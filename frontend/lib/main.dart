import 'dart:io';//Required to load FileImage from stored image path
import 'package:flutter/material.dart';
import 'dart:ffi' as ffi;
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'database_helper.dart';//Local SQLite storage helper
import 'add_coin_screen.dart';
import 'scanner_screen.dart';
import 'sync_service.dart';

void main() {
  runApp(const CoinlyApp());
}

class CoinlyApp extends StatelessWidget {
  const CoinlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coinly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const CoinListScreen(),
    );
  }
}

class CoinListScreen extends StatefulWidget {
  const CoinListScreen({super.key});

  @override
  State<CoinListScreen> createState() => _CoinListScreenState();
}

class _CoinListScreenState extends State<CoinListScreen> {

  //Local in-memory cache of SQLite records
  List<Map<String, dynamic>> coins = [];
  bool isLoading = true;

  //Network connectivity listener subscription
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    fetchCoins();

    //Automatic background synchronization trigger based on connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {

      //Trigger sync only when Wi-Fi connectivity is detected
      if (results.contains(ConnectivityResult.wifi)) {
        debugPrint("Wi-Fi detected. Starting bidirectional auto-sync in background...");

        //Execute sync asynchronously and refresh UI after completion
        SyncService.syncCoinsWithServer().then((_) {
          fetchCoins();
        });
      }
    });

    //FFI integration test with native C++ library
    try {
      final nativeLib = ffi.DynamicLibrary.open('libcore_ai.so');
      final testConnection = nativeLib
          .lookup<ffi.NativeFunction<ffi.Int32 Function()>>('test_connection')
          .asFunction<int Function()>();

      final resultCpp = testConnection();
      debugPrint('=========================================');
      debugPrint('SUCCESS FFI! C++ RETURNED: $resultCpp 🔥');
      debugPrint('=========================================');
    } catch (e) {
      debugPrint('ERROR FFI: Not possible to connect with C++. Error: $e');
    }
  }

  @override
  void dispose() {
    //Cancel connectivity listener to prevent memory leaks and reduce battery usage
    _connectivitySubscription.cancel();
    super.dispose();
  }

  //Fetches all coins from local SQLite storage
  Future<void> fetchCoins() async {
    setState(() {
      isLoading = true;
    });

    try {

      //Direct read from local database
      final localCoins = await DatabaseHelper.instance.getAllLocalCoins();

      setState(() {
        coins = localCoins;
        isLoading = false;
      });

    } catch (e) {
      debugPrint('Error loading local coins: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Collection',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [

          //Manual bidirectional synchronization trigger
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting bidirectional synchronization...')),
              );

              //Execute upload and download
              await SyncService.syncCoinsWithServer();

              //Refresh UI after sync
              fetchCoins();
            },
          ),

          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScannerScreen()),
              );

              //Refresh list if a new coin was added via scanner
              if (result == true) {
                fetchCoins();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : coins.isEmpty
          ? const Center(child: Text('Vault is empty. Add a coin!'))
          : ListView.builder(
        itemCount: coins.length,
        itemBuilder: (context, index) {
          final coin = coins[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(

              //Hybrid image resolution logic (local file vs remote URL)
              leading: Builder(
                builder: (context) {
                  final String? path = coin['imagePath'];

                  //No image available
                  if (path == null || path.isEmpty) {
                    return const CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.monetization_on, color: Colors.white),
                    );
                  }

                  //Local image stored on device
                  if (path.startsWith('/')) {
                    return CircleAvatar(
                      backgroundImage: FileImage(File(path)),
                      radius: 25,
                      backgroundColor: Colors.transparent,
                    );
                  }

                  //Remote image retrieved from backend
                  return CircleAvatar(
                    backgroundImage: NetworkImage('http://10.0.2.2:8080/uploads/coins/$path'),
                    radius: 25,
                    backgroundColor: Colors.transparent,
                    onBackgroundImageError: (e, stack) => debugPrint("Remote image loading error: $e"),
                  );
                },
              ),

              title: Text(
                coin['name'] ?? 'Unnamed coin',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              //Displays country, year and conditionally renders AI anomalies
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${coin['country']} • ${coin['year']}'),
                  if (coin['anomalies'] != null && coin['anomalies'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              coin['anomalies'],
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade700,
                                  fontStyle: FontStyle.italic
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              //Displays face value and synchronization state
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${coin['faceValue']}€',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  //Cloud icon indicates synchronization status
                  Icon(
                    coin['isSynced'] == 1 ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: coin['isSynced'] == 1 ? Colors.blue : Colors.grey,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCoinScreen()),
          );

          //Refresh list after successful insertion
          if (result == true) {
            fetchCoins();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
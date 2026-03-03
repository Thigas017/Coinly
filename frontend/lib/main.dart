import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_coin_screen.dart';
import 'scanner_screen.dart';
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

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
  List<dynamic> coins = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCoins(); //Fetch data when the screen initializes

    //Test FFI: Try comms with C++
    try {
      final nativeLib = ffi.DynamicLibrary.open('libcore_ai.so');
      //Search function test_connection
      final testConnection = nativeLib.lookup<ffi.NativeFunction<ffi.Int32 Function()>>('test_connection').asFunction<int Function()>();

      //Exec function C++!
      final resultCpp = testConnection();
      debugPrint('=========================================');
      debugPrint('SUCCESS FFI! C++ RETURNED: $resultCpp 🔥');
      debugPrint('=========================================');
    } catch (e) {
      debugPrint('ERROR FFI: Not possible to connect with C++. Error: $e');
    }

  }

  Future<void> fetchCoins() async {
    //Android emulator cannot access localhost directly
    //Use 10.0.2.2 to access the host machine backend
    final url = Uri.parse('http://10.0.2.2:8080/api/coins');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          //Parse JSON response into a Dart list
          coins = json.decode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching coins: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScannerScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      ) //Display loader while waiting for network response
          : coins.isEmpty
          ? const Center(
        child: Text('No coins found in database.'),
      )
          : ListView.builder(
        itemCount: coins.length,
        itemBuilder: (context, index) {
          final coin = coins[index];
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.amber,
                child: Icon(Icons.monetization_on,
                    color: Colors.white),
              ),
              title: Text(
                coin['name'] ?? 'Unnamed coin',
                style: const TextStyle(
                    fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  '${coin['country']} • ${coin['year']}'),
              trailing: Text(
                '${coin['faceValue']}€',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          //Open add coin screen and wait for result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCoinScreen()),
          );

          //If true is returned, refresh the coin list
          if (result == true) {
            setState(() { isLoading = true; });
            fetchCoins();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
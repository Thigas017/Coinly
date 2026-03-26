import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'database_helper.dart';

class SyncService {

  //Backend API base URL
  static const String serverUrl = 'http://10.0.2.2:8080/api/coins';

  //Main synchronization entry point (upload first, then download)
  static Future<void> syncCoinsWithServer() async {
    await _uploadPendingCoins();
    await _downloadServerCoins();
  }

  //Handles upload of locally unsynchronized records
  static Future<void> _uploadPendingCoins() async {
    final db = DatabaseHelper.instance;
    final unsyncedCoins = await db.getUnsyncedCoins();

    if (unsyncedCoins.isEmpty) return;

    for (var coin in unsyncedCoins) {
      try {

        //Prepare multipart POST request
        var request = http.MultipartRequest('POST', Uri.parse(serverUrl));
        request.fields['id'] = coin['id'].toString();
        request.fields['name'] = coin['name'];
        request.fields['country'] = coin['country'];
        request.fields['year'] = coin['year'].toString();
        request.fields['faceValue'] = coin['faceValue'].toString();

        //Attach anomalies if AI detected any
        if (coin['anomalies'] != null) {
          request.fields['anomalies'] = coin['anomalies'].toString();
        }

        //Attach local image file if available
        if (coin['imagePath'] != null) {
          File imageFile = File(coin['imagePath']);
          if (imageFile.existsSync()) {
            request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
          }
        }

        var response = await request.send();

        //Mark record as synchronized on successful response
        if (response.statusCode == 200 || response.statusCode == 201) {
          await db.markAsSynced(coin['id']);
          debugPrint("UPLOAD SUCCESS: Coin ${coin['name']} synchronized.");
        }

      } catch (e) {
        debugPrint("Upload failure: $e");
      }
    }
  }

  //Handles download of server-side records and local merge
  static Future<void> _downloadServerCoins() async {
    try {

      //Fetch all coins from backend API
      final response = await http.get(Uri.parse(serverUrl));

      if (response.statusCode == 200) {

        //Decode UTF-8 response body into JSON list
        final List<dynamic> serverCoins = json.decode(utf8.decode(response.bodyBytes));
        final db = DatabaseHelper.instance;

        //Retrieve local records to preserve device-specific data
        final localCoins = await db.getAllLocalCoins();
        final localCoinMap = {for (var c in localCoins) c['id']: c};

        for (var sCoin in serverCoins) {

          final existingCoin = localCoinMap[sCoin['id']];
          String? finalImagePath = sCoin['imageUrl'];

          //If local record exists and contains a valid absolute file path, preserve local image
          if (existingCoin != null &&
              existingCoin['imagePath'] != null &&
              existingCoin['imagePath'].toString().startsWith('/')) {

            finalImagePath = existingCoin['imagePath'];
          }

          //Insert or update local record (replace strategy prevents duplication)
          await db.insertCoin({
            "id": sCoin['id'],
            "name": sCoin['name'],
            "country": sCoin['country'],
            "year": sCoin['year'],
            "faceValue": sCoin['faceValue'],
            "imagePath": finalImagePath,
            "anomalies": sCoin['anomalies'], //Extract anomalies from server response
            "isSynced": 1,
          });
        }

        debugPrint("DOWNLOAD SUCCESS: Server synchronization completed.");
      }

    } catch (e) {
      debugPrint("Download failure: $e");
    }
  }
}
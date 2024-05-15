import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// class VWorldAddressService {
//   Future<String> getAddressFromCoordinates(Position position) async {
//     String apiKey = dotenv.env['VWORLDKEY']!;
//     String requestUrl =
//         'https://api.vworld.kr/req/address?key=$apiKey&service=address&version=2.0&request=getAddress&format=json&point=${position.longitude},${position.latitude}&crs=epsg:4326&type=both&zipcode=true&simple=false';
//     http.Response response = await http.get(Uri.parse(requestUrl));
//     if (response.statusCode == 200) {
//       var jsonResponse = jsonDecode(response.body);
//       var responseResult = jsonResponse['response']['result'];
//       if (responseResult != null && responseResult.isNotEmpty) {
//         return responseResult[0]['text'] ?? 'No address found';
//       } else {
//         print('Response result is empty or null: $jsonResponse');
//         return 'Failed to get address';
//       }
//     } else {
//       print('Failed to fetch address. Status code: ${response.statusCode}');
//       return 'Failed to get address';
//     }
//   }
// }

class VWorldAddressService {
  final String baseUrl = 'http://api.vworld.kr/req/address';
  final String apiKey = dotenv.env['VWORLDKEY'] ?? '';

  Future<String> getAddressFromCoordinates(Position position) async {
    final response = await http.get(Uri.parse(
        '$baseUrl?service=address&version=2.0&request=getAddress&key=$apiKey&point=${position.longitude},${position.latitude}'));
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse['response']['result']['text'];
    } else {
      throw Exception('Failed to load address data');
    }
  }

  static Future<Map<String, dynamic>> fetchAddress(
      double latitude, double longitude) async {
    final String apiKey = dotenv.env['VWORLDKEY'] ?? '';
    const String baseUrl = 'http://api.vworld.kr/req/address';

    final response = await http.get(Uri.parse(
        '$baseUrl?service=address&version=2.0&request=getAddress&key=$apiKey&point=$longitude,$latitude'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['response']['status'] == 'OK') {
        return data['response']['result'][0];
      } else {
        throw Exception('Failed to fetch address');
      }
    } else {
      throw Exception('Failed to connect to VWorld API');
    }
  }
}

class AddressFinder extends StatefulWidget {
  const AddressFinder({Key? key}) : super(key: key);

  @override
  State<AddressFinder> createState() => _AddressFinderState();
}

class _AddressFinderState extends State<AddressFinder> {
  String _address = 'Press button to get your address';

  @override
  void initState() {
    super.initState();
    getPositionAndAddress();
  }

  Future<void> getPositionAndAddress() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition();
      getAddressFromCoordinates(position);
    } catch (e) {
      setState(() {
        _address = 'Failed to get location: $e';
      });
    }
  }

  Future<String> getAddressFromCoordinates(Position position) async {
    String apiKey = dotenv.env['VWORLDKEY']!;
    Map<String, String> params = {
      'key': apiKey,
      'service': 'address',
      'version': '2.0',
      'request': 'getAddress',
      'format': 'json',
      'point': '${position.longitude},${position.latitude}',
      'crs': 'epsg:4326',
      'type': 'both',
      'zipcode': 'true',
      'simple': 'false'
    };

    String baseUrl = "https://api.vworld.kr/req/address";
    String queryString = Uri(queryParameters: params).query;
    String requestUrl = '$baseUrl?$queryString';

    http.Response response = await http.get(Uri.parse(requestUrl));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      var responseResult = jsonResponse['response']['result'];
      if (responseResult != null && responseResult.isNotEmpty) {
        var addressText = responseResult[0]['text'];
        _address = addressText ?? 'No address found';
      } else {
        print('Response result is empty or null: $jsonResponse');
        _address = 'No address found';
      }
    } else {
      print('Failed to fetch address. Status code: ${response.statusCode}');
      _address = 'Failed to fetch address';
    }
    return _address;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_address, textAlign: TextAlign.center),
          ),
          ElevatedButton(
            onPressed: getPositionAndAddress,
            child: const Text('Get Address'),
          ),
        ],
      ),
    );
  }
}

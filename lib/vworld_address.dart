import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VWorldAddressService {
  final String baseUrl = 'http://api.vworld.kr/req/address';
  final String apiKey = dotenv.env['VWORLDKEY'] ?? '';

  static Future<Map<String, dynamic>> fetchAddress(
      double latitude, double longitude) async {
    final String apiKey = dotenv.env['VWORLDKEY'] ?? '';
    const String baseUrl = 'http://api.vworld.kr/req/address';
    final response = await http.get(Uri.parse(
      '$baseUrl?service=address&version=2.0&request=getAddress&key=$apiKey&point=$longitude,$latitude&crs=epsg:4326&type=both&zipcode=true&format=json',
    ));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['response']['status'] == 'OK') {
        return data['response']['result'][0];
      } else {
        throw Exception(
            'Failed to fetch address: ${data['response']['status']}');
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
      String address = await getAddressFromCoordinates(position);
      setState(() {
        _address = address;
      });
    } catch (e) {
      setState(() {
        _address = 'Failed to get location: $e';
      });
    }
  }

  Future<String> getAddressFromCoordinates(Position position) async {
    try {
      double latitude = position.latitude;
      double longitude = position.longitude;
      Map<String, dynamic> addressData =
          await VWorldAddressService.fetchAddress(latitude, longitude);
      String addressText = addressData['text'] ?? 'No address found';
      return addressText;
    } catch (e) {
      return 'Failed to fetch address: $e';
    }
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

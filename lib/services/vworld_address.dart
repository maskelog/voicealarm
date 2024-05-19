import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class VWorldAddressService {
  static Future<String> fetchAddress(double latitude, double longitude) async {
    final String apiKey = dotenv.env['VWORLDKEY'] ?? '';
    const String baseUrl = 'http://api.vworld.kr/req/address';
    final url = Uri.parse(
      '$baseUrl?key=$apiKey&service=address&version=2.0&request=getAddress&crs=epsg:4166&type=road&point=$longitude,$latitude&zipcode=true&format=json',
    );

    print("Request URL: $url");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      print("Response data: $data");
      if (data['response']['status'] == 'OK') {
        final String level3 = data['response']['result'][0]['structure']
                ['level3'] ??
            '주소를 찾을 수 없음';
        return level3;
      } else {
        throw Exception(
            'Failed to fetch address: ${data['response']['status']}');
      }
    } else {
      throw Exception('Failed to connect to VWorld API');
    }
  }
}

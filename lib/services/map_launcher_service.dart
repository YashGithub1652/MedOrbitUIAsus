import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class MapLauncherService {
  static Future<void> launchDirections({required double lat, required double lng}) async {
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    final Uri appleMapsUrl = Uri.parse("http://maps.apple.com/?daddr=$lat,$lng");
    final Uri browserUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");

    try {
      if (Platform.isAndroid) {
        if (await canLaunchUrl(googleMapsUrl)) {
          await launchUrl(googleMapsUrl);
        } else {
          await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isIOS) {
        if (await canLaunchUrl(appleMapsUrl)) {
          await launchUrl(appleMapsUrl);
        } else {
          await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
        }
      } else {
        await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
    }
  }
}
import 'package:flutter/material.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

const kEmergencyPhone = '999';
const kRepairAiUssdCode = '*384#';

Future<void> launchEmergencyCall() async {
  final uri = Uri.parse('tel:$kEmergencyPhone');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> launchPhoneNumber(String phoneNumber) async {
  final normalized = phoneNumber.replaceAll(RegExp(r'\s+'), '');
  final uri = Uri.parse('tel:$normalized');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> launchFacilityDirections({
  required double latitude,
  required double longitude,
  double? fromLatitude,
  double? fromLongitude,
}) async {
  final encodedDestination = '$latitude,$longitude';
  final uri = fromLatitude != null && fromLongitude != null
      ? Uri.parse(
          'https://www.openstreetmap.org/directions?engine=fossgis_osrm_car&route=$fromLatitude%2C$fromLongitude%3B$encodedDestination',
        )
      : Uri.parse(
          'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=15/$latitude/$longitude',
        );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> launchRepairAiWebsite() async {
  final uri = Uri.parse('https://repairai.co.ke/');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> launchWhatsAppHelp([BuildContext? context]) async {
  const phone = '254711507497';
  final message = context != null
      ? AppLocalizations.of(context).whatsAppMessage
      : 'Hello REPAIR-AI, I need help with my pregnancy.';
  final uri = Uri.parse(
    'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> launchUssdCode() async {
  final uri = Uri.parse('tel:${Uri.encodeComponent(kRepairAiUssdCode)}');
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri);
}

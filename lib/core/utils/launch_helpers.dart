import 'package:flutter/material.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

const kEmergencyPhone = '999';
const kFacilityMapsQuery = 'Bungoma+County+Referral+Hospital';

Future<void> launchEmergencyCall() async {
  final uri = Uri.parse('tel:$kEmergencyPhone');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> launchFacilityMaps() async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$kFacilityMapsQuery',
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

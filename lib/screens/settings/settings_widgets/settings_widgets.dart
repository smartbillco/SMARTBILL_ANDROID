import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartbill/screens/settings/settings_widgets/update_address_screen.dart';
import 'package:smartbill/screens/settings/settings_widgets/update_email_screen.dart';
import 'package:smartbill/screens/settings/settings_widgets/update_id_screen.dart';
import 'package:smartbill/screens/settings/settings_widgets/update_name_screen.dart';
import 'package:smartbill/services/settings.dart';


class SettingsRow extends StatefulWidget {
  final bool settingsValue;
  final String title;
  final String subtitle;
  
  const SettingsRow({
    super.key,
    required this.settingsValue,
    required this.title,
    required this.subtitle,
  });

  @override
  State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {

  @override
  void initState() {
    super.initState(); // Initialize with the passed value
  }

  @override
  Widget build(BuildContext context) {

    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Container(width: 200, child: Text(widget.subtitle, style: const TextStyle(color: Colors.black54))),
          ],
        ),
        Switch(
          activeColor: Colors.blue,
          value: widget.settingsValue, // Bind to _option, not widget.settingsValue
          onChanged: (value) {
            if(widget.title == 'Descargas') {
              settingsProvider.changeAutoDownloadSetting();
            } else {
              settingsProvider.changeNotificationSetting();
            }
          },
        ),
      ],
    );
  }
}


//List of user fields
class ListViewUserFields extends StatelessWidget {
  final String? email;
  final String? name;
  final String? userId;
  final String? address;
  const ListViewUserFields({super.key, required this.email, required this.name, required this.userId, required this.address});

  @override
  Widget build(BuildContext context) {

    return ListView(
      children: [
        ListTile(
          title: const Text("Email", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          subtitle: email == '' || email == null ? const Text('Ingresa un email') : Text(email!),
          trailing: IconButton(onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const UpdateEmailScreen()));
          }, icon: const Icon(Icons.arrow_forward_ios, color: Colors.grey,)),
      ),
        ListTile(
          title: const Text("Nombre", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          subtitle: name == '' || name == null ? const Text('Ingresa tu nombre') : Text(name!),
          trailing: IconButton(onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const UpdateNameScreen()));
          }, icon: const Icon(Icons.arrow_forward_ios, color: Colors.grey)),
        ),
        ListTile(
          title: const Text("Identificación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          subtitle: userId == '' ? const Text('Ingresa  tu identificación') : Text(userId!),
          trailing: IconButton(onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const UpdateIdScreen()));
          }, icon: const Icon(Icons.arrow_forward_ios, color: Colors.grey,)),
        ),
        ListTile(
          title: const Text("Direccion", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          subtitle: address == '' ? const Text('Ingresa  tu identificación') : Text(address!),
          trailing: IconButton(onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const UpdateAddressScreen()));
          }, icon: const Icon(Icons.arrow_forward_ios, color: Colors.grey,)),
        )
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:HolaTalk/views/settings/account.dart';
import 'package:HolaTalk/views/settings/appearance.dart'; // 새로 추가된 임포트

class AppSettings extends StatelessWidget {
  final Function(ThemeMode) updateThemeMode;

  AppSettings({required this.updateThemeMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Account'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Account(updateThemeMode: updateThemeMode)),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            onTap: () {
              // Notifications 설정 화면으로 이동하는 코드 추가
            },
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Privacy'),
            onTap: () {
              // Privacy 설정 화면으로 이동하는 코드 추가
            },
          ),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text('Chat Settings'),
            onTap: () {
              // Chat Settings 설정 화면으로 이동하는 코드 추가
            },
          ),
          ListTile(
            leading: Icon(Icons.palette), // 아이콘 추가
            title: Text('Appearance'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Appearance(updateThemeMode: updateThemeMode), // updateThemeMode 전달
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            onTap: () {
              // About 화면으로 이동하는 코드 추가
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help'),
            onTap: () {
              // Help 화면으로 이동하는 코드 추가
            },
          ),
        ],
      ),
    );
  }
}

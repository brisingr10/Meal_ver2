import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; //데이터 저장하고 불러오는 패키지
import '../viewmodel/MainViewModel.dart';
import 'package:meal_ver2/view/meal2_view.dart';

class MainActivity extends StatelessWidget  {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Main Activity'),
      ),
      body: Column(
        children: [
          //ElevatedButton(
            //onPressed: _showScheduleBottomSheet,
            //child: Text('Show Schedule'),
          //),
          //ElevatedButton(
            //onPressed: _showAppInfoBottomSheet,
            //child: Text('Show App Info'),
          //),
          Text('Current Theme: ${viewModel.themeIndex == 0 ? 'Light' : viewModel.themeIndex == 1 ? 'Dark' : 'System'}'),
        ],
      ),
    );
  }
}

class ScheduleBottomSheet extends StatelessWidget {
  final Function(int) onItemSelected;

  ScheduleBottomSheet({required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(10, (index) {
          return ListTile(
            title: Text('Schedule Item $index'),
            onTap: () => onItemSelected(index),
          );
        }),
      ),
    );
  }
}
class AppInfoBottomSheet extends StatelessWidget {
  final int themeIndex;
  final Function(int) onThemeChanged;

  AppInfoBottomSheet({required this.themeIndex, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('App Version: 1.0.0'),
          ListTile(
            title: Text('Light Theme'),
            leading: Radio(
              value: 0,
              groupValue: themeIndex,
              onChanged: (int? value) {
                if (value != null) onThemeChanged(value);
              },
            ),
          ),
          ListTile(
            title: Text('Dark Theme'),
            leading: Radio(
              value: 1,
              groupValue: themeIndex,
              onChanged: (int? value) {
                if (value != null) onThemeChanged(value);
              },
            ),
          ),
          ListTile(
            title: Text('System Theme'),
            leading: Radio(
              value: 2,
              groupValue: themeIndex,
              onChanged: (int? value) {
                if (value != null) onThemeChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
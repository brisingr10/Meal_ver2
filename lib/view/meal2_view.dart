import 'package:flutter/material.dart';

class Meal2View extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background, // 테마에 따라 색상 설정
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Header(),
            Expanded(
              child: ListView.builder(
                itemCount: 20, // 예시 아이템 개수
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Item $index'),
                    subtitle: Text('Details for item $index'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('끼니', style: TextStyle(fontFamily: 'Myfont',fontSize: 80, color: Theme.of(context).textTheme.bodyLarge?.color)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Date Info', style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () {
                // 캘린더 기능 구현
              },
            ),
          ],
        ),
        Divider(color: Colors.grey),
        Text('Additional Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
      ],
    );
  }
}
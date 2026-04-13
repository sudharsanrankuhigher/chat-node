import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

import '../ui/views/chat/chat_view.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stacked Chat',
      debugShowCheckedModeBanner: false,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [StackedService.routeObserver],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A8F6A)),
        useMaterial3: true,
      ),
      home: const ChatView(),
    );
  }
}

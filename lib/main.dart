import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arduino LED Controller',
      theme: ThemeData.dark(useMaterial3: true),
      home: const LedControllerPage(),
    );
  }
}

class LedControllerPage extends StatefulWidget {
  const LedControllerPage({super.key});

  @override
  State<LedControllerPage> createState() => _LedControllerPageState();
}

class _LedControllerPageState extends State<LedControllerPage> {
  final TextEditingController ipController =
      TextEditingController(text: " Your Ip");

  Timer? _heartbeatTimer;
  bool connected = false;
  List<String> logs = [];

  void _log(String msg) {
    setState(() {
      logs.insert(0, "[${TimeOfDay.now().format(context)}] $msg");
    });
  }

  Future<void> connect() async {
    final ip = ipController.text.trim();
    if (ip.isEmpty) return;

    _log("🔌 Trying connect to Arduino at $ip ...");

    setState(() {
      connected = true;
    });

    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _sendCommand("/status", silent: true);
    });

    _log("✅ Connected to Arduino at $ip");
  }

  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    setState(() {
      connected = false;
    });
    _log("❌ Disconnected manually");
  }

  Future<void> _sendCommand(String path, {bool silent = false}) async {
    final ip = ipController.text.trim();
    final url = Uri.parse("http://$ip$path");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (!silent) {
        _log("➡️ Sent $path → ${response.body}");
      }
    } catch (e) {
      if (!silent) {
        _log("⚠️ Failed $path → $e");
      } else {
        _log("⚠️ Heartbeat failed (ignored)");
      }
      
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Arduino LED Controller - ${connected ? "Connected" : "Disconnected"}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: "Arduino IP / Host",
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: connected ? null : connect,
                  child: const Text("Connect"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: connected ? disconnect : null,
                  child: const Text("Disconnect"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: connected ? () => _sendCommand("/on") : null,
                  child: const Text("LED ON"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: connected ? () => _sendCommand("/off") : null,
                  child: const Text("LED OFF"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: connected ? () => _sendCommand("/status") : null,
                  child: const Text("STATUS"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView(
                  reverse: true,
                  children: logs.map((e) => Text(e)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

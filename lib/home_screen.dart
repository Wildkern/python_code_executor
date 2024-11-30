import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  String _output = "";
  bool _isLoading = false;
  int? errorLine; // Line number with an error, if any.

  void executeCode(String code) async {
    setState(() {
      _isLoading = true;
      _output = "";
      errorLine = null;
    });

    final url = Uri.parse("https://emkc.org/api/v2/piston/execute");

    try {
      // Send HTTP POST request
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "language": "python",
          "version": "3.10.0",
          "files": [
            {"content": code}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stdout = data['run']['stdout'] ?? "";
        final stderr = data['run']['stderr'] ?? "";

        if (stderr.isNotEmpty) {
          setState(() {
            _output = "Error:\n$stderr";
            errorLine = _extractErrorLine(stderr);
          });
        } else if (stdout.isNotEmpty) {
          setState(() {
            _output = stdout;
          });
        } else {
          setState(() {
            _output = "No output received.";
          });
        }
      } else {
        setState(() {
          _output =
              "Error: Unable to execute the code. Status Code: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _output = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Extract the error line number from the stderr.
  int? _extractErrorLine(String stderr) {
    final match = RegExp(r"line (\d+)").firstMatch(stderr);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  void clearInput() {
    setState(() {
      _controller.clear();
      _output = "";
      errorLine = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Python Code Executor"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Editable Input Field with removed padding and no border
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _controller,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: "Enter Python Code",
                  border: InputBorder.none, // Remove border
                  contentPadding: EdgeInsets.all(0), // Remove padding
                ),
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Buttons for Submit and Clear
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => executeCode(_controller.text),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Run"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: clearInput,
                  icon: const Icon(Icons.clear),
                  label: const Text("Clear"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Spinner while loading
            if (_isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 10),
            // Output section
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _output.isEmpty ? "Output will appear here." : _output,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 14,
                      color: _output.startsWith("Error")
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

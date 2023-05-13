import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../alarm_dataclass.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  // list of bluetooth devices
  final List<BluetoothDevice> devicesList = [];
  final List<Alarm> _currentAlarms = [];

  Future<Alarm> _selectTime(BuildContext context) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
    );
    // ask for an alarm name
    String alarmName = '';
    TextEditingController nameController = TextEditingController();
    // ignore: use_build_context_synchronously
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Alarm name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Enter a name',
              labelText: 'new name',
              ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                alarmName = nameController.text;
                if (alarmName.isNotEmpty) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (newTime != null && alarmName != "") {
      return Alarm(alarmName, newTime);
    }
    return Alarm("", const TimeOfDay(hour: 0, minute: 0));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            tooltip: 'Connect to the device',
            icon: const Icon(Icons.bluetooth),
            onPressed: () async {
              // scan for bluetooth devices
              flutterBlue.startScan(timeout: const Duration(seconds: 4));
              // listen for devices
              flutterBlue.scanResults.listen((results) {
                // do something with scan results
                for (ScanResult r in results) {
                  if (!devicesList.contains(r.device)) {
                    setState(() => devicesList.add(r.device));
                  }
                }
              });
            },
          ),
        ],
      ),
      body: Center(
        child: ListView.builder(
          itemCount: _currentAlarms.length,
          itemBuilder: (context, index) {
            final alarmTime = _currentAlarms[index].time.format(context);
            final alarmTitle = _currentAlarms[index].name;
            ListTile element = ListTile(
              title: Text(alarmTitle),
              subtitle: Text(alarmTime.toString()),
              onLongPress: () => {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    // delete or modify alarm
                    return AlertDialog(
                      title: Text(alarmTitle),
                      content: Text(alarmTime.toString()),
                      actions: [
                        // Cancel
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        // Delete
                        TextButton(
                          onPressed: () {
                            setState(() => _currentAlarms.removeAt(index));
                            Navigator.of(context).pop();
                          },
                          child: const Text('Delete'),
                        ),
                        // Modify
                        TextButton(
                          onPressed: () async {
                            // show time picker
                            Alarm selected = await _selectTime(context);
                            if (!selected.isEmpty()) {
                              setState(() => _currentAlarms[index] = selected);
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text('Modify'),
                        ),
                      ],
                    );
                  },
                ),
              },
            );
            return element;
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Alarm selected = await _selectTime(context);
          if (!selected.isEmpty()) {
            setState(() => _currentAlarms.add(selected));
          }
        },
        tooltip: 'Create a new alarm',
        child: const Icon(Icons.add),
      ),
    );
  }
}

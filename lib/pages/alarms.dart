// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../alarm_dataclass.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'discovery.dart';

class AlarmsPage extends StatefulWidget {
  const AlarmsPage({
    Key? key,
    required this.blDevice,
  }) : super(key: key);

  final BluetoothDevice? blDevice;

  @override
  State<AlarmsPage> createState() => _AlarmsPageState();
}

class _AlarmsPageState extends State<AlarmsPage> {
  BluetoothConnection? connection;

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;
  bool isLoading = false;

  final _currentAlarms = List<Alarm>.empty(growable: true);

  @override
  void initState() {
    super.initState();

    isLoading = true;
    BluetoothConnection.toAddress(widget.blDevice?.address)
        .then((newConnection) {
      print('Connected to the device');
      connection = newConnection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (mounted) {
          setState(() {});
        }
      });
      // ask for alarms
      connection!.output.add(const Utf8Encoder().convert('G;'));
    }).catchError((error) {
      print('Cannot connect, exception occured');
      // print(error);
      MaterialPageRoute(builder: (context) => const DiscoveryPage());
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  Future<Alarm> _selectTime(BuildContext context) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
    );
    // if we pressed cancel, return empty alarm
    if (newTime == null) {
      return Alarm("", const TimeOfDay(hour: 0, minute: 0));
    }
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

    if (alarmName != "") {
      return Alarm(alarmName, newTime);
    }
    return Alarm("", const TimeOfDay(hour: 0, minute: 0));
  }

  Future<void> editAlarm(int index) async {
    // show time picker
    Alarm selected = await _selectTime(context);
    if (!selected.isEmpty()) {
      int cylinder = 0; // TODO: get cylinder
      setState(() => _currentAlarms[index] = selected);
      connection?.output.add(const Utf8Encoder().convert(
          'E,$index,${selected.name},${selected.time.hour},${selected.time.minute},$cylinder;'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alarms"),
        actions: <Widget>[
          // refresh button
          isLoading
              ? FittedBox(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  tooltip: 'Refresh the list of alarms',
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    try {
                      isLoading = true;
                      connection!.output.add(const Utf8Encoder().convert('G;'));
                    } catch (e) {
                      // print(e);
                      print("error");
                    }
                    setState(() {});
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
              // add a pencil button on the right, to edit the alarm
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  editAlarm(index);
                },
              ),
              onLongPress: () => {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    // delete or modify alarm
                    return AlertDialog(
                      title: Text(alarmTitle),
                      content: Text(alarmTime.toString()),
                      actions: [
                        TextButton(
                          // Cancel
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          // Delete
                          onPressed: () {
                            setState(() => _currentAlarms.removeAt(index));
                            connection?.output
                                .add(const Utf8Encoder().convert('D,$index;'));
                            Navigator.of(context).pop();
                          },
                          child: const Text('Delete'),
                        ),
                        TextButton(
                          // EDIT
                          onPressed: () async {
                            await editAlarm(index);
                            Navigator.of(context).pop();
                          },
                          child: const Text('Edit'),
                        ),
                      ],
                    );
                  },
                ),
              },
            );
            // add pencil button on the right
            return element;
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // ADD
        onPressed: () async {
          Alarm selected = await _selectTime(context);
          if (!selected.isEmpty()) {
            setState(() => _currentAlarms.add(selected));
            int cylinder = 0; // test
            connection?.output.add(const Utf8Encoder().convert(
              // send A, name, hour, minute, cylinder
              'A,${selected.name},${selected.time.hour},${selected.time.minute},$cylinder,',
            ));
          }
        },
        tooltip: 'Create a new alarm',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _onDataReceived(Uint8List event) {
    print('Data incoming: ${ascii.decode(event)}');
    // parse data (format is name, hour, minute, cylinder;)
    String dataString = ascii.decode(event);
    // divide the string in substrings
    List<String> alarms = dataString.split(';');
    // remove the last empty string
    alarms.removeLast();
    // add alarms
    _currentAlarms.clear();
    for (int i = 0; i < alarms.length; i++) {
      // get index, hour, minute, cylinder
      List<String> alarm = alarms[i].split(',');
      // add alarm
      _currentAlarms.add(Alarm(alarm[0],
          TimeOfDay(hour: int.parse(alarm[1]), minute: int.parse(alarm[2]))));
    }
    // stop loading
    isLoading = false;
    setState(() {});
  }
}

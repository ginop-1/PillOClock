import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class Alarm {
  final String name;
  final TimeOfDay time;

  Alarm(this.name, this.time);

  @override
  String toString() {
    return 'Alarm{name: $name, time: $time}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alarm &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          time == other.time;

  @override
  int get hashCode => name.hashCode ^ time.hashCode;

  // check if it's empty
  bool isEmpty() {
    return name.isEmpty && time == const TimeOfDay(hour: 0, minute: 0);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pill O\'Clock manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Pill O\' Clock manager'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
            decoration: const InputDecoration(hintText: 'Enter a name'),
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
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

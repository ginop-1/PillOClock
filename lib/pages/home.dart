// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

import "./discovery.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // sample empty home
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.connect_without_contact),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) {
                  return const DiscoveryPage();
                },
              ));
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          // ignore: prefer_const_literals_to_create_immutables
          children: <Widget>[
            Text(
              'Welcome!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            // button that goes to discovery page
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) {
                    return const DiscoveryPage();
                  },
                ));
              },
              child: const Text('Connect to a device',
                  style: TextStyle(fontSize: 20)),
            ),  
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:pill_o_clock/pages/alarms.dart';

import '../bluetooth_device_list_entry.dart';

class DiscoveryPage extends StatefulWidget {
  /// If true, discovery starts on page start, otherwise user must press action button.
  final bool start;

  const DiscoveryPage({super.key, this.start = true});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPage();
}

class _DiscoveryPage extends State<DiscoveryPage> {
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  List<BluetoothDiscoveryResult> results =
      List<BluetoothDiscoveryResult>.empty(growable: true);
  bool isDiscovering = false;

  _DiscoveryPage();

  @override
  void initState() {
    super.initState();

    isDiscovering = widget.start;
    if (isDiscovering) {
      _startDiscovery();
    }
  }

  void _restartDiscovery() {
    setState(() {
      results.clear();
      isDiscovering = true;
    });

    _startDiscovery();
  }

  void _startDiscovery() {
    _streamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        final existingIndex = results.indexWhere(
            (element) => element.device.address == r.device.address);
        if (existingIndex >= 0) {
          results[existingIndex] = r;
        } else {
          // add bondend devices to the top of the list
          if (r.device.isBonded) {
            results.insert(0, r);
          } else {
            results.add(r);
          }
        }
      });
    });

    _streamSubscription!.onDone(() {
      setState(() {
        isDiscovering = false;
      });
    });
  }

  void _bond(BluetoothDevice device, String address,
      BluetoothDiscoveryResult result) async {
    try {
      bool bonded = false;
      if (device.isBonded) {
        print('Unbonding from ${device.address}...');
        await FlutterBluetoothSerial.instance
            .removeDeviceBondWithAddress(address);
        print('Unbonding from ${device.address} has succed');
      } else {
        print('Bonding with ${device.address}...');
        bonded = (await FlutterBluetoothSerial.instance
            .bondDeviceAtAddress(address))!;
        print(
            'Bonding with ${device.address} has ${bonded ? 'succed' : 'failed'}.');
        if (bonded) {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) {
              return AlarmsPage(blDevice: device);
            },
          ));
        }
      }
      setState(() {
        results[results.indexOf(result)] = BluetoothDiscoveryResult(
            device: BluetoothDevice(
              name: device.name ?? '',
              address: address,
              type: device.type,
              bondState:
                  bonded ? BluetoothBondState.bonded : BluetoothBondState.none,
            ),
            rssi: result.rssi);
      });
    } catch (ex) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error occured while bonding'),
            content: Text(ex.toString()),
            actions: <Widget>[
              TextButton(
                child: const Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isDiscovering
            ? const Text('Discovering devices')
            : const Text('Discovered devices'),
        actions: <Widget>[
          isDiscovering
              ? FittedBox(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.replay),
                  onPressed: _restartDiscovery,
                )
        ],
      ),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (BuildContext context, index) {
          BluetoothDiscoveryResult result = results[index];
          final device = result.device;
          final address = device.address;
          return BluetoothDeviceListEntry(
            device: device,
            rssi: result.rssi,
            onTap: () async {
              // check if it's already bonded
              if (device.isBonded) {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) {
                    return AlarmsPage(blDevice: device);
                  },
                ));
              } else {
                _bond(device, address, result);
              }
            },
          );
        },
      ),
    );
  }
}

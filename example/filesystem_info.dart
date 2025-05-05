import 'dart:convert';

import 'package:udisks/udisks.dart';

void main() async {
  // Create a UDisks client instance
  final client = UDisksClient();

  try {
    // Connect to the UDisks service on D-Bus
    print('Connecting to UDisks...');
    await client.connect();
    print('Connected. UDisks version: ${client.version}');
    print('---');

    // Get the list of block devices
    final blockDevices = client.blockDevices;

    if (blockDevices.isEmpty) {
      print('No block devices found.');
      return;
    }

    final targetLabel = 'Specific drive name that you have';
    final device = blockDevices.firstWhere(
      (dev) => dev.idLabel == targetLabel,
      orElse: () => throw Exception('Device with label $targetLabel not found'),
    );

    // Display device information
    final devicePath = utf8.decode(device.preferredDevice.isNotEmpty
        ? device.preferredDevice
        : device.device);
    print('Found target device: $devicePath');
    print('  ID Label: ${device.idLabel}');
    print('  ID UUID: ${device.idUUID}');
    print('  Size: ${device.size} bytes');

    // Check if the device has a filesystem interface
    final fs = device.filesystem;
    if (fs == null) {
      print('  No filesystem interface detected on this device.');
      return;
    }

    print('  Filesystem Information:');
    print('    Mount Points: ${fs.mountPoints.join(', ')}');

    // If the device is not mounted, attempt to mount it
    if (fs.mountPoints.isEmpty) {
      print('  Device is not mounted. Attempting to mount...');
      try {
        final mountPath = await fs.mount();
        print('  Successfully mounted at: $mountPath');
      } catch (e) {
        print('  Failed to mount: $e');
      }
    } else {
      print('  Device is already mounted at: ${fs.mountPoints.join(', ')}');

      // Optionally, attempt to unmount
      print('  Attempting to unmount...');
      try {
        await fs.unmount();
        print('  Successfully unmounted');
      } catch (e) {
        print('  Failed to unmount: $e');
      }
    }

    // Access the filesystem size
    try {
      print('  Filesystem Size: ${fs.size} bytes');
    } catch (e) {
      print('  Failed to get filesystem size: $e');
    }

    // Try checking the filesystem health
    try {
      bool consistent = await fs.check();
      print('  Filesystem check consistent: $consistent');
    } catch (e) {
      print('  Failed to check filesystem: $e');
    }
  } catch (e) {
    print('An error occurred: $e');
  } finally {
    // Always close the client connection when done
    print('Closing connection...');
    await client.close();
    print('Connection closed.');
  }
}

import 'package:flutter/material.dart';

AppBar getAppBar(context) {
  return AppBar(
    centerTitle: true,
    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    title: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('LocationTracker', style: TextStyle(fontWeight: FontWeight.bold))
        ]),
  );
}

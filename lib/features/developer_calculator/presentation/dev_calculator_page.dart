import 'package:flutter/material.dart';

import '../../../core/widgets/aura_scaffold.dart';
import 'widgets/ascii_table.dart';
import 'widgets/base_converter.dart';
import 'widgets/bitwise_calculator.dart';
import 'widgets/byte_converter.dart';
import 'widgets/timestamp_converter.dart';

/// A calculator for programmers: base conversion, bitwise ops, an ASCII table,
/// timestamp conversion and byte-size conversion.
class DevCalculatorPage extends StatelessWidget {
  const DevCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: AuraScaffold(
        appBar: AppBar(
          title: const Text('Dev tools'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Widget>[
              Tab(text: 'Bases'),
              Tab(text: 'Bitwise'),
              Tab(text: 'ASCII'),
              Tab(text: 'Timestamp'),
              Tab(text: 'Bytes'),
            ],
          ),
        ),
        extendBody: false,
        body: SafeArea(
          top: false,
          child: const TabBarView(
            children: <Widget>[
              BaseConverter(),
              BitwiseCalculator(),
              AsciiTable(),
              TimestampConverter(),
              ByteConverter(),
            ],
          ),
        ),
      ),
    );
  }
}

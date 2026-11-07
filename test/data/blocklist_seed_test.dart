import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/services/blocklist_store.dart';
import 'package:qorgan_app/domain/signals/link_signals.dart';

void main() {
  late List<String> hosts;

  setUpAll(() {
    hosts = parseHostList(File(blocklistSeedAsset).readAsStringSync());
  });

  test('the shipped seed parses into a usable list', () {
    expect(hosts.length, greaterThan(1000));
  });

  test('no bank host is in the shipped blocklist', () {
    // The rule already lets the whitelist win, but a bank appearing here at
    // all would mean the generator or the feed is wrong.
    for (final bank in officialHosts) {
      expect(hosts, isNot(contains(bank)), reason: '$bank is in the seed');
    }
  });

  test('no entry is short enough to cover a whole suffix', () {
    expect(hosts.where((host) => host.split('.').length < 2), isEmpty);
  });
}

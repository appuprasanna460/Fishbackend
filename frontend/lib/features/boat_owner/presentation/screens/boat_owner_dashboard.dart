import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tabs/boat_owner_home_tab.dart';

class BoatOwnerDashboard extends ConsumerWidget {
  const BoatOwnerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const BoatOwnerHomeTab();
  }
}

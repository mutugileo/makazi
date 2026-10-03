import 'package:flutter/material.dart';

enum RootNavigationDestination {
  dashboard,
  properties,
  tenants,
  maintenance,
  financials;

  String get label {
    switch (this) {
      case RootNavigationDestination.dashboard:
        return 'Overview';
      case RootNavigationDestination.properties:
        return 'Properties';
      case RootNavigationDestination.tenants:
        return 'Tenants';
      case RootNavigationDestination.maintenance:
        return 'Maintenance';
      case RootNavigationDestination.financials:
        return 'Financials';
    }
  }

  IconData get icon {
    switch (this) {
      case RootNavigationDestination.dashboard:
        return Icons.dashboard_outlined;
      case RootNavigationDestination.properties:
        return Icons.apartment_outlined;
      case RootNavigationDestination.tenants:
        return Icons.people_outline_rounded;
      case RootNavigationDestination.maintenance:
        return Icons.build_outlined;
      case RootNavigationDestination.financials:
        return Icons.account_balance_wallet_outlined;
    }
  }

  IconData get selectedIcon {
    switch (this) {
      case RootNavigationDestination.dashboard:
        return Icons.dashboard_rounded;
      case RootNavigationDestination.properties:
        return Icons.apartment_rounded;
      case RootNavigationDestination.tenants:
        return Icons.people_rounded;
      case RootNavigationDestination.maintenance:
        return Icons.build_rounded;
      case RootNavigationDestination.financials:
        return Icons.account_balance_wallet_rounded;
    }
  }
}

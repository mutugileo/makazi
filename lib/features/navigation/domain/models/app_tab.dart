enum AppTab {
  home,
  payments,
  repairs,
  messages;

  String get label {
    switch (this) {
      case AppTab.home:
        return 'Home';
      case AppTab.payments:
        return 'Payments';
      case AppTab.repairs:
        return 'Repairs';
      case AppTab.messages:
        return 'Messages';
    }
  }
}

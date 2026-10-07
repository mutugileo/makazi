// Demo sign-in for the prototype and the test APK only. Phase 2 removes this
// file: the manager's onboarding creates the account in Supabase and hands
// the tenant a one-time temporary password.

class DemoAccount {
  const DemoAccount({
    required this.phone,
    required this.password,
    required this.isTemporary,
  });

  final String phone;
  final String password;

  /// A temporary password must be changed at first sign-in.
  final bool isTemporary;
}

/// One demo tenant per landlord in shared/billing-seed.json, to show that
/// each only sees their own company's data:
/// David Mwangi (HarborRidge Limited, 5A Riverside Court) and
/// Naliaka Wekesa (Savanna Homes Ltd, 3 Milimani Court), plus
/// Joseph Kariuki, a former HarborRidge tenant (moved out of 2A, read-only).
const List<DemoAccount> kDemoAccounts = [
  DemoAccount(phone: '0733 605 118', password: 'Karibu-5A', isTemporary: true),
  DemoAccount(phone: '0723 555 019', password: 'Karibu-MC3', isTemporary: true),
  DemoAccount(phone: '0720 671 093', password: 'Karibu-2A', isTemporary: true),
];

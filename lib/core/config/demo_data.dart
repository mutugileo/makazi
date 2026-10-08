import 'package:flutter/foundation.dart';
import 'supabase_config.dart';

/// Demo data (the bundled tenant seed and the demo sign-ins) is available to
/// tests, debug runs and the offline demo build (`MAKAZI_DEMO=true`).
///
/// A release build that talks to Supabase gets `false`. This is a
/// compile-time constant, so the demo branches and the data they reference
/// are removed from that build rather than only skipped at runtime.
const bool kDemoDataAvailable = !kReleaseMode || SupabaseConfig.demo;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration and initialization helper.
///
/// IMPORTANT: For mobile and desktop apps prefer using a "service_role" style key
/// only on trusted backends. For client-side apps use the "anon" or a
/// publishable key configured with limited permissions. Do NOT commit secret
/// keys to source control. Use secure runtime config or environment variables.

String get _supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
String get _supabaseAnonKey => dotenv.env['SUPABASE_KEY'] ?? '';
String get supabaseBucketName =>
    (dotenv.env['SUPABASE_BUCKET'] ?? 'yub-storage').trim();

Future<void> initializeSupabase() async {
  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    throw Exception(
        'Supabase URL or Key is not set. Please provide them in .env');
  }

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
    // Optionally set debug to true during development
    debug: false,
  );

  // Optional: sanity check the configured bucket exists to catch typos early
  try {
    final client = Supabase.instance.client;
    // List root to force auth/storage wiring, then try list on the bucket root
    await client.storage.listBuckets();
    // If the bucket does not exist, a StorageException will be thrown when listing
    await client.storage.from(supabaseBucketName).list(path: '');
  } on StorageException catch (e) {
    // ignore: avoid_print
    print(
        'Supabase Storage bucket check failed for "${supabaseBucketName}": ${e.message}');
  } catch (_) {
    // ignore non-storage errors silently here to not block app start
  }
}

// Avoid providing a global getter that may be accessed before initialization.

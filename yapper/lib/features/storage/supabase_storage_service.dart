import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  // Optional injected client (useful for testing). If null, uses Supabase.instance.client lazily
  final SupabaseClient? _injectedClient;
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;
  final String _bucket;

  String get bucket => _bucket;

  SupabaseStorageService(
      {SupabaseClient? client, String bucket = 'yub-storage'})
      : _injectedClient = client,
        _bucket = bucket;

  /// Uploads a file to the given path inside the configured bucket.
  /// Returns the path on success.
  Future<String> uploadFile({
    required String path,
    required File file,
    String? contentType,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      // uploadBinary returns a String path on success in current SDK
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              cacheControl: '0',
              upsert: true,
            ),
          );
      return path;
    } on StorageException catch (e) {
      throw Exception('Supabase upload failed (bucket=$bucket): ${e.message}');
    } catch (e) {
      throw Exception('Supabase upload failed (bucket=$bucket): $e');
    }
  }

  /// Returns a public URL for a file path. If the bucket is private you'll need
  /// to create a signed URL instead.
  String getPublicUrl(String path) {
    // getPublicUrl returns a String (the public URL)
    try {
      final res = _client.storage.from(bucket).getPublicUrl(path);
      return res;
    } on StorageException catch (e) {
      // Return empty string on error; callers should handle this case
      final _ = e; // reference to avoid unused var lint
      return '';
    } catch (e) {
      // Return empty string on error; callers should handle this case
      return '';
    }
  }

  /// Removes a file at the given path.
  Future<void> removeFile(String path) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } on StorageException catch (e) {
      throw Exception('Supabase remove failed (bucket=$bucket): ${e.message}');
    } catch (e) {
      throw Exception('Supabase remove failed (bucket=$bucket): $e');
    }
  }

  /// List files in a folder (pathPrefix), non-recursive by default.
  Future<List<String>> listFiles({String path = ''}) async {
    try {
      // The SDK's list method accepts an optional path parameter.
      final res = await _client.storage.from(bucket).list(path: path);
      return res.map((e) => e.name).where((n) => n.isNotEmpty).toList();
    } on StorageException catch (e) {
      throw Exception('Supabase list failed (bucket=$bucket): ${e.message}');
    } catch (e) {
      throw Exception('Supabase list failed (bucket=$bucket): $e');
    }
  }

  /// Create a signed URL for private buckets. Expires after [expiresIn] seconds.
  Future<String> createSignedUrl(String path, {int expiresIn = 60}) async {
    try {
      final res =
          await _client.storage.from(bucket).createSignedUrl(path, expiresIn);
      return res;
    } on StorageException catch (e) {
      throw Exception(
          'Supabase createSignedUrl failed (bucket=$bucket): ${e.message}');
    } catch (e) {
      throw Exception('Supabase createSignedUrl failed (bucket=$bucket): $e');
    }
  }
}

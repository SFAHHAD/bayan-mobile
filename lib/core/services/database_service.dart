import 'package:supabase_flutter/supabase_flutter.dart';

class DuplicateEmailException implements Exception {
  const DuplicateEmailException();
}

class DatabaseService {
  final SupabaseClient client;

  DatabaseService({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  Future<int> getWaitlistCount() async {
    final res = await client
        .from('lead_emails')
        .select()
        .count(CountOption.exact);
    return res.count;
  }

  Future<bool> checkIfEmailExists(String email) async {
    final data = await client
        .from('lead_emails')
        .select('email')
        .eq('email', email)
        .maybeSingle();
    return data != null;
  }

  Future<void> addToWaitlist(String email) async {
    final exists = await checkIfEmailExists(email);
    if (exists) throw const DuplicateEmailException();
    await client.from('lead_emails').insert({'email': email});
  }
}

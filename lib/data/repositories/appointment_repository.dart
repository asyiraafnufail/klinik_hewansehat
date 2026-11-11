import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment_model.dart';

class AppointmentRepository {
  final SupabaseClient? _injectedClient;

  AppointmentRepository({SupabaseClient? client}) : _injectedClient = client;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  Future<List<AppointmentModel>> fetchAppointments({
    String search = '',
    AppointmentStatus? statusFilter,
  }) async {
    var query = _client.from('appointments').select(
          '*, pets(name, species), profiles(full_name), veterinarians(full_name), services(name, price)',
        );

    if (statusFilter != null) {
      query = query.eq('status', statusFilter.value);
    }

    final data = await query.order('appointment_date', ascending: false);
    final list = (data as List<dynamic>)
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final clean = search.trim().toLowerCase();
    if (clean.isEmpty) return list;

    return list.where((a) {
      return (a.petName ?? '').toLowerCase().contains(clean) ||
          (a.ownerName ?? '').toLowerCase().contains(clean) ||
          (a.vetName ?? '').toLowerCase().contains(clean) ||
          (a.serviceName ?? '').toLowerCase().contains(clean) ||
          a.reason.toLowerCase().contains(clean);
    }).toList();
  }

  Future<void> createAppointment(AppointmentModel appointment) async {
    await _client.from('appointments').insert(appointment.toPayload());
  }

  Future<void> updateAppointment(AppointmentModel appointment) async {
    await _client
        .from('appointments')
        .update(appointment.toPayload())
        .eq('id', appointment.id);
  }

  Future<void> updateStatus({
    required String id,
    required AppointmentStatus status,
    String? cancellationReason,
  }) async {
    await _client.from('appointments').update({
      'status': status.value,
      if (cancellationReason != null) 'cancellation_reason': cancellationReason,
    }).eq('id', id);
  }

  Future<void> deleteAppointment(String id) async {
    await _client.from('appointments').delete().eq('id', id);
  }
}

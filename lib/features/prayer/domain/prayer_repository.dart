import '../../tracking/domain/tracking_entry.dart';
import 'prayer_models.dart';

abstract interface class PrayerRepository {
  Stream<PrayerSchedule?> watchSchedule();
  Future<PrayerSchedule> saveSchedule(PrayerSchedule schedule);
  Stream<List<TrackingEntry>> watchPrayerEntries(String localDate);
  Future<TrackingEntry> savePrayerStatus({
    required PrayerName prayer,
    required String localDate,
    required PrayerCompletion status,
    JamaatStatus? jamaatStatus,
    String? notes,
  });
}

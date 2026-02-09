# Offline sync (Salah App)

## Ownership

- **Sync logic** (queue processing, Firestore writes, idempotency): [PrayerRepository](../../lib/data/repositories/prayer_repository.dart)
- **Sync state and connectivity trigger**: [SyncService](../../lib/core/services/sync_service.dart)
- **Persistence**: [DatabaseHelper](../../lib/core/services/database_helper.dart) (SQLite `sync_queue` table)

## Flow

1. User adds a prayer log (or other syncable action) while offline or when Firestore write fails → item is appended to SQLite `sync_queue` with a client-generated `clientId` (UUID) for prayer logs.
2. [SyncService](../../lib/core/services/sync_service.dart) listens to [ConnectivityService](../../lib/core/services/connectivity_service.dart); when the device goes online it calls `PrayerRepository.syncAllPending()`.
3. PrayerRepository processes each queue item (with a per-item timeout). Prayer logs are written to Firestore using `clientId` as the document ID when present, so duplicate sync runs (e.g. after app kill) do not create duplicate documents.
4. After a successful write, the item is removed from the queue; on failure, retry count is updated and exponential backoff is applied.

## Legacy

- `OfflineSyncService` was removed; all sync is handled by PrayerRepository + SyncService as above.

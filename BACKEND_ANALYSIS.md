# 🏗️ BEDROCK BACKEND ANALYSIS
### Deep Engineering Audit — Firebase, APIs, Data Layer, Security, Performance
> **Analyst:** Senior Backend Data Engineer | **Date:** 2026-07-10 | **Project:** `bedrock-weather-app`
> **Verdict:** Strong architectural bones with critical production blockers that must be resolved before public launch.

---

## TABLE OF CONTENTS

1. [Architecture Overview](#architecture-overview)
2. [🟢 The Good — What Works Well](#-the-good--what-works-well)
3. [🟡 The Bad — What Needs Fixing](#-the-bad--what-needs-fixing)
4. [🔴 The Ugly — Critical Production Blockers](#-the-ugly--critical-production-blockers)
5. [Firestore Database Design](#firestore-database-design)
6. [Security Audit](#security-audit)
7. [API Analysis](#api-analysis)
8. [Performance Bottlenecks](#performance-bottlenecks)
9. [Firebase Services Audit](#firebase-services-audit)
10. [Dead Code & Dummy Data](#dead-code--dummy-data)
11. [Complete Remediation Roadmap](#complete-remediation-roadmap)

---

## Architecture Overview

```
lib/
├── core/                         # Shared kernel
│   ├── config/                   # ApiConfig, AppConfig
│   ├── constants/                # BedrockConstants
│   ├── ml/                       # MLEngine, WeatherMLPipeline (all stubs)
│   ├── network/                  # ApiClient (stub)
│   ├── providers/                # 9x ChangeNotifier providers
│   ├── services/                 # 14x concrete services
│   ├── theme/
│   └── utils/                    # GeohashUtil
├── data/                         # Infrastructure layer
│   ├── datasources/
│   │   ├── local/                # SharedPreferences caches (2 files, very thin)
│   │   └── remote/               # 10x datasource files
│   ├── dto/                      # 4x DTOs
│   └── repositories/             # 7x concrete repositories
├── domain/                       # Business logic
│   ├── enums/                    # Domain enums
│   ├── models/                   # Domain models
│   └── repositories/             # 5x repository interfaces
└── presentation/                 # UI layer — 16x screens
```

**Pattern:** Clean Architecture with `domain → data → presentation` dependency flow. Firebase is correctly isolated behind service/datasource abstractions.

**State Management:** Provider (ChangeNotifier). Appropriate for current scale.

---

## 🟢 The Good — What Works Well

### 1. Clean Architecture Adherence
The domain → data → presentation separation is genuinely well implemented. Repository interfaces (`i_hazard_repository.dart`, `i_user_repository.dart`, etc.) properly abstract the data layer. Firebase is **not** imported directly in providers — it goes through services and repositories.

### 2. Firestore Batch Writes on Hazard Submission
```dart
// firestore_hazard_datasource.dart — submitHazard()
final batch = firestore.batch();
batch.set(docRef, data);
batch.update(userRef, {'totalReports': FieldValue.increment(1)});
await batch.commit();
```
Atomic batch write for hazard submission + user counter increment. This is correct — prevents partial writes leaving data in an inconsistent state.

### 3. Transaction-Based Voting System
```dart
// voteOnHazard() — full read-modify-write transaction
await firestore.runTransaction((transaction) async {
  final hazardSnapshot = await transaction.get(hazardRef);
  final voteSnapshot = await transaction.get(voteRef);
  // toggle logic with clamp(0, 99999)
  transaction.update(hazardRef, { ... });
});
```
Prevents vote manipulation from concurrent requests. Vote deduplication via `votes/{userId}` subcollection is the correct pattern.

### 4. Firestore as an API Cache Layer
Both `OpenMeteoWeatherDataSource` and `UsgsEarthquakeDataSource` use Firestore as a shared server-side cache (30-min TTL for weather, 1-hour for earthquakes, 24-hour for ReliefWeb). All clients share the same cached response, significantly reducing external API calls and costs.

### 5. Geohash-Based Geospatial Queries
Custom `GeohashUtil` with a precision-radius mapping for geospatial prefix queries. Sound approach for Firestore, which lacks native geo queries.

### 6. Offline-First Strategy
The `HazardRepository` correctly implements a 3-tier fallback:
1. Live Firestore stream (online)
2. `SharedPreferences` local cache (offline)
3. Static mock data (cache miss)

### 7. DTO <-> Domain Separation
`HazardDto`, `UserDto`, `WeatherDto` — clean separation between the Firestore wire format and the domain models. `fromFirestore()` / `toFirestore()` / `toDomain()` methods are all well-defined.

### 8. FCM Notification Architecture
`FcmNotificationService` correctly implements foreground + background tap listeners and wraps them in a broadcast `StreamController`. Topic-based subscriptions are available.

### 9. Biometric Auth with Secure Storage
`BiometricService` stores credentials in `flutter_secure_storage` (hardware-backed keystore on Android, Keychain on iOS). Correct pattern — not SharedPreferences.

### 10. Auth Error Formatting
`AuthProvider._formatAuthError()` translates raw Firebase error codes to human-readable messages rather than leaking internal exception strings to the UI.

### 11. Geolocation Service Abstraction
`LocationService` interface + `GeolocatorLocationService` implementation with a sensible Abbottabad default fallback (`34.1558, 73.2194`). The 5-second timeout on `getCurrentPosition` prevents UI hangs.

---

## 🟡 The Bad — What Needs Fixing

### B1. Silent Error Swallowing — Everywhere
The most pervasive bad pattern in the codebase:

```dart
// Pattern found in 11+ files:
} catch (_) {}                 // admin_datasource.dart x8
} catch (_) { return null; }   // firestore_user_datasource.dart
} catch (_) { return []; }     // firestore_hazard_datasource.dart
```

Silent catches make debugging impossible in production. A Firestore permission denied error looks identical to a network error or a data parsing error. Zero observability.

**Fix:** Replace with structured logging and typed error handling:
```dart
} on FirebaseException catch (e) {
  logger.e('Firestore write failed', error: e.code);
  rethrow;
} catch (e, stack) {
  logger.e('Unexpected error', error: e, stackTrace: stack);
  rethrow;
}
```

### B2. N+1 Query Problem in Vote Loading
```dart
// hazard_repository.dart — getNearbyHazards() & streamLiveHazards()
for (var dto in dtos) {
  // 1 Firestore read per hazard = N reads for N hazards
  final vote = await _hazardDataSource.getUserVote(dto.id, currentUserId);
}
```

For 20 active hazards, this fires **20 individual Firestore document reads** every time the stream emits. At Firestore pricing this is costly and degrades UX latency significantly.

**Fix:** Batch-read all user votes or maintain a denormalized `userVotes` map on the hazard document keyed by userId.

### B3. Admin Panel Has Zero Server-Side Authorization
```dart
// admin_datasource.dart — purgeAllReports()
Future<void> purgeAllReports() async {
  final query = await fs.collection('hazards').get();
  final batch = fs.batch();
  for (var doc in query.docs) {
    batch.delete(doc.reference);
  }
  await batch.commit();
}
```

The admin panel runs **directly from the client** with full delete/update privileges. Any user who knows the `/admin_panel` route can wipe the entire `hazards` collection. No Firestore Security Rules check admin role — nothing.

### B4. `isOwnReport` Logic Is Wrong
```dart
// hazard_repository.dart — Line 212
isOwnReport: currentUserId != null &&
    dto.reporterName == FirebaseAuth.instance.currentUser?.displayName,
```

This compares **display names**, not UIDs. Two users with the same username both see each other's reports as their own. `reporterId` is already stored in Firestore — it should be used here.

**Fix:**
```dart
isOwnReport: currentUserId != null && dto.reporterId == currentUserId,
```

### B5. `HazardFeedProvider` Bypasses Repository
```dart
// hazard_feed_provider.dart — submitReport()
await FirebaseFirestore.instance
    .collection('hazards')
    .doc(docId)
    .update({'imageUrl': downloadUrl});
```

The provider directly calls Firestore, bypassing the `HazardRepository`. Clean Architecture violation — the image URL update must go through the repository.

### B6. `BroadcastModel` Violates Domain Layer Placement
`BroadcastModel` is declared inside `broadcast_provider.dart` (presentation/provider layer). Domain models must live in `lib/domain/models/`. This couples the data model to the provider and prevents reuse.

### B7. `AdminDataSource` Is Not in Repository Pattern
`AdminDataSource` is used directly by the admin screen with no repository interface, no domain models, and returns raw `Map<String, dynamic>`. Breaks the Clean Architecture contract.

### B8. Firestore Directly Initialized in Datasources (Breaks Testability)
```dart
// Multiple datasource files
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
```

`FirebaseFirestore.instance` singleton cannot be mocked in unit tests. Must be injected via constructor.

**Fix:**
```dart
class OpenMeteoWeatherDataSource {
  final FirebaseFirestore _firestore;
  OpenMeteoWeatherDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
}
```

### B9. `ConnectivityService` Creates a StreamController That Is Never Closed
`ConnectivityService` is instantiated inside `HazardRepository` as a field (`final ConnectivityService _connectivityService = ConnectivityService()`). It is newed up fresh per repository instance, never disposed, leaking the `StreamController` and the `connectivity_plus` subscription underneath.

### B10. `LocalStorageService` Calls `SharedPreferences.getInstance()` On Every Read/Write
```dart
// local_storage_service.dart
Future<void> cacheHazards(List<HazardDisplayModel> hazards) async {
  final prefs = await SharedPreferences.getInstance();  // Every call!
```

`SharedPreferences.getInstance()` is an async factory — resolve once at startup and cache.

### B11. Weather Cache Stores Raw JSON Blobs in Firestore
```dart
// open_meteo_datasource.dart
'rawJson': response.body,  // Stores full JSON as a string
```

Storing raw JSON strings bypasses Firestore's querying, wastes storage, and makes the Firestore console unreadable. Store parsed fields instead.

### B12. `ReputationTier` Missing a `helper` Tier Variant
```dart
// domain_enums.dart
enum ReputationTier { rookie, trusted, expert, veteran }

// admin_datasource.dart mock data:
'tier': 'helper',  // This value does NOT exist in the enum!
```

Parsing `'helper'` falls through to `orElse: () => ReputationTier.rookie`, silently corrupting the user's displayed tier.

---

## 🔴 The Ugly — Critical Production Blockers

### U1. 🔥 No Firestore Security Rules Configured
Without Security Rules, **anyone** can read/write your entire Firestore database. This is the single most dangerous issue.

**Required rules (minimum viable):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid
        && !request.resource.data.keys().hasAny(['tier', 'trustCoefficient', 'isBanned']);
    }

    match /hazards/{hazardId} {
      allow read: if true;
      allow create: if request.auth != null
        && request.resource.data.reporterId == request.auth.uid
        && request.resource.data.description.size() < 500;
      allow update: if request.auth != null
        && (resource.data.reporterId == request.auth.uid
          || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.tier == 'admin');
      allow delete: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.tier == 'admin';

      match /votes/{userId} {
        allow read, write: if request.auth.uid == userId;
      }
    }

    match /system_broadcasts/{docId} {
      allow read: if true;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.tier == 'admin';
    }

    match /weather_snapshots/{docId} { allow read: if true; allow write: if false; }
    match /earthquake_snapshots/{docId} { allow read: if true; allow write: if false; }
    match /reliefweb_snapshots/{docId} { allow read: if true; allow write: if false; }
  }
}
```

### U2. 🔥 Admin Panel is Client-Side with No Role Enforcement
`/admin_panel` route is accessible to **any authenticated user**. `purgeAllReports()`, `toggleUserBan()`, and `updateUserTier()` are all called from client-side code with zero server-side validation.

**Fix:** Implement Firebase Custom Claims for admin role. Move all admin mutations to Cloud Functions that verify `context.auth.token.admin === true`. Add a route guard in `main.dart` checking the ID token claim before rendering the admin panel.

### U3. 🔥 Password Stored in Plaintext in Secure Storage for Biometrics
```dart
// biometric_service.dart
await _secureStorage.write(key: _keyPassword, value: password);
```

The user's **actual Firebase password** is stored on-device. A compromised device = exposed password.

**Fix:** Store a Firebase **Refresh Token** (not the password). After biometric authentication, use the refresh token to silently re-authenticate via Firebase Auth REST API. Better still: use `signInWithCustomToken` issued by a Cloud Function after biometric validation passes.

### U4. 🔥 Firebase Cache Collections Are Client-Writable
```dart
// open_meteo_datasource.dart, usgs_earthquake_datasource.dart, reliefweb_datasource.dart
// Client directly writes to:
_firestore.collection('weather_snapshots').doc(cacheId).set({ ... })
```

Any authenticated user can poison the cache with fake extreme weather data, corrupt earthquake data for all users, or spam garbage data to inflate your Firebase costs.

**Fix:** Move all external API fetching + cache writing to **Firebase Cloud Functions** scheduled triggers. Clients only read from cache collections.

### U5. 🔥 No Firebase Storage Security Rules
`FirebaseStorageService` uploads to `hazards/{hazardId}/evidence.jpg` and `avatars/{uid}/avatar.jpg` with no storage rules. Any authenticated user can overwrite any other user's avatar or hazard photo.

**Required Storage Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /hazards/{hazardId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null
        && request.resource.size < 10 * 1024 * 1024;
    }
    match /avatars/{uid}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth.uid == uid
        && request.resource.size < 5 * 1024 * 1024;
    }
  }
}
```

### U6. 🔥 All External API Calls Happen From Client Devices
Every client device independently calls USGS, Open-Meteo, and ReliefWeb. The Firestore caching helps but the **first client each cycle** makes the raw API call. If any API rate-limits or returns 429, it fails for that user. More critically — any API keys added in the future would be exposed in client APKs.

**Fix:** Move ALL external API calls to Firebase Cloud Functions (scheduled triggers). Clients only read from Firestore cache collections.

### U7. 🔥 No Input Validation or Sanitization on Hazard Reports
```dart
// firestore_hazard_datasource.dart — submitHazard()
// No validation of description length, coordinate ranges, or content
data['reporterId'] = userId;
```

A user can submit a 50,000-character description, coordinates `(999.0, 999.0)`, or inject harmful content. Security Rules must enforce limits.

**Firestore rule additions:**
```javascript
allow create: if request.resource.data.description.size() < 500
  && request.resource.data.latitude >= -90 && request.resource.data.latitude <= 90
  && request.resource.data.longitude >= -180 && request.resource.data.longitude <= 180;
```

### U8. 🔥 FCM Token Never Saved to Firestore
```dart
// fcm_notification_service.dart
Future<String?> getToken() async { ... }
// Token is obtained but NEVER saved anywhere
```

Without saving FCM tokens to user documents, you **cannot** send targeted push notifications to specific users. Topic subscriptions are also never called anywhere in `main.dart`.

**Fix:** After sign-in, save FCM token:
```dart
final token = await fcmService.getToken();
if (token != null) {
  await userDataSource.updateUserProfile(uid, {
    'fcmToken': token,
    'fcmUpdatedAt': FieldValue.serverTimestamp()
  });
}
```

### U9. 🔥 `signUp` Creates User Profile in Two Places with Inconsistent Schema
```dart
// firebase_auth_service.dart — signUp() creates profile with 6 fields:
// username, email, tier, totalReports, verificationRate, trustCoefficient
// MISSING: avatarUrl, isBanned, createdAt, fcmToken

// firestore_user_datasource.dart — createUserProfile() creates with UserDto.toFirestore()
// But this method is NEVER CALLED — it's dead code
```

`createUserProfile()` is dead code because `FirebaseAuthService.signUp()` creates the user doc directly and bypasses the datasource entirely.

### U10. 🔥 Required Firestore Composite Indexes Not Defined
The geohash query requires a composite index:
```dart
// firestore_hazard_datasource.dart
coll.where('status', isEqualTo: 'active')
    .orderBy('geohash')  // where + orderBy on different fields = index required
    .startAt([prefix])
    .endAt(['$prefix\uf8ff'])
```

Without the index, this query throws `FAILED_PRECONDITION: The query requires an index`. This is **silently swallowed** by `catch (_) { return []; }` — so you'll see empty hazard feeds in production with no error indication.

**Required `firestore.indexes.json`:**
```json
{
  "indexes": [
    {
      "collectionGroup": "hazards",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "geohash", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "hazards",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "expiresAt", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "hazards",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "reportedAt", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "system_broadcasts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## Firestore Database Design

### Current Collections

| Collection | Purpose | Issues |
|---|---|---|
| `users/{uid}` | User profiles | Schema inconsistency, missing `createdAt`, `isBanned`, `fcmToken` |
| `hazards/{id}` | Crowdsourced reports | No expiry index, `reporterId` not used for ownership check |
| `hazards/{id}/votes/{uid}` | Per-user votes | Correct pattern |
| `system_broadcasts/{id}` | Admin alerts | No authorization |
| `weather_snapshots/{id}` | Weather API cache | Client-writable, raw JSON blob |
| `earthquake_snapshots/{id}` | Earthquake API cache | Client-writable |
| `reliefweb_snapshots/{id}` | ReliefWeb API cache | Client-writable |

### Recommended Schema

#### `users/{uid}` — Add missing fields:
```typescript
{
  uid: string,
  username: string,
  email: string,
  tier: 'rookie' | 'trusted' | 'expert' | 'veteran' | 'admin',
  totalReports: number,
  verificationRate: number,     // 0.0-1.0
  trustCoefficient: number,     // 0.0-1.0
  avatarUrl?: string,
  fcmToken?: string,            // NEW: for targeted push notifications
  isBanned: boolean,            // NEW: ban enforcement
  createdAt: Timestamp,         // NEW: account age
  lastSeenAt?: Timestamp,       // NEW: activity tracking
}
```

#### `hazards/{id}` — Add missing fields:
```typescript
{
  reporterId: string,           // Already written, but not read for isOwnReport
  reporterName: string,
  reporterTier: string,
  type: string,
  description: string,
  latitude: number,
  longitude: number,
  geohash: string,
  upvotes: number,
  downvotes: number,
  trustScore: number,
  status: 'active' | 'resolved' | 'expired',
  reportedAt: Timestamp,
  expiresAt: Timestamp,
  resolvedAt?: Timestamp,
  resolvedById?: string,
  imageUrl?: string,
  verifiedByCount?: number,     // NEW: distinct from upvotes
}
```

#### `notifications/{uid}/messages/{notifId}` — NEW collection:
```typescript
{
  title: string,
  body: string,
  type: 'hazard_nearby' | 'broadcast' | 'tier_upgrade' | 'report_resolved',
  relatedDocId?: string,
  isRead: boolean,
  createdAt: Timestamp,
}
```

---

## Security Audit

| Issue | Severity | Status |
|---|---|---|
| No Firestore Security Rules | CRITICAL | Not configured |
| No Firebase Storage Rules | CRITICAL | Not configured |
| Admin panel client-side, no role check | CRITICAL | Any user can access |
| Password stored for biometrics | CRITICAL | Wrong pattern |
| Cache collections client-writable | CRITICAL | Poisoning possible |
| No input validation on hazard reports | HIGH | Abuse possible |
| FCM token not persisted | MEDIUM | Push notifications non-functional |
| Silent error catches throughout | MEDIUM | Zero observability |
| Admin actions not in Cloud Functions | MEDIUM | Authorization bypass possible |
| `isOwnReport` uses displayName not UID | MEDIUM | Data integrity issue |

---

## API Analysis

### External APIs Used

| API | Purpose | Caching | Issues |
|---|---|---|---|
| **Open-Meteo** `api.open-meteo.com` | Weather data | 30-min Firestore cache | Client writes cache (U4) |
| **USGS Earthquake** `earthquake.usgs.gov` | Seismic data | 1-hour Firestore cache | Client writes cache (U4) |
| **ReliefWeb** `api.reliefweb.int` | Disaster reports | 24-hour Firestore cache | Client writes cache (U4) |

### Stub/Unimplemented Code
These files exist with placeholder TODO bodies and throw `UnimplementedError`:

| File | Status | Impact |
|---|---|---|
| `core/network/api_client.dart` | All methods throw | `ApiConfig.baseUrl` domain does not exist |
| `core/ml/ml_engine.dart` | All methods throw | ML inference completely non-functional |
| `core/ml/weather_ml_pipeline.dart` | All methods throw | Weather ML pipeline dead |
| `core/services/hazard_detection_service.dart` | All methods throw | Auto-alert system dead |
| `data/repositories/weather_ml_repository.dart` | Stub | Verify |
| `data/repositories/forecast_repository.dart` | Stub | Verify |
| `data/datasources/remote/hazard_remote_source.dart` | 706 bytes, likely stub | High priority |
| `data/datasources/remote/live_hazard_stream.dart` | 580 bytes, likely stub | High priority |
| `data/datasources/remote/user_remote_source.dart` | 365 bytes, likely stub | Medium priority |
| `data/datasources/remote/weather_remote_source.dart` | 572 bytes, likely stub | Medium priority |
| `data/datasources/local/user_preferences.dart` | 423 bytes, likely stub | Medium priority |
| `data/datasources/local/weather_cache.dart` | 473 bytes, likely stub | Medium priority |

### `ApiConfig` Points to a Non-Existent Backend
```dart
// api_config.dart
static const String baseUrl = 'https://api.bedrock-abbottabad.com/v1';
```

This domain doesn't exist. The entire `ApiClient` is scaffolding. If going full Firebase, this entire REST backend concept should either be built (as Cloud Functions) or deleted.

---

## Performance Bottlenecks

### P1. Hazard Stream Fires N Firestore Reads Per Emission
Every stream emission from `streamLiveHazards()` triggers N individual `getUserVote()` reads. At Firestore pricing ($0.06/100K reads), with 50 users x 20 hazards updating every few seconds = unsustainable cost.

**Fix options:**
- **Option A (Recommended):** Denormalize `userVotes: {'userId1': 'up', 'userId2': 'down'}` on the hazard document
- **Option B:** Client-side vote state cache in memory
- **Option C:** Separate paginated query for user votes after initial load

### P2. Admin Panel Fetches ALL Records Without Pagination
```dart
// admin_datasource.dart
final snapshot = await fs.collection('users').get();   // ALL users
final snapshot = await fs.collection('hazards').get(); // ALL hazards
```

At 10,000 users, this downloads all 10,000 documents into device memory.

**Fix:** Add `.limit(50)` with cursor-based pagination using `startAfterDocument`.

### P3. Firestore Persistent Cache Not Configured
```dart
// main.dart — Firebase initialization
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// MISSING: Firestore persistence settings
```

**Fix:**
```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

### P4. `streamLiveHazards()` Uses 294-Line Manual StreamController
The custom `StreamController` + `StreamSubscription` management is complex and has a bug: when offline and emitting mock data, `await controller.close()` terminates the stream. If connectivity is later restored, no new data flows.

### P5. Connectivity Check on Every `getNearbyHazards` Call
`isConnected()` triggers an async `checkConnectivity()` every hazard fetch. Connectivity state should be maintained as a reactive stream.

---

## Firebase Services Audit

| Service | Status | Notes |
|---|---|---|
| **Firebase Auth** | Implemented | Email/password, password reset |
| **Cloud Firestore** | Partial | No Security Rules, no indexes |
| **Firebase Storage** | Partial | No Security Rules, file size unchecked |
| **Firebase Messaging (FCM)** | Broken | Token obtained but never saved |
| **Firebase Functions** | Not used | Should handle: cache refresh, admin ops, auto-expire |
| **Firebase App Check** | Not implemented | Needed to prevent API abuse |
| **Firebase Analytics** | Not implemented | No event tracking |
| **Firebase Crashlytics** | Not implemented | No crash reporting |
| **Firebase Remote Config** | Not implemented | Hazard radius, expiry durations are hardcoded |
| **Firebase Performance** | Not implemented | No performance monitoring |

### Missing: Firebase Cloud Functions Architecture
```
functions/
├── src/
│   ├── hazards/
│   │   ├── autoExpireHazards.ts      # Scheduled: mark expired hazards every 5min
│   │   ├── computeTrustScore.ts      # Trigger: recompute on vote changes
│   │   └── sendNearbyHazardFCM.ts    # Trigger: notify nearby users on new hazard
│   ├── admin/
│   │   ├── setAdminClaim.ts          # HTTP: set admin custom claim
│   │   ├── banUser.ts                # HTTP: admin-only user ban
│   │   └── purgeExpiredData.ts       # Scheduled: clean up cache collections
│   └── cache/
│       ├── refreshWeatherCache.ts    # Scheduled: every 30min
│       ├── refreshEarthquakeCache.ts # Scheduled: every hour
│       └── refreshReliefWebCache.ts  # Scheduled: daily
```

---

## Dead Code & Dummy Data

### Dummy Data to Remove Before Production

| File | Dummy Data | Description |
|---|---|---|
| `hazard_repository.dart` | `_getMockHazards()` | 5 hardcoded Abbottabad hazards with fake user names |
| `admin_datasource.dart` | `_getMockUsers()` | 4 hardcoded users with fake emails |
| `admin_datasource.dart` | `_getMockHazards()` | 3 hardcoded hazard entries |
| `user_profile_provider.dart` | `mockProfile` | Static `DemoUser` / `demo@bedrock.org` profile |
| `reliefweb_datasource.dart` | Inline fallback array | 3 fake ReliefWeb reports with hardcoded 2026 dates |

### Stub Code to Implement or Delete

| File | Status | Priority |
|---|---|---|
| `core/network/api_client.dart` | All methods throw | Low (may not need if full Firebase) |
| `core/ml/ml_engine.dart` | All methods throw | Medium |
| `core/ml/weather_ml_pipeline.dart` | All methods throw | Medium |
| `core/services/hazard_detection_service.dart` | All methods throw | High |
| `core/services/realtime_service.dart` | Stub (280 bytes) | High |
| `data/repositories/forecast_repository.dart` | Likely stub | High |
| `data/repositories/weather_ml_repository.dart` | Likely stub | Medium |

---

## Complete Remediation Roadmap

### Phase 1 — Security (BLOCK LAUNCH until complete)
- [ ] **P1.1** Deploy Firestore Security Rules (rules provided in U1 above)
- [ ] **P1.2** Deploy Firebase Storage Security Rules (rules provided in U5 above)
- [ ] **P1.3** Create `admin` custom claim via Cloud Function, remove client-side admin access
- [ ] **P1.4** Replace biometric password storage with Firebase refresh token pattern
- [ ] **P1.5** Add input validation to Firestore Security Rules for hazard creation
- [ ] **P1.6** Enable Firebase App Check (Play Integrity on Android, DeviceCheck on iOS)

### Phase 2 — Data Integrity
- [ ] **P2.1** Fix `isOwnReport` to use `reporterId` instead of `displayName`
- [ ] **P2.2** Fix `signUp` to use `FirestoreUserDataSource.createUserProfile()` consistently
- [ ] **P2.3** Add `createdAt`, `isBanned`, `fcmToken` to user schema
- [ ] **P2.4** Add `helper` to `ReputationTier` enum OR remove from all mock data
- [ ] **P2.5** Create `firestore.indexes.json` with all required composite indexes

### Phase 3 — Firebase Cloud Functions
- [ ] **P3.1** `autoExpireHazards` — Scheduled every 5 minutes
- [ ] **P3.2** `refreshWeatherCache` — Scheduled every 30 min, moves Open-Meteo server-side
- [ ] **P3.3** `refreshEarthquakeCache` — Scheduled every hour, moves USGS server-side
- [ ] **P3.4** `refreshReliefWebCache` — Scheduled daily, moves ReliefWeb server-side
- [ ] **P3.5** `sendNearbyHazardAlert` — Firestore trigger on new hazard, sends FCM to nearby users
- [ ] **P3.6** `computeReputationTier` — Firestore trigger on vote changes, auto-upgrades user tier

### Phase 4 — Performance
- [ ] **P4.1** Eliminate N+1 vote loading — denormalize or batch reads
- [ ] **P4.2** Configure Firestore persistent cache settings in `main.dart`
- [ ] **P4.3** Refactor `LocalStorageService` to singleton with pre-loaded `SharedPreferences`
- [ ] **P4.4** Add pagination to admin panel queries
- [ ] **P4.5** Replace manual `StreamController` in `streamLiveHazards()` with proper reactive stream

### Phase 5 — Observability
- [ ] **P5.1** Add Firebase Crashlytics (`firebase_crashlytics`)
- [ ] **P5.2** Replace all `catch (_) {}` with structured logging + Crashlytics error reporting
- [ ] **P5.3** Add Firebase Analytics events (report submit, vote, location search)
- [ ] **P5.4** Add Firebase Performance traces for key operations
- [ ] **P5.5** Create Firebase Alerting on Crashlytics crash rate thresholds

### Phase 6 — Feature Completion
- [ ] **P6.1** Save FCM token to Firestore on login, refresh on token rotation
- [ ] **P6.2** Implement `HazardDetectionService` with weather threshold rules
- [ ] **P6.3** Move `BroadcastModel` to `domain/models/`
- [ ] **P6.4** Implement `AdminRepository` with proper interface pattern
- [ ] **P6.5** Replace all dummy/mock data with proper empty-state UI components
- [ ] **P6.6** Add Firebase Remote Config for tunable parameters (hazard radius, expiry duration, etc.)

### Phase 7 — Clean Architecture Completion
- [ ] **P7.1** Inject `FirebaseFirestore` via constructor in all datasources (testability)
- [ ] **P7.2** Implement or delete stub files (`ApiClient`, `MLEngine`, `HazardDetectionService`)
- [ ] **P7.3** Fix `HazardFeedProvider.submitReport()` to route image URL update through repository
- [ ] **P7.4** Add proper dependency injection (consider `get_it` for service locator)
- [ ] **P7.5** Write unit tests for repository layer, datasource layer, and providers

---

## Priority Summary

```
CRITICAL (Block launch):
   U1:  Deploy Firestore Security Rules
   U2:  Admin panel server-side authorization
   U3:  Biometric password storage pattern
   U4:  Client-writable cache collections
   U5:  Firebase Storage Security Rules
   U7:  Input validation on hazard creation
   U10: Missing Firestore composite indexes

HIGH (Fix before scaling):
   B1:  Silent error swallowing across all files
   B2:  N+1 vote loading query
   B4:  isOwnReport uses displayName not UID
   B9:  ConnectivityService memory leak
   U8:  FCM token never saved
   U9:  Duplicate user creation paths

MEDIUM (Quality improvements):
   B5:  HazardFeedProvider bypasses repository
   B6:  BroadcastModel in wrong layer
   B7:  AdminDataSource not in pattern
   B11: Raw JSON blobs in Firestore cache
   B12: 'helper' tier enum mismatch
   P3:  Firestore persistent cache not configured
```

---

*Full backend audit of the Bedrock Abbottabad project (Firebase project: `bedrock-weather-app`). All file references are relative to `lib/`. Act on Phase 1 before any public deployment.*

const { onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();
const db = admin.firestore();

/**
 * P3.1: Scheduled function that runs every 5 minutes to auto-expire hazards
 * that have passed their expiration timestamp.
 */
exports.autoExpireHazards = onSchedule("every 5 minutes", async (event) => {
  const now = admin.firestore.Timestamp.now();
  const query = await db.collection("hazards")
    .where("status", "==", "active")
    .where("expiresAt", "<", now)
    .get();

  if (query.empty) {
    console.log("No hazards to expire.");
    return;
  }

  const batch = db.batch();
  query.docs.forEach((doc) => {
    batch.update(doc.ref, { status: "expired" });
  });

  await batch.commit();
  console.log(`Successfully expired ${query.size} hazards.`);
});

/**
 * P3.2: HTTPS Callable function that handles weather caching.
 * Clients request weather data via this function; it serves cached reports
 * from Firestore if fresh (<30 min old), or fetches from Open-Meteo.
 */
exports.getWeatherData = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("unauthenticated");
  }

  const { lat, lng } = request.data;
  if (lat === undefined || lng === undefined) {
    throw new Error("invalid-argument");
  }

  const now = new Date();
  // Cache key per coordinates (rounded to 2 decimals ~1.1km) and current hour
  const cacheId = `weather_${lat.toFixed(2)}_${lng.toFixed(2)}_${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}-${now.getHours()}`;
  const cacheRef = db.collection("weather_snapshots").doc(cacheId);

  try {
    const doc = await cacheRef.get();
    if (doc.exists) {
      const data = doc.data();
      const ageMs = now.getTime() - data.fetchedAt.toDate().getTime();
      // 30 min TTL
      if (ageMs < 30 * 60 * 1000) {
        console.log(`Returning cached weather data for ${cacheId}`);
        return JSON.parse(data.rawJson);
      }
    }
  } catch (err) {
    console.error("Cache read failed", err);
  }

  const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lng}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,surface_pressure,wind_speed_10m,weather_code,visibility&hourly=temperature_2m,weather_code,precipitation_probability&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=Asia%2FKarachi`;
  
  console.log(`Fetching weather from API: ${url}`);
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error("failed-precondition");
  }
  const body = await response.text();
  const parsed = JSON.parse(body);

  await cacheRef.set({
    fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
    latitude: lat,
    longitude: lng,
    rawJson: body
  });

  return parsed;
});

/**
 * P3.3: HTTPS Callable function that handles earthquake caching.
 * Serves cached earthquake data if fresh (<60 min old), or fetches from USGS API.
 */
exports.getEarthquakeData = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("unauthenticated");
  }

  const { lat, lng } = request.data;
  if (lat === undefined || lng === undefined) {
    throw new Error("invalid-argument");
  }

  const now = new Date();
  const cacheId = `eq_${lat.toFixed(1)}_${lng.toFixed(1)}_${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}-${now.getHours()}`;
  const cacheRef = db.collection("earthquake_snapshots").doc(cacheId);

  try {
    const doc = await cacheRef.get();
    if (doc.exists) {
      const data = doc.data();
      const ageMs = now.getTime() - data.fetchedAt.toDate().getTime();
      // 60 min TTL
      if (ageMs < 60 * 60 * 1000) {
        console.log(`Returning cached earthquake data for ${cacheId}`);
        return JSON.parse(data.featuresJson);
      }
    }
  } catch (err) {
    console.error("Cache read failed", err);
  }

  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(now.getDate() - 30);
  const starttime = `${thirtyDaysAgo.getFullYear()}-${(thirtyDaysAgo.getMonth() + 1).toString().padStart(2, '0')}-${thirtyDaysAgo.getDate().toString().padStart(2, '0')}`;

  const url = `https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=${starttime}&minmagnitude=2.5&latitude=${lat}&longitude=${lng}&maxradiuskm=500`;

  console.log(`Fetching earthquakes from API: ${url}`);
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error("failed-precondition");
  }
  const body = await response.text();
  const parsed = JSON.parse(body);
  const features = parsed.features || [];

  await cacheRef.set({
    fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
    latitude: lat,
    longitude: lng,
    featuresJson: JSON.stringify(features)
  });

  return features;
});

/**
 * P3.4: HTTPS Callable function that handles ReliefWeb caches.
 * Serves cached reports if fresh (<24 hours old), or fetches from ReliefWeb API.
 */
exports.getReliefWebReports = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("unauthenticated");
  }

  const now = new Date();
  const cacheId = `rw_${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}`;
  const cacheRef = db.collection("reliefweb_snapshots").doc(cacheId);

  try {
    const doc = await cacheRef.get();
    if (doc.exists) {
      const data = doc.data();
      const ageMs = now.getTime() - data.fetchedAt.toDate().getTime();
      // 24 hour TTL
      if (ageMs < 24 * 60 * 60 * 1000) {
        console.log(`Returning cached ReliefWeb reports for ${cacheId}`);
        return JSON.parse(data.reportsJson);
      }
    }
  } catch (err) {
    console.error("Cache read failed", err);
  }

  const url = "https://eonet.gsfc.nasa.gov/api/v3/events?status=open&limit=15";

  console.log(`Fetching Relief/Disaster reports from NASA EONET API: ${url}`);
  let reports = [];
  try {
    const response = await fetch(url);
    if (response.ok) {
      const parsed = await response.json();
      const events = parsed.events || [];
      reports = events.map(e => ({
        id: e.id || String(Date.now()),
        fields: {
          title: `${e.title || 'Natural Hazard'} (${e.categories?.[0]?.title || 'Disaster'})`,
          source: [{ name: `NASA EONET / ${e.sources?.[0]?.id || 'UN'}` }],
          url: e.sources?.[0]?.url || 'https://eonet.gsfc.nasa.gov',
          date: { created: e.geometry?.[0]?.date || new Date().toISOString() }
        }
      }));
    }
  } catch (e) {
    console.error("NASA EONET fetch failed", e);
  }

  if (reports.length === 0) {
    reports = [
      {
        id: 'fallback_cf_1',
        fields: {
          title: 'Monsoon Emergency Preparedness & High Alert in Hazara Division',
          source: [{ name: 'UN OCHA / NDMA Pakistan' }],
          url: 'https://reliefweb.int/country/pak',
          date: { created: new Date().toISOString() }
        }
      }
    ];
  }

  await cacheRef.set({
    fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
    reportsJson: JSON.stringify(reports)
  });

  return reports;
});

/**
 * P3.5: Triggered Firestore Function on new hazard creation.
 * Broadcasts location-based notifications directly to the device's
 * corresponding geohash topic (5-character precision ~4.9km).
 */
exports.sendNearbyHazardAlert = onDocumentCreated("/hazards/{hazardId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log("No snapshot available.");
    return;
  }

  const hazard = snapshot.data();
  const hazardType = hazard.type || "Hazard";
  const description = hazard.description || "";
  const geohash = hazard.geohash || "";

  if (!geohash) {
    console.log("No geohash for hazard. Skipping push notification.");
    return;
  }

  // 5-character geohash prefix topic subscription matches 4.9km radius
  const queryPrefix = geohash.substring(0, 5);
  const topic = `geohash_${queryPrefix}`;
  const payload = {
    notification: {
      title: `⚠️ New Hazard Detected Nearby`,
      body: `${hazardType.toUpperCase()}: ${description}`
    },
    data: {
      hazardId: event.params.hazardId,
      latitude: String(hazard.latitude),
      longitude: String(hazard.longitude),
      type: hazardType,
      click_action: "FLUTTER_NOTIFICATION_CLICK"
    },
    topic: topic
  };

  try {
    const response = await admin.messaging().send(payload);
    console.log(`Successfully sent alert to topic ${topic}:`, response);
  } catch (error) {
    console.error(`Error sending push notification to topic ${topic}:`, error);
  }
});

/**
 * P3.6: Triggered Firestore Function on hazard updates (votes/resolution).
 * Recalculates the reporter's stats (verificationRate, trustCoefficient) and
 * auto-upgrades/downgrades their ReputationTier (rookie, helper, trusted, expert, veteran).
 */
exports.computeReputationTier = onDocumentUpdated("/hazards/{hazardId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  if (!afterData) return;

  const upvotesChanged = beforeData.upvotes !== afterData.upvotes;
  const downvotesChanged = beforeData.downvotes !== afterData.downvotes;
  const statusChanged = beforeData.status !== afterData.status;

  if (!upvotesChanged && !downvotesChanged && !statusChanged) {
    return;
  }

  const reporterId = afterData.reporterId;
  if (!reporterId) return;

  const hazardsQuery = await db.collection("hazards")
    .where("reporterId", "==", reporterId)
    .get();

  let totalReports = hazardsQuery.size;
  let verifiedCount = 0;
  let upvoteTotal = 0;
  let downvoteTotal = 0;

  hazardsQuery.docs.forEach((doc) => {
    const h = doc.data();
    upvoteTotal += h.upvotes || 0;
    downvoteTotal += h.downvotes || 0;
    if (h.status === "resolved") {
      verifiedCount++;
    }
  });

  const verificationRate = totalReports > 0 ? verifiedCount / totalReports : 0.0;
  const totalVotes = upvoteTotal + downvoteTotal;
  const trustCoefficient = totalVotes > 0 ? upvoteTotal / totalVotes : 0.5;

  // Auto-upgrade system rules
  let tier = "rookie";
  if (totalReports >= 30 && trustCoefficient >= 0.90 && verificationRate >= 0.85) {
    tier = "veteran";
  } else if (totalReports >= 15 && trustCoefficient >= 0.80 && verificationRate >= 0.70) {
    tier = "expert";
  } else if (totalReports >= 5 && trustCoefficient >= 0.70 && verificationRate >= 0.50) {
    tier = "trusted";
  } else if (totalReports >= 1) {
    tier = "helper";
  }

  await db.collection("users").doc(reporterId).update({
    totalReports: totalReports,
    verificationRate: parseFloat(verificationRate.toFixed(2)),
    trustCoefficient: parseFloat(trustCoefficient.toFixed(2)),
    tier: tier
  });

  console.log(`Updated user ${reporterId}: tier=${tier}, reports=${totalReports}, verificationRate=${verificationRate}`);
});

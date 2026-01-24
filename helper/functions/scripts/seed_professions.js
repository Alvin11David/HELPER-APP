/**
 * Seed professions into Firestore.
 *
 * File locations (your project):
 * - Script: functions/scripts/seed_professions.js
 * - Data:   assets/data/professions.json
 * - Key:    functions/serviceAccountKey.json
 *
 * Run:
 *   cd functions
 *   npm i firebase-admin
 *   node scripts/seed_professions.js
 */

const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

const SERVICE_ACCOUNT_PATH = path.resolve(__dirname, "../serviceAccountKey.json");
const PROFESSIONS_JSON_PATH = path.resolve(__dirname, "../../assets/data/professions.json");

if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error("❌ Missing serviceAccountKey.json at:", SERVICE_ACCOUNT_PATH);
  console.error("Download it from Firebase Console > Project Settings > Service Accounts.");
  process.exit(1);
}

if (!fs.existsSync(PROFESSIONS_JSON_PATH)) {
  console.error("❌ Missing professions.json at:", PROFESSIONS_JSON_PATH);
  process.exit(1);
}

const serviceAccount = require(SERVICE_ACCOUNT_PATH);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

function normalize(s) {
  return (s || "")
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim();
}

function docIdFromName(name) {
  // stable ID: "software_engineer", "police_officer"
  return normalize(name).replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
}

function keywordsFromName(name) {
  const n = normalize(name);
  const parts = n.split(" ").filter(Boolean);
  return Array.from(new Set(parts));
}

async function main() {
  const raw = fs.readFileSync(PROFESSIONS_JSON_PATH, "utf8");
  const items = JSON.parse(raw);

  if (!Array.isArray(items)) {
    throw new Error("professions.json must be an array of objects");
  }

  const col = db.collection("professions");

  const batchLimit = 450; // safe under 500
  let batch = db.batch();
  let countInBatch = 0;
  let total = 0;

  for (const item of items) {
    const name = (item.name || "").trim();
    if (!name) continue;

    const docId = item.id ? String(item.id) : docIdFromName(name);
    const ref = col.doc(docId);

    const payload = {
      id: docId,
      name,
      normalized: normalize(name),
      category: (item.category || "Other").trim(),
      isProfessional: !!item.isProfessional,
      isActive: item.isActive !== false,
      keywords: Array.isArray(item.keywords) && item.keywords.length
        ? item.keywords
        : keywordsFromName(name),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    batch.set(ref, payload, { merge: true });
    countInBatch++;
    total++;

    if (countInBatch >= batchLimit) {
      await batch.commit();
      console.log(`✅ Committed batch of ${countInBatch} (total so far: ${total})`);
      batch = db.batch();
      countInBatch = 0;
    }
  }

  if (countInBatch > 0) {
    await batch.commit();
    console.log(`✅ Committed last batch of ${countInBatch}`);
  }

  console.log(`🎉 Done. Total seeded/updated: ${total}`);
}

main().catch((e) => {
  console.error("❌ Seed failed:", e);
  process.exit(1);
});

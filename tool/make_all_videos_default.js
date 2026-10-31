// tool/make_all_videos_default.js
//
// Opens EVERY published video to EVERY member — no new app version needed.
// Members' current app already plays any video marked "Default"
// (free: true) on every platform, and firestore.rules already lets any
// active member read it. This script sets free: true on every published
// video that is still "Custom".
//
// SETUP (once):
//   1. Firebase console → Project settings → Service accounts →
//      Generate new private key. Save it OUTSIDE the repo, e.g.
//      ~/asec-service-account.json  (never commit it).
//   2. cd tool && npm install firebase-admin
//
// RUN:
//   node make_all_videos_default.js ~/asec-service-account.json --dry-run   (preview only)
//   node make_all_videos_default.js ~/asec-service-account.json             (apply)
//   node make_all_videos_default.js ~/asec-service-account.json --undo videos_default_backup.json
//
// Applying writes videos_default_backup.json with the ids it changed, so
// --undo puts exactly those back to Custom.

const fs = require('fs');
const path = require('path');
// firebase-admin 12+ modular API (the old admin.credential is gone in v14).
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const [, , keyArg, ...rest] = process.argv;
if (!keyArg) {
  console.error('Usage: node make_all_videos_default.js <service-account.json> [--dry-run | --undo <backup.json>]');
  process.exit(1);
}
const keyPath = keyArg.replace(/^~/, process.env.HOME);
const dryRun = rest.includes('--dry-run');
const undoIdx = rest.indexOf('--undo');
const undoFile = undoIdx >= 0 ? rest[undoIdx + 1] : null;

initializeApp({ credential: cert(require(path.resolve(keyPath))) });
const db = getFirestore();

async function commitInBatches(ids, data) {
  for (let i = 0; i < ids.length; i += 400) {
    const batch = db.batch();
    for (const id of ids.slice(i, i + 400)) {
      batch.update(db.collection('videos').doc(id), {
        ...data,
        updated_at: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    console.log(`  ✓ ${Math.min(i + 400, ids.length)} / ${ids.length}`);
  }
}

(async () => {
  if (undoFile) {
    const ids = JSON.parse(fs.readFileSync(undoFile, 'utf8')).ids || [];
    console.log(`Undo: ${ids.length} video(s) back to Custom (free: false).`);
    if (!dryRun) await commitInBatches(ids, { free: false });
    console.log('Done.');
    return;
  }

  const snap = await db.collection('videos').where('published', '==', true).get();
  const toOpen = [];
  const byCourse = {};
  for (const d of snap.docs) {
    if (d.get('free') === true) continue;
    toOpen.push(d.id);
    const c = (d.get('category') || '(no course)').toString().trim();
    byCourse[c] = (byCourse[c] || 0) + 1;
  }
  console.log(`Published videos: ${snap.size}. Already Default: ${snap.size - toOpen.length}. To open: ${toOpen.length}.`);
  for (const [c, n] of Object.entries(byCourse).sort()) console.log(`  ${c}: ${n}`);

  if (dryRun) {
    console.log('\nDry run — nothing changed. Run again without --dry-run to apply.');
    return;
  }
  if (toOpen.length === 0) {
    console.log('Nothing to do.');
    return;
  }
  const backup = path.resolve('videos_default_backup.json');
  fs.writeFileSync(backup, JSON.stringify({ at: new Date().toISOString(), ids: toOpen }, null, 2));
  console.log(`Backup of changed ids: ${backup}`);
  await commitInBatches(toOpen, { free: true });
  console.log('\nDone — every published video is now Default (open to all members, all platforms).');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});

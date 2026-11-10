// tool/open_all_courses_for_members.js
//
// Gives every EXISTING member the same course access a NEW member gets:
// every course open. New accounts have no `courses_all` field, which the
// app and firestore.rules (hasCourse) read as "all courses". Older members
// were saved through Members → Edit access, so they still carry
// courses_all: false / a ticked list / closed_courses / per-course limits,
// and some courses stay locked for them.
//
// For every member (role == 'user') this sets:
//   courses_all: true, courses: [], closed_courses: [], course_access: {}
// It does NOT touch platforms, access period, pause, devices, CV or calcs.
//
// SETUP (once) — same key as make_all_videos_default.js:
//   Firebase console → Project settings → Service accounts → Generate new
//   private key, saved OUTSIDE the repo (e.g. ~/asec-service-account.json).
//
// RUN (from the project folder, where firebase-admin is installed):
//   node tool/open_all_courses_for_members.js ~/asec-service-account.json --dry-run   (preview only)
//   node tool/open_all_courses_for_members.js ~/asec-service-account.json             (apply)
//   node tool/open_all_courses_for_members.js ~/asec-service-account.json --undo members_courses_backup.json
//
// Applying first writes members_courses_backup.json with each changed
// member's previous values, so --undo puts exactly those back.

const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');

// Timestamps (per-course dates) survive the JSON backup and come back as Timestamps.
const toJson = (_k, v) =>
  v && typeof v === 'object' && typeof v._seconds === 'number' && typeof v._nanoseconds === 'number'
    ? { __ts: v._seconds * 1000 + Math.round(v._nanoseconds / 1e6) }
    : v;
const fromJson = (_k, v) => (v && typeof v === 'object' && typeof v.__ts === 'number' ? Timestamp.fromMillis(v.__ts) : v);

const [, , keyArg, ...rest] = process.argv;
if (!keyArg) {
  console.error('Usage: node open_all_courses_for_members.js <service-account.json> [--dry-run | --undo <backup.json>]');
  process.exit(1);
}
const keyPath = keyArg.replace(/^~/, process.env.HOME);
const dryRun = rest.includes('--dry-run');
const undoIdx = rest.indexOf('--undo');
const undoFile = undoIdx >= 0 ? rest[undoIdx + 1] : null;

initializeApp({ credential: cert(require(path.resolve(keyPath))) });
const db = getFirestore();

const FIELDS = ['courses_all', 'courses', 'closed_courses', 'course_access'];

async function commitInBatches(entries) {
  for (let i = 0; i < entries.length; i += 400) {
    const batch = db.batch();
    for (const [uid, data] of entries.slice(i, i + 400)) {
      batch.update(db.collection('users').doc(uid), {
        ...data,
        updated_at: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    console.log(`  ✓ ${Math.min(i + 400, entries.length)} / ${entries.length}`);
  }
}

function isLocked(d) {
  const all = d.get('courses_all');
  const closed = d.get('closed_courses') || [];
  const perCourse = d.get('course_access') || {};
  return all === false || closed.length > 0 || Object.keys(perCourse).length > 0;
}

(async () => {
  if (undoFile) {
    const members = JSON.parse(fs.readFileSync(undoFile, 'utf8'), fromJson).members || {};
    const entries = Object.entries(members).map(([uid, prev]) => {
      const data = {};
      for (const f of FIELDS) data[f] = prev[f] === undefined ? FieldValue.delete() : prev[f];
      return [uid, data];
    });
    console.log(`Undo: restoring course access of ${entries.length} member(s).`);
    if (!dryRun) await commitInBatches(entries);
    console.log('Done.');
    return;
  }

  const snap = await db.collection('users').where('role', '==', 'user').get();
  const locked = snap.docs.filter(isLocked);
  console.log(`Members: ${snap.size}. Already all-open: ${snap.size - locked.length}. To open: ${locked.length}.`);
  for (const d of locked) {
    const shown = d.get('courses_all') === false ? (d.get('courses') || []).join(', ') || '(none ticked)' : 'all, with limits';
    console.log(`  ${d.get('email') || d.id}: ${shown}`);
  }

  if (dryRun) {
    console.log('\nDry run — nothing changed. Run again without --dry-run to apply.');
    return;
  }
  if (locked.length === 0) {
    console.log('Nothing to do.');
    return;
  }

  const backup = { at: new Date().toISOString(), members: {} };
  for (const d of locked) {
    const prev = {};
    for (const f of FIELDS) if (d.get(f) !== undefined) prev[f] = d.get(f);
    backup.members[d.id] = prev;
  }
  const backupPath = path.resolve('members_courses_backup.json');
  fs.writeFileSync(backupPath, JSON.stringify(backup, toJson, 2));
  console.log(`Backup of previous access: ${backupPath}`);

  await commitInBatches(locked.map((d) => [d.id, {
    courses_all: true,
    courses: [],
    closed_courses: [],
    course_access: {},
  }]));
  console.log('\nDone — every member now has every course open, like a new account.');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});

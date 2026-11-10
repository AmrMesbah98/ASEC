// tool/open_phones_for_members.js
//
// Courses locked on iPhone but open on Android: the member's `platforms`
// list was saved on Members → Edit access WITHOUT 'ios' (or without
// 'android'). A new member has no list, which means Android + iPhone.
// This adds 'android' and 'ios' to every member whose saved list is
// missing one — Mac / Windows they already have are kept. Also fixes the
// same list inside each course's own settings (course_access).
//
// RUN (from the ASEC folder):
//   node tool/open_phones_for_members.js ~/asec-service-account.json --dry-run
//   node tool/open_phones_for_members.js ~/asec-service-account.json
// Applying writes members_platforms_backup.json first.

const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const [, , keyArg, ...rest] = process.argv;
if (!keyArg) {
  console.error('Usage: node open_phones_for_members.js <service-account.json> [--dry-run]');
  process.exit(1);
}
const dryRun = rest.includes('--dry-run');
initializeApp({ credential: cert(require(path.resolve(keyArg.replace(/^~/, process.env.HOME)))) });
const db = getFirestore();

const PHONES = ['android', 'ios'];
// A saved list missing a phone gets both; an empty list already means phones.
const fix = (list) => {
  const l = Array.isArray(list) ? list : [];
  if (l.length === 0 || PHONES.every((p) => l.includes(p))) return null;
  return [...new Set([...l, ...PHONES])];
};

(async () => {
  const snap = await db.collection('users').where('role', '==', 'user').get();
  const changes = [];
  const backup = { at: new Date().toISOString(), members: {} };
  for (const d of snap.docs) {
    const p = fix(d.get('platforms'));
    const ca = d.get('course_access') || {};
    const caNeedsFix = Object.values(ca).some((a) => a && fix(a.platforms));
    if (p || caNeedsFix) {
      changes.push([d, p, ca]);
      backup.members[d.id] = { platforms: d.get('platforms') ?? null, course_access: ca };
    }
  }
  console.log(`Members: ${snap.size}. Missing iPhone or Android: ${changes.length}.`);
  for (const [d] of changes) {
    console.log(`  ${d.get('email') || d.id}: ${(d.get('platforms') || []).join(', ') || '(course settings only)'}`);
  }
  if (dryRun) {
    console.log('\nDry run — nothing changed. Run again without --dry-run to apply.');
    return;
  }
  if (!changes.length) {
    console.log('Nothing to do.');
    return;
  }
  fs.writeFileSync(path.resolve('members_platforms_backup.json'), JSON.stringify(backup, null, 2));
  console.log('Backup: members_platforms_backup.json');
  for (let i = 0; i < changes.length; i += 400) {
    const batch = db.batch();
    for (const [d, p, ca] of changes.slice(i, i + 400)) {
      const data = { updated_at: FieldValue.serverTimestamp() };
      if (p) data.platforms = p;
      const newCa = {};
      let caChanged = false;
      for (const [course, a] of Object.entries(ca)) {
        const cp = a && fix(a.platforms);
        newCa[course] = cp ? { ...a, platforms: cp } : a;
        if (cp) caChanged = true;
      }
      if (caChanged) data.course_access = newCa;
      batch.update(d.ref, data);
    }
    await batch.commit();
    console.log(`  ✓ ${Math.min(i + 400, changes.length)} / ${changes.length}`);
  }
  console.log('\nDone — every member now has courses open on Android and iPhone.');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});

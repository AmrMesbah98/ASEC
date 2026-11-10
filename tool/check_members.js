// tool/check_members.js — READ ONLY. Counts every account in `users` and
// shows what could keep courses locked. Changes nothing.
//   node tool/check_members.js ~/asec-service-account.json
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({ credential: cert(require(path.resolve(process.argv[2].replace(/^~/, process.env.HOME)))) });
const db = getFirestore();

(async () => {
  const snap = await db.collection('users').get();
  const now = Date.now();
  const roles = {};
  const c = { coursesLocked: 0, platformsSet: 0, platformsDefault: 0, perCourse: 0, expired: 0, notStarted: 0, paused: 0, inactive: 0 };
  const platformMix = {};
  for (const d of snap.docs) {
    const x = d.data();
    const role = x.role === undefined ? '(no role)' : String(x.role);
    roles[role] = (roles[role] || 0) + 1;
    if (role === 'admin') continue;
    if (x.courses_all === false || (x.closed_courses || []).length) c.coursesLocked++;
    if (Object.keys(x.course_access || {}).length) c.perCourse++;
    const p = x.platforms || [];
    if (p.length) { c.platformsSet++; const k = [...p].sort().join('+'); platformMix[k] = (platformMix[k] || 0) + 1; }
    else c.platformsDefault++;
    if (x.access_until && x.access_until.toMillis() < now) c.expired++;
    if (x.access_from && x.access_from.toMillis() > now) c.notStarted++;
    if (x.paused_at) c.paused++;
    if (x.active === false) c.inactive++;
  }
  console.log(`All accounts in users: ${snap.size}`);
  console.log('By role:', roles);
  console.log('\nMembers (not admin):');
  console.log(`  courses locked (courses_all false / closed): ${c.coursesLocked}`);
  console.log(`  per-course dates/platforms set:              ${c.perCourse}`);
  console.log(`  platforms not set (= Android + iPhone only): ${c.platformsDefault}`);
  console.log(`  platforms set:                               ${c.platformsSet}`, platformMix);
  console.log(`  access period ended:                         ${c.expired}`);
  console.log(`  access period not started:                   ${c.notStarted}`);
  console.log(`  paused:                                      ${c.paused}`);
  console.log(`  blocked (active false):                      ${c.inactive}`);
})().catch((e) => { console.error(e); process.exit(1); });

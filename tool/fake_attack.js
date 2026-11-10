// tool/fake_attack.js — adds a TEST security alert, so you can see how the
// super admin's Settings → Security alerts shows an attack. Nothing is
// attacked; it only writes one `security_events` document, like the app's
// SecurityMonitor does. Delete it from the app (Delete / Clear all).
//
//   node tool/fake_attack.js ~/asec-service-account.json            (sniffer alert)
//   node tool/fake_attack.js ~/asec-service-account.json stream     (video grabbed)
//   node tool/fake_attack.js ~/asec-service-account.json download   (too many downloads)
//   node tool/fake_attack.js ~/asec-service-account.json all        (all three)
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const [, , keyArg, which = 'mitm'] = process.argv;
if (!keyArg) {
  console.error('Usage: node tool/fake_attack.js <service-account.json> [mitm | stream | download | all]');
  process.exit(1);
}
initializeApp({ credential: cert(require(path.resolve(keyArg.replace(/^~/, process.env.HOME)))) });
const db = getFirestore();

const KINDS = {
  mitm: ['mitm', 'TEST — The connection to www.googleapis.com was intercepted (certificate issuer: Charles Proxy CA). An HTTPS sniffing tool is likely running.'],
  stream: ['stream_grab', 'TEST — A lesson stream was requested by a download tool, not by the app player.'],
  download: ['download_burst', 'TEST — 12 lessons were downloaded within one minute.'],
};
const picked = which === 'all' ? Object.keys(KINDS) : [which];
if (picked.some((k) => !KINDS[k])) {
  console.error(`Unknown type "${which}". Use: mitm, stream, download or all.`);
  process.exit(1);
}

(async () => {
  for (const k of picked) {
    const [kind, detail] = KINDS[k];
    const ref = await db.collection('security_events').add({
      type: 'attack',
      kind,
      detail,
      test: true,
      uid: 'test',
      member_name: 'Test Member (fake)',
      email: 'test@example.com',
      role: 'member',
      platform: 'android',
      device_name: 'Android · Test device',
      device_id: 'test-device',
      page: 'Videos',
      course: 'AutoCAD',
      at: FieldValue.serverTimestamp(),
    });
    console.log(`✓ Test "${kind}" alert added (${ref.id}).`);
  }
  console.log('\nOpen the app as super admin → Settings → Security alerts.');
})().catch((e) => { console.error(e.message || e); process.exit(1); });

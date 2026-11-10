// tool/check_rules.js — READ ONLY. Downloads the Firestore rules that are
// LIVE on Firebase and compares them with firestore.rules in this folder.
//   node tool/check_rules.js ~/asec-service-account.json
const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getSecurityRules } = require('firebase-admin/security-rules');

initializeApp({ credential: cert(require(path.resolve(process.argv[2].replace(/^~/, process.env.HOME)))) });

(async () => {
  const live = await getSecurityRules().getFirestoreRuleset();
  const liveText = live.source[0].content;
  const local = fs.readFileSync(path.resolve(__dirname, '..', 'firestore.rules'), 'utf8');
  const out = path.resolve(__dirname, 'live_firestore.rules');
  fs.writeFileSync(out, liveText);
  console.log(`Live rules deployed at: ${live.createTime}`);
  console.log(`Live rules size: ${liveText.length} chars · local file: ${local.length} chars`);
  console.log(liveText.trim() === local.trim()
    ? 'SAME — the live rules match firestore.rules.'
    : `DIFFERENT — the live rules are NOT your firestore.rules. Saved them to ${out}`);
})().catch((e) => { console.error(e.message || e); process.exit(1); });

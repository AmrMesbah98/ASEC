// tool/deploy_rules.js — puts firestore.rules (this folder) LIVE on Firebase.
// Same as `firebase deploy --only firestore:rules`, for when the Firebase
// CLI is not installed.
//   node tool/deploy_rules.js ~/asec-service-account.json
const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getSecurityRules } = require('firebase-admin/security-rules');

initializeApp({ credential: cert(require(path.resolve(process.argv[2].replace(/^~/, process.env.HOME)))) });

(async () => {
  const source = fs.readFileSync(path.resolve(__dirname, '..', 'firestore.rules'), 'utf8');
  const r = await getSecurityRules().releaseFirestoreRulesetFromSource(source);
  console.log(`Done — firestore.rules is live (ruleset ${r.name}, ${r.createTime}).`);
})().catch((e) => { console.error(e.message || e); process.exit(1); });

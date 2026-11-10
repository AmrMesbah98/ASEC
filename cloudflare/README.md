# ASEC lessons on Cloudflare R2 — setup (once)

Why: Google Drive blocks a public lesson for up to 24 h after "too many users
viewed or downloaded" it. R2 has no such limit and no bandwidth charge.

How it works: Drive stays the lesson LIST. Each lesson FILE is copied to R2
as `lessons/<drive file id>` (Settings → Cloudflare lessons → Copy lessons).
With Settings → Control centre → "Play lessons from Cloudflare" ON, members
play ONLY from R2 through the Worker (`worker.js`), never from Drive.

Account: the SAME Cloudflare account as ENGX (amrmesbah2023).

1. R2 → Create bucket `asec-lessons` (Standard, private).
2. Workers & Pages → Create → Hello World → name `asec-lessons` → Deploy →
   Edit code → paste all of `cloudflare/worker.js` → Deploy.
3. Worker → Settings → Bindings → Add → R2 bucket: `BUCKET` → `asec-lessons`.
4. Worker → Settings → Variables and Secrets → Add:
   - `FIREBASE_PROJECT_ID` (Text) = `asec-a811b`
   - `ADMIN_EMAIL` (Text) = `amrmesbah33@gmail.com`
   - `SIGN_KEY` (Secret) = `ce79317deb28684fa967783c88724f6e5e5f190d203d0c5999238861bea1ae36`
5. Open the Worker address: it must show "ASEC lessons".
   The app expects `https://asec-lessons.<account subdomain>.workers.dev` —
   send the address to update `CloudLessons` if the subdomain differs.
6. In the app (admin): Settings → Cloudflare lessons → Copy lessons.
7. Settings → Control centre → "Play lessons from Cloudflare" → ON.
8. Workers plans → Workers Paid ($5/month) when requests near 100k/day.

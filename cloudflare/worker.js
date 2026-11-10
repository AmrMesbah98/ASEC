// ASEC lessons — Cloudflare Worker (07/11/2026)
//
// Serves lesson videos from the private R2 bucket to the ENGX app only, and
// lets the admin (Firebase sign-in as ADMIN_EMAIL) upload into it.
//
//   GET/HEAD /v/<key>?e=<unix>&d=<device>&s=<hmac>   → the video (Range ok)
//   GET      /admin/has?key=<key>                     → {exists,size}
//   POST     /admin/mpu/create?key=<key>              → {uploadId}
//   PUT      /admin/mpu/part?key=&uploadId=&part=<n>  → {partNumber,etag}
//   POST     /admin/mpu/complete?key=&uploadId=       body {parts:[…]}
//   POST     /admin/mpu/abort?key=&uploadId=
//   POST     /admin/delete?key=<key>                  → {ok}
//
// Settings (Worker → Settings → Variables and Secrets / Bindings):
//   BUCKET               R2 bucket binding (the lessons bucket)
//   SIGN_KEY             secret — the same "signing key" saved in the app
//   FIREBASE_PROJECT_ID  text   — app-engx
//   ADMIN_EMAIL          text   — amrmesbah33@gmail.com

const enc = new TextEncoder();

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    try {
      if (url.pathname.startsWith('/v/')) return await serveLesson(request, env, url);
      if (url.pathname.startsWith('/admin/')) return await admin(request, env, url);
      if (url.pathname === '/') return new Response('ASEC lessons', { status: 200 });
      return new Response('Not found', { status: 404 });
    } catch (e) {
      return json({ error: String(e && e.message ? e.message : e) }, 500);
    }
  },
};

// ── Lessons (members) ───────────────────────────────────────────────────────

async function serveLesson(request, env, url) {
  if (request.method !== 'GET' && request.method !== 'HEAD') return new Response('Method not allowed', { status: 405 });
  const key = decodeURIComponent(url.pathname.slice(3));
  const e = url.searchParams.get('e') || '';
  const d = url.searchParams.get('d') || '';
  const s = url.searchParams.get('s') || '';
  const now = Math.floor(Date.now() / 1000);
  // The app signs every request with "now + 10 minutes". A phone clock up to
  // an hour wrong still works; an address copied out is dead within the hour.
  if (!key || !/^\d+$/.test(e) || Number(e) < now - 3600 || Number(e) > now + 4200) return new Response('Expired', { status: 403 });
  const expected = await hmacHex(env.SIGN_KEY, `${key}|${e}|${d}`);
  if (!timingSafeEqual(expected, s)) return new Response('Forbidden', { status: 403 });

  const headers = new Headers();
  headers.set('accept-ranges', 'bytes');
  headers.set('cache-control', 'private, no-store');
  headers.set('content-type', 'video/mp4');

  if (request.method === 'HEAD') {
    const head = await env.BUCKET.head(key);
    if (!head) return new Response('Not found', { status: 404 });
    headers.set('content-length', String(head.size));
    return new Response(null, { status: 200, headers });
  }

  const hasRange = request.headers.has('range');
  const obj = await env.BUCKET.get(key, hasRange ? { range: request.headers } : undefined);
  if (!obj) return new Response('Not found', { status: 404 });
  if (hasRange && obj.range) {
    const r = obj.range;
    const offset = r.offset !== undefined ? r.offset : (r.suffix !== undefined ? obj.size - r.suffix : 0);
    const length = r.length !== undefined ? r.length : obj.size - offset;
    headers.set('content-range', `bytes ${offset}-${offset + length - 1}/${obj.size}`);
    headers.set('content-length', String(length));
    return new Response(obj.body, { status: 206, headers });
  }
  headers.set('content-length', String(obj.size));
  return new Response(obj.body, { status: 200, headers });
}

// ── Admin (uploads) ─────────────────────────────────────────────────────────

async function admin(request, env, url) {
  const auth = request.headers.get('authorization') || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  const user = await verifyFirebase(token, env);
  // ADMIN_EMAIL may list several emails, separated by commas.
  const admins = String(env.ADMIN_EMAIL || '').toLowerCase().split(',').map((x) => x.trim()).filter(Boolean);
  if (!user || !admins.includes((user.email || '').toLowerCase())) {
    return json({ error: 'not admin' }, 401);
  }
  const key = url.searchParams.get('key') || '';
  if (!key) return json({ error: 'no key' }, 400);
  const op = url.pathname.slice('/admin/'.length);

  if (op === 'has' && request.method === 'GET') {
    const head = await env.BUCKET.head(key);
    return json({ exists: !!head, size: head ? head.size : 0 });
  }
  if (op === 'delete' && request.method === 'POST') {
    if (!key.startsWith('lessons/')) return json({ error: 'bad key' }, 400);
    await env.BUCKET.delete(key);
    return json({ ok: true });
  }
  if (op === 'mpu/create' && request.method === 'POST') {
    const mpu = await env.BUCKET.createMultipartUpload(key, { httpMetadata: { contentType: 'video/mp4' } });
    return json({ uploadId: mpu.uploadId });
  }
  const uploadId = url.searchParams.get('uploadId') || '';
  if (!uploadId) return json({ error: 'no uploadId' }, 400);
  const mpu = env.BUCKET.resumeMultipartUpload(key, uploadId);
  if (op === 'mpu/part' && request.method === 'PUT') {
    const n = Number(url.searchParams.get('part') || '0');
    if (!(n >= 1 && n <= 10000)) return json({ error: 'bad part' }, 400);
    const part = await mpu.uploadPart(n, request.body);
    return json({ partNumber: part.partNumber, etag: part.etag });
  }
  if (op === 'mpu/complete' && request.method === 'POST') {
    const body = await request.json();
    const obj = await mpu.complete(body.parts || []);
    return json({ ok: true, size: obj.size });
  }
  if (op === 'mpu/abort' && request.method === 'POST') {
    await mpu.abort();
    return json({ ok: true });
  }
  return json({ error: 'unknown' }, 404);
}

// ── Helpers ─────────────────────────────────────────────────────────────────

function json(o, status = 200) {
  return new Response(JSON.stringify(o), { status, headers: { 'content-type': 'application/json' } });
}

async function hmacHex(secret, text) {
  const k = await crypto.subtle.importKey('raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig = new Uint8Array(await crypto.subtle.sign('HMAC', k, enc.encode(text)));
  return [...sig].map((b) => b.toString(16).padStart(2, '0')).join('');
}

function timingSafeEqual(a, b) {
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}

function b64urlBytes(s) {
  s = s.replace(/-/g, '+').replace(/_/g, '/');
  while (s.length % 4) s += '=';
  const bin = atob(s);
  return Uint8Array.from(bin, (c) => c.charCodeAt(0));
}

let jwksCache = null;
let jwksAt = 0;

/** A Firebase ID token's claims when it is genuine and current, else null. */
async function verifyFirebase(token, env) {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const header = JSON.parse(new TextDecoder().decode(b64urlBytes(parts[0])));
  const claims = JSON.parse(new TextDecoder().decode(b64urlBytes(parts[1])));
  const now = Math.floor(Date.now() / 1000);
  const project = env.FIREBASE_PROJECT_ID;
  if (header.alg !== 'RS256') return null;
  if (claims.aud !== project || claims.iss !== `https://securetoken.google.com/${project}`) return null;
  if (!(claims.exp > now) || !(claims.iat <= now + 300)) return null;
  if (!jwksCache || Date.now() - jwksAt > 3600 * 1000) {
    const r = await fetch('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com');
    jwksCache = await r.json();
    jwksAt = Date.now();
  }
  const jwk = (jwksCache.keys || []).find((k) => k.kid === header.kid);
  if (!jwk) return null;
  const key = await crypto.subtle.importKey('jwk', jwk, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, b64urlBytes(parts[2]), enc.encode(`${parts[0]}.${parts[1]}`));
  return ok ? claims : null;
}

import crypto from 'node:crypto';
import https from 'node:https';
import fs from 'node:fs';
import path from 'node:path';

function httpsRequest(options, body) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(data) }); }
        catch { resolve({ status: res.statusCode, body: data }); }
      });
    });
    req.on('error', reject);
    if (body) req.write(typeof body === 'string' ? body : JSON.stringify(body));
    req.end();
  });
}

async function getAccessToken(sa) {
  const now = Math.floor(Date.now() / 1000);
  const hdr = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
  const pay = Buffer.from(JSON.stringify({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase https://www.googleapis.com/auth/cloud-platform',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600, iat: now,
  })).toString('base64url');
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(`${hdr}.${pay}`);
  const jwt = `${hdr}.${pay}.${sign.sign(sa.private_key, 'base64url')}`;
  const body = `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${encodeURIComponent(jwt)}`;
  const res = await httpsRequest({
    hostname: 'oauth2.googleapis.com', path: '/token', method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Content-Length': Buffer.byteLength(body) },
  }, body);
  if (res.status !== 200) throw new Error('Auth failed: ' + JSON.stringify(res.body));
  return res.body.access_token;
}

async function fbGet(token, path_) {
  return httpsRequest({
    hostname: 'firebase.googleapis.com', path: path_, method: 'GET',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  });
}

async function fbPost(token, path_, body) {
  const b = JSON.stringify(body);
  return httpsRequest({
    hostname: 'firebase.googleapis.com', path: path_, method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(b) },
  }, b);
}

async function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function main() {
  const saJson = process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON;
  if (!saJson) throw new Error('GOOGLE_APPLICATION_CREDENTIALS_JSON not set');
  const sa = JSON.parse(saJson);
  console.log('Project:', sa.project_id);
  console.log('Service account:', sa.client_email);

  const token = await getAccessToken(sa);
  console.log('✓ Access token obtained');

  const projectId = sa.project_id;
  const pkg = 'com.duoshield.app';

  // Check existing apps
  const listRes = await fbGet(token, `/v1beta1/projects/${projectId}/androidApps`);
  const existing = (listRes.body.apps || []).find(a => a.packageName === pkg);
  let appId;

  if (existing) {
    appId = existing.appId;
    console.log('✓ App already registered:', appId);
  } else {
    console.log('Registering Android app...');
    const regRes = await fbPost(token, `/v1beta1/projects/${projectId}/androidApps`,
      { packageName: pkg, displayName: 'DuoShield' });
    console.log('Register response status:', regRes.status);

    if (regRes.status !== 200) throw new Error('Register failed: ' + JSON.stringify(regRes.body));

    // May be a Long Running Operation
    if (regRes.body.name && regRes.body.name.includes('operations')) {
      const opName = regRes.body.name;
      console.log('Waiting for operation:', opName);
      for (let i = 0; i < 10; i++) {
        await sleep(3000);
        const opRes = await fbGet(token, `/v1/${opName}`);
        if (opRes.body.done) {
          appId = opRes.body.response?.appId;
          console.log('✓ Operation done, appId:', appId);
          break;
        }
        console.log('  Still pending...');
      }
    } else {
      appId = regRes.body.appId;
      console.log('✓ App registered:', appId);
    }
  }

  if (!appId) throw new Error('Could not get appId');

  // Get SDK config (google-services.json content, base64 encoded)
  const cfgRes = await fbGet(token, `/v1beta1/projects/${projectId}/androidApps/${appId}/config`);
  if (cfgRes.status !== 200) throw new Error('Config fetch failed: ' + JSON.stringify(cfgRes.body));

  const googleServicesJson = Buffer.from(cfgRes.body.configFileContents, 'base64').toString('utf8');
  const parsed = JSON.parse(googleServicesJson);

  // Extract key values for firebase_options.dart
  const client = parsed.client[0];
  const apiKey = client.api_key[0].current_key;
  const mobilesdkAppId = client.client_info.mobilesdk_app_id;
  const messagingSenderId = parsed.project_info.project_number;
  const projectIdOut = parsed.project_info.project_id;
  const storageBucket = parsed.project_info.storage_bucket;

  console.log('\n=== Config Values ===');
  console.log('apiKey:', apiKey);
  console.log('appId:', mobilesdkAppId);
  console.log('messagingSenderId:', messagingSenderId);
  console.log('projectId:', projectIdOut);
  console.log('storageBucket:', storageBucket);

  // Write google-services.json
  const gsPath = 'duoshield_app/android/app/google-services.json';
  fs.writeFileSync(gsPath, googleServicesJson, 'utf8');
  console.log('\n✓ Written:', gsPath);

  // Build firebase_options.dart
  const firebaseOptions = `// File generated by firebase-setup.mjs — do not edit manually.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web — '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS — '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS — '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows — '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux — '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '${apiKey}',
    appId: '${mobilesdkAppId}',
    messagingSenderId: '${messagingSenderId}',
    projectId: '${projectIdOut}',
    storageBucket: '${storageBucket}',
  );
}
`;

  const foPath = 'duoshield_app/lib/firebase_options.dart';
  fs.writeFileSync(foPath, firebaseOptions, 'utf8');
  console.log('✓ Written:', foPath);
  console.log('\n✓ Firebase setup complete!');
}

main().catch(e => { console.error('ERROR:', e.message); process.exit(1); });

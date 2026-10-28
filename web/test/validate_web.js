/**
 * Automated Validation Script for Animatto Web
 * Verifies DOM bindings, referenced assets, syntax, and Vercel configuration.
 */

const fs = require('fs');
const path = require('path');

const webDir = path.resolve(__dirname, '..');
let failures = 0;

function assert(condition, message) {
  if (!condition) {
    console.error(`❌ FAIL: ${message}`);
    failures++;
  } else {
    console.log(`✅ PASS: ${message}`);
  }
}

console.log('--- 1. Validating Core Files Exist ---');
const requiredFiles = ['index.html', 'styles.css', 'app.js', 'vercel.json', 'package.json', 'README.md'];
requiredFiles.forEach(file => {
  assert(fs.existsSync(path.join(webDir, file)), `File exists: ${file}`);
});

console.log('\n--- 2. Validating JSON Configuration ---');
try {
  const vercel = JSON.parse(fs.readFileSync(path.join(webDir, 'vercel.json'), 'utf8'));
  assert(vercel.cleanUrls === true, 'vercel.json cleanUrls enabled');
  assert(Array.isArray(vercel.headers), 'vercel.json security headers configured');
} catch (e) {
  assert(false, `vercel.json parse error: ${e.message}`);
}

try {
  const pkg = JSON.parse(fs.readFileSync(path.join(webDir, 'package.json'), 'utf8'));
  assert(pkg.name === 'animatto-web', 'package.json name matches');
} catch (e) {
  assert(false, `package.json parse error: ${e.message}`);
}

console.log('\n--- 3. Validating Sprite Assets ---');
const sprites = [
  'umamusume.png',
  'miku.png',
  'chiikawa.png',
  'sayori.png',
  'usagi.png',
  'taiyaki.png',
  'nyancat.png',
  'fattie.png'
];
sprites.forEach(sprite => {
  const spritePath = path.join(webDir, 'sprites', sprite);
  const exists = fs.existsSync(spritePath);
  assert(exists, `Sprite asset exists: sprites/${sprite}`);
  if (exists) {
    const stat = fs.statSync(spritePath);
    assert(stat.size > 1000, `Sprite size reasonable (${stat.size} bytes): sprites/${sprite}`);
  }
});

console.log('\n--- 4. Validating Media and Screenshot Assets ---');
const assets = [
  'screenshot_library.png',
  'screenshot_desktop_roaming.png',
  'screenshot_workshop.png',
  'screenshot_settings.png',
  'app_icon.png',
  'favicon.png',
  'demo.mp4'
];
assets.forEach(asset => {
  const assetPath = path.join(webDir, 'assets', asset);
  const exists = fs.existsSync(assetPath);
  assert(exists, `Asset exists: assets/${asset}`);
  if (exists) {
    const stat = fs.statSync(assetPath);
    assert(stat.size > 5000, `Asset size reasonable (${stat.size} bytes): assets/${asset}`);
  }
});

console.log('\n--- 5. Validating DOM IDs between app.js and index.html ---');
const indexHtml = fs.readFileSync(path.join(webDir, 'index.html'), 'utf8');
const appJs = fs.readFileSync(path.join(webDir, 'app.js'), 'utf8');

// Extract getElementById calls from app.js
const idMatches = appJs.match(/getElementById\(['"]([a-zA-Z0-9_-]+)['"]\)/g) || [];
const usedIds = [...new Set(idMatches.map(m => m.match(/getElementById\(['"]([a-zA-Z0-9_-]+)['"]\)/)[1]))];

console.log(`Found ${usedIds.length} element IDs accessed in app.js:`);
usedIds.forEach(id => {
  const idRegex = new RegExp(`id=["']${id}["']`);
  const found = idRegex.test(indexHtml);
  assert(found, `DOM Element ID exists in index.html: #${id}`);
});

console.log('\n--- 6. Validating JS Syntax ---');
try {
  // Syntax check via node -c
  require('child_process').execSync(`node --check ${path.join(webDir, 'app.js')}`);
  assert(true, 'app.js syntax valid (no parse errors)');
} catch (e) {
  assert(false, `app.js syntax check failed: ${e.message}`);
}

console.log('\n========================================');
if (failures === 0) {
  console.log('🎉 ALL VALIDATION CHECKS PASSED PERFECTLY!');
  process.exit(0);
} else {
  console.error(`🚨 VALIDATION COMPLETED WITH ${failures} FAILURE(S).`);
  process.exit(1);
}

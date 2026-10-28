/**
 * Automated Validation Test Suite for Animatto Web
 * Verifies DOM bindings, asset integrity, obsolete media removal, syntax, and Vercel configuration.
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const webDir = path.resolve(__dirname, '..');
const repoRoot = path.resolve(webDir, '..');
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
const coreFiles = ['index.html', 'styles.css', 'app.js', 'vercel.json', 'package.json', 'README.md'];
coreFiles.forEach(file => {
  assert(fs.existsSync(path.join(webDir, file)), `Core file exists: ${file}`);
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
    assert(stat.size > 2000, `Sprite size reasonable (${stat.size} bytes): sprites/${sprite}`);
  }
});

console.log('\n--- 4. Validating App Icon & Favicon ---');
['app_icon.png', 'favicon.png'].forEach(asset => {
  const assetPath = path.join(webDir, 'assets', asset);
  const exists = fs.existsSync(assetPath);
  assert(exists, `Icon asset exists: assets/${asset}`);
});

console.log('\n--- 5. Confirming Obsolete Media Files Are Removed ---');
const obsoleteFiles = [
  path.join(repoRoot, 'demo', 'Animatto-Demo.mp4'),
  path.join(webDir, 'assets', 'demo.mp4'),
  path.join(webDir, 'assets', 'screenshot_desktop_roaming.png'),
  path.join(webDir, 'assets', 'screenshot_library.png'),
  path.join(webDir, 'assets', 'screenshot_settings.png'),
  path.join(webDir, 'assets', 'screenshot_workshop.png')
];
obsoleteFiles.forEach(file => {
  assert(!fs.existsSync(file), `Obsolete media absent: ${path.relative(repoRoot, file)}`);
});

console.log('\n--- 6. Validating Zero Broken References to Removed Media ---');
const indexHtml = fs.readFileSync(path.join(webDir, 'index.html'), 'utf8');
const stylesCss = fs.readFileSync(path.join(webDir, 'styles.css'), 'utf8');
const appJs = fs.readFileSync(path.join(webDir, 'app.js'), 'utf8');
const webReadme = fs.readFileSync(path.join(webDir, 'README.md'), 'utf8');

const forbiddenPatterns = ['screenshot_', 'demo.mp4', 'Animatto-Demo.mp4'];
forbiddenPatterns.forEach(pat => {
  assert(!indexHtml.includes(pat), `index.html contains no references to ${pat}`);
  assert(!stylesCss.includes(pat), `styles.css contains no references to ${pat}`);
  assert(!appJs.includes(pat), `app.js contains no references to ${pat}`);
  assert(!webReadme.includes(pat), `web/README.md contains no references to ${pat}`);
});

console.log('\n--- 7. Validating DOM IDs between app.js and index.html ---');
const idMatches = appJs.match(/getElementById\(['"]([a-zA-Z0-9_-]+)['"]\)/g) || [];
const usedIds = [...new Set(idMatches.map(m => m.match(/getElementById\(['"]([a-zA-Z0-9_-]+)['"]\)/)[1]))];

console.log(`Checking ${usedIds.length} element IDs in index.html:`);
usedIds.forEach(id => {
  const idRegex = new RegExp(`id=["']${id}["']`);
  const found = idRegex.test(indexHtml);
  assert(found, `DOM Element ID exists in index.html: #${id}`);
});

console.log('\n--- 8. Validating JavaScript Syntax ---');
try {
  execSync(`node --check ${path.join(webDir, 'app.js')}`);
  assert(true, 'app.js syntax valid (no syntax/parsing errors)');
} catch (e) {
  assert(false, `app.js syntax error: ${e.message}`);
}

console.log('\n========================================');
if (failures === 0) {
  console.log('🎉 ALL VALIDATION CHECKS PASSED PERFECTLY!');
  process.exit(0);
} else {
  console.error(`🚨 VALIDATION COMPLETED WITH ${failures} FAILURE(S).`);
  process.exit(1);
}

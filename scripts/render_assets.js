// アイコン（design/icon.html）を書き出す。
//   NODE_PATH=$(npm root -g) node scripts/render_assets.js
const { chromium } = require('playwright');
const path = require('path');
const root = path.resolve(__dirname, '..');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1024, height: 1024 } });
  await page.goto('file://' + path.join(root, 'design/icon.html'));
  await page.evaluate(() => document.fonts.ready);
  await page.screenshot({ path: path.join(root, 'ios/NakabishaDojo/Assets.xcassets/AppIcon.appiconset/AppIcon.png'), omitBackground: false });
  await browser.close();
})();

// App Store 用スクリーンショット（6.9インチ: 1290×2796）を appstore/screenshots/ に書き出す。
//   NODE_PATH=$(npm root -g) node scripts/render_screenshots.js
const { chromium } = require('playwright');
const path = require('path');
const root = path.resolve(__dirname, '..');
const out = n => path.join(root, 'appstore/screenshots', n);

(async () => {
  const browser = await chromium.launch();
  for (const scheme of ['light', 'dark']) {
    const ctx = await browser.newContext({
      viewport: { width: 430, height: 932 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true, colorScheme: scheme,
    });
    const page = await ctx.newPage();
    await page.goto('file://' + path.join(root, 'ios/www/index.html'));
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(500);
    const tb = act => page.click(`#toolbar [data-act="${act}"]`);
    if (scheme === 'dark') {
      await page.click('[data-mode="test"]');
      await page.waitForTimeout(2500);
      await page.screenshot({ path: out('3-test-dark.png') });
      await ctx.close();
      continue;
    }
    // 稽古：数手進めて、手の意味が出ている局面
    // 分岐で選択ボタンが出たら最初の変化を選ぶ
    for (let i = 0; i < 6; i++) {
      if (await page.locator('#msg .choice').count()) await page.locator('#msg .choice').first().click();
      else await tb('answer');
      await page.waitForTimeout(2500);
    }
    await page.screenshot({ path: out('1-play.png') });
    // 解説シート
    await tb('detail'); await page.waitForTimeout(600);
    await page.screenshot({ path: out('2-detail.png') });
    await ctx.close();
  }
  await browser.close();
})();

// เส้นทาง Swagger UI: /api-docs (หน้าเลือก role) และ /api-docs/<role> (หน้าทดสอบของ role นั้น)
const express = require('express');
const swaggerUi = require('swagger-ui-express');
const { specs, ROLE_INFO } = require('./index');

const router = express.Router();

const ROLE_LABEL = { student: 'นักศึกษา (student)', owner: 'เจ้าของหอ (owner)', admin: 'แอดมิน (admin)' };

const escapeHtml = (text) => String(text).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
}[c]));

function landingPage() {
    const cards = Object.keys(specs).map((role) => `
        <a class="card" href="/api-docs/${role}/">
            <h2>${escapeHtml(ROLE_LABEL[role])}</h2>
            <p>${escapeHtml(ROLE_INFO[role].description.split('\n')[0])}</p>
        </a>`).join('');
    return `<!doctype html>
<html lang="th">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Ho-Phak API Docs</title>
<style>
  body { font-family: system-ui, sans-serif; margin: 0; padding: 32px 16px; background: #f5f6fa; color: #1f2937; }
  h1 { margin: 0 0 8px; font-size: 1.6rem; }
  .hint { margin: 0 0 24px; color: #4b5563; }
  .grid { display: grid; gap: 16px; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); max-width: 960px; }
  .card { display: block; background: #fff; border-radius: 12px; padding: 20px; text-decoration: none; color: inherit;
          box-shadow: 0 1px 3px rgba(0,0,0,.08); border: 1px solid #e5e7eb; }
  .card:hover { border-color: #2563eb; }
  .card h2 { margin: 0 0 8px; font-size: 1.1rem; color: #1d4ed8; }
  .card p { margin: 0; font-size: .9rem; color: #4b5563; }
</style>
</head>
<body>
<h1>Ho-Phak API Docs</h1>
<p class="hint">เลือก role ที่จะทดสอบ แต่ละหน้าแสดงเฉพาะ endpoint ของ role นั้น และ endpoint ทั่วไปที่ทุก role ใช้ร่วมกัน</p>
<div class="grid">${cards}
</div>
</body>
</html>`;
}

router.get('/', (req, res) => {
    res.type('html').send(landingPage());
});

const swaggerOptions = {
    customSiteTitle: 'Ho-Phak API Docs',
    swaggerOptions: { persistAuthorization: true, docExpansion: 'list' },
};

// ต้องใช้ serveFiles(spec) คู่กับ setup ของแต่ละ role
// ถ้าใช้ swaggerUi.serve ตัวเดียวร่วมกัน ทุกหน้าจะโหลด spec ของ role สุดท้ายแทน
for (const role of Object.keys(specs)) {
    router.use(
        `/${role}`,
        swaggerUi.serveFiles(specs[role], swaggerOptions),
        swaggerUi.setup(specs[role], swaggerOptions),
    );
}

module.exports = router;

# Ho-Phak Tests (Tester P1)

Tests for Ho-Phak: API, Unit and E2E (Node.js + Jest + Supertest), plus Flutter Widget Test templates.
Black-box testing: it calls the running Backend over HTTP, so it does not depend on how the Backend code is structured.

## Folder structure

```
tests/
├── config/endpoints.js     ← every API path (if Backend paths differ, change only this file)
├── helpers/                ← api.js (call the API), db.js (connect to MySQL / clean up data), geo.js (distance)
├── fixtures/               ← sample image and PDF for upload tests
├── seed/seed-admin.js      ← creates the test admin account
├── unit/                   ← UNIT-01..08
├── api/                    ← AUTH, OWN, STU, ADM
├── e2e/full-flow.test.js   ← E2E-01..08 Owner → Admin → Student
├── widget/                 ← Flutter Widget Test templates (copy into frontend/test/)
└── docs/bug-report-template.md
```

## How to run

1. Open XAMPP and start MySQL, then run the Backend (`node server.js` or `npm start` in the Backend folder)
2. In the `tests/` folder:
   ```bash
   npm install
   cp .env.example .env      # set BASE_URL and DB_* to match your machine
   npm run seed              # create the admin qa_admin
   npm test                  # run everything
   npm run test:api          # API only
   npm run test:e2e          # E2E only
   ```
3. Widget Test: copy the files in `widget/` into the Flutter project's `test/` folder, fix the imports, then run `flutter test`

## Notes

- Every test user's name starts with `qa_`, and the tests delete them when they finish (they do not touch real data)
- Do not run this against a production database
- A failing test = a bug in the app or an endpoint that doesn't match `endpoints.js`. Check the path/field first, then open an Issue using `docs/bug-report-template.md`

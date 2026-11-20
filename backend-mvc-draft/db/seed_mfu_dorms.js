// Additive, idempotent seed script for the 10 MFU sample dormitories.
// Usage (from backend-mvc-draft/):
//   node db/seed_mfu_dorms.js
//   (or: node --env-file=.env db/seed_mfu_dorms.js)

const fs = require('fs');
const path = require('path');

const BACKEND_ROOT = path.resolve(__dirname, '..');
const ENV_PATH = path.join(BACKEND_ROOT, '.env');
if (!process.env.DB_NAME && fs.existsSync(ENV_PATH) && typeof process.loadEnvFile === 'function') {
    process.loadEnvFile(ENV_PATH);
}

const argon2 = require('@node-rs/argon2');
const db = require('../config/db');
const { PUBLIC_UPLOAD_DIR } = require('../config/upload');
const { withTransaction } = require('../utils/transaction');
const { normalizePhone } = require('../utils/validators');

const SAMPLE_ROOT = path.resolve(BACKEND_ROOT, '..', '..', '..', 'sample_dorms_mfu');
const DORMS_JSON_PATH = path.join(SAMPLE_ROOT, 'dorms.json');
const DEFAULT_OWNER_PASSWORD = process.env.SEED_OWNER_PASSWORD || 'Owner@1234';

const CATALOG_AMENITIES = [
    'Wi-Fi',
    'CCTV',
    'Key card',
    'Air conditioner',
    'Fan',
    'Parking',
    'Washing machine',
    'Elevator',
    'Pets allowed',
];

const TRACKED_TABLES = [
    'users',
    'verifications',
    'dormitories',
    'dormitory_images',
    'amenities',
    'dormitory_amenities',
    'notification_preferences',
];

function toDbUtilityMode(mode) {
    if (mode === 'setPrice' || mode === 'set_price') return 'set_price';
    if (mode === 'included') return 'included';
    return 'not_specified';
}

function assertValidJpeg(filePath) {
    if (!fs.existsSync(filePath)) {
        throw new Error(`Missing source image: ${filePath}`);
    }
    const buf = fs.readFileSync(filePath);
    if (buf.length <= 5 * 1024) {
        throw new Error(`Source image too small (${buf.length} bytes): ${filePath}`);
    }
    if (!(buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff)) {
        throw new Error(`Source image is not a valid JPEG: ${filePath}`);
    }
    return buf;
}

function copyImageIdempotent(srcPath, destPath) {
    const srcBuf = assertValidJpeg(srcPath);
    if (fs.existsSync(destPath)) {
        const destBuf = fs.readFileSync(destPath);
        if (destBuf.equals(srcBuf)) {
            return 'existing';
        }
    }
    fs.copyFileSync(srcPath, destPath);
    return 'copied';
}

async function getLiveSchema() {
    const [tables] = await db.query('SHOW TABLES');
    const tableSet = new Set(tables.map((row) => Object.values(row)[0]));

    const columnsByTable = {};
    for (const table of TRACKED_TABLES) {
        if (!tableSet.has(table)) continue;
        const [cols] = await db.query(`DESCRIBE \`${table}\``);
        columnsByTable[table] = new Set(cols.map((c) => c.Field));
    }

    return { tableSet, columnsByTable };
}

async function getRowCounts(tableSet) {
    const counts = {};
    for (const table of TRACKED_TABLES) {
        if (!tableSet.has(table)) continue;
        const [[row]] = await db.query(`SELECT COUNT(*) AS n FROM \`${table}\``);
        counts[table] = row.n;
    }
    return counts;
}

async function ensureCatalogAmenities(tableSet) {
    const amenityMap = new Map();
    if (!tableSet.has('amenities')) return { amenityMap, inserted: 0 };

    let inserted = 0;
    for (const name of CATALOG_AMENITIES) {
        const [res] = await db.query('INSERT IGNORE INTO amenities (name) VALUES (?)', [name]);
        inserted += res.affectedRows;
    }
    const [rows] = await db.query('SELECT id, name FROM amenities ORDER BY id');
    for (const row of rows) {
        amenityMap.set(row.name, row.id);
    }
    return { amenityMap, inserted };
}

async function findActiveAdminId() {
    const [rows] = await db.query(
        "SELECT id FROM users WHERE role = 'admin' AND status = 'active' ORDER BY id ASC LIMIT 1"
    );
    return rows[0]?.id ?? null;
}

async function seed() {
    if (!fs.existsSync(DORMS_JSON_PATH)) {
        throw new Error(`Cannot find sample dataset at ${DORMS_JSON_PATH}`);
    }

    const dataset = JSON.parse(fs.readFileSync(DORMS_JSON_PATH, 'utf8'));
    const dormEntries = dataset.dorms || [];
    if (dormEntries.length === 0) {
        throw new Error('dorms.json contains no dormitories');
    }

    const [[dbRow]] = await db.query('SELECT DATABASE() AS name');
    const { tableSet, columnsByTable } = await getLiveSchema();
    const beforeCounts = await getRowCounts(tableSet);

    // 1. Verify and copy all sample images before touching the database.
    fs.mkdirSync(PUBLIC_UPLOAD_DIR, { recursive: true });
    const stats = {
        images_copied: 0,
        images_already_present: 0,
        amenities_inserted: 0,
        users_inserted: 0,
        users_existing: 0,
        verifications_inserted: 0,
        verifications_existing: 0,
        notification_prefs_inserted: 0,
        notification_prefs_existing: 0,
        dormitories_inserted: 0,
        dormitories_existing: 0,
        dorm_images_inserted: 0,
        dorm_images_existing: 0,
        dorm_amenities_inserted: 0,
        dorm_amenities_existing: 0,
    };

    const preparedImagesBySlug = new Map();
    for (const entry of dormEntries) {
        const prepared = [];
        const sortedImages = [...(entry.images || [])].sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0));
        for (let i = 0; i < sortedImages.length; i += 1) {
            const img = sortedImages[i];
            const srcPath = path.join(SAMPLE_ROOT, entry.folder, img.local_path);
            const baseName = path.basename(img.local_path);
            const destFilename = `mfu_${entry.slug}_${baseName}`;
            const destPath = path.join(PUBLIC_UPLOAD_DIR, destFilename);
            const copyResult = copyImageIdempotent(srcPath, destPath);
            if (copyResult === 'copied') stats.images_copied += 1;
            else stats.images_already_present += 1;

            prepared.push({
                file_path: `/uploads/${destFilename}`,
                sort_order: Number.isInteger(img.sort_order) ? img.sort_order : i,
            });
        }
        preparedImagesBySlug.set(entry.slug, prepared);
    }

    // 2. Ensure catalog amenities exist.
    const { amenityMap, inserted: amenitiesInserted } = await ensureCatalogAmenities(tableSet);
    stats.amenities_inserted = amenitiesInserted;

    const adminId = await findActiveAdminId();
    const userCols = columnsByTable.users || new Set();
    const dormCols = columnsByTable.dormitories || new Set();
    const hasNameCols = userCols.has('first_name') && userCols.has('surname');
    const hasUtilityModeCols =
        dormCols.has('water_utility_mode') && dormCols.has('electricity_utility_mode');

    const seededSummary = [];

    // 3. Seed each owner + dormitory atomically inside its own transaction.
    for (const entry of dormEntries) {
        const ownerData = entry.owner;
        const dormData = entry.dormitory;
        const utilData = entry.utilities || {};
        const normPhone = normalizePhone(ownerData.phone);
        const normContactPhone = dormData.contact_phone ? normalizePhone(dormData.contact_phone) : normPhone;
        const images = preparedImagesBySlug.get(entry.slug) || [];

        const record = await withTransaction(async (conn) => {
            // 3a. Owner user (lookup by normalized phone; never overwrite unrelated users)
            const [existingUsers] = await conn.query(
                'SELECT id, username, phone, role, status, is_verified FROM users WHERE phone = ?',
                [normPhone]
            );
            let ownerId;
            if (existingUsers.length > 0) {
                ownerId = existingUsers[0].id;
                stats.users_existing += 1;
            } else {
                const passwordHash = argon2.hashSync(DEFAULT_OWNER_PASSWORD);
                if (hasNameCols) {
                    const [res] = await conn.query(
                        `INSERT INTO users (username, first_name, surname, phone, password, role, status, is_verified)
                         VALUES (?, ?, ?, ?, ?, 'owner', 'active', 1)`,
                        [
                            ownerData.username,
                            ownerData.first_name || null,
                            ownerData.surname || null,
                            normPhone,
                            passwordHash,
                        ]
                    );
                    ownerId = res.insertId;
                } else {
                    const [res] = await conn.query(
                        `INSERT INTO users (username, phone, password, role, status, is_verified)
                         VALUES (?, ?, ?, 'owner', 'active', 1)`,
                        [ownerData.username, normPhone, passwordHash]
                    );
                    ownerId = res.insertId;
                }
                stats.users_inserted += 1;
            }

            // 3b. Approved verification record
            if (tableSet.has('verifications')) {
                const [existingVerif] = await conn.query(
                    'SELECT id FROM verifications WHERE owner_id = ?',
                    [ownerId]
                );
                if (existingVerif.length > 0) {
                    stats.verifications_existing += 1;
                } else {
                    await conn.query(
                        `INSERT INTO verifications (owner_id, document_url, status, submitted_at, reviewed_at, reviewed_by)
                         VALUES (?, ?, 'approved', NOW(), NOW(), ?)`,
                        [ownerId, `seeded://mfu-sample/${entry.slug}`, adminId]
                    );
                    stats.verifications_inserted += 1;
                }
            }

            // 3c. Notification preferences
            if (tableSet.has('notification_preferences')) {
                const [existingPref] = await conn.query(
                    'SELECT user_id FROM notification_preferences WHERE user_id = ?',
                    [ownerId]
                );
                if (existingPref.length > 0) {
                    stats.notification_prefs_existing += 1;
                } else {
                    const prefs = ownerData.notification_preferences || {
                        messages: true,
                        approvals: true,
                        reviews: false,
                    };
                    await conn.query(
                        `INSERT INTO notification_preferences (user_id, messages, approvals, reviews)
                         VALUES (?, ?, ?, ?)`,
                        [ownerId, prefs.messages ? 1 : 0, prefs.approvals ? 1 : 0, prefs.reviews ? 1 : 0]
                    );
                    stats.notification_prefs_inserted += 1;
                }
            }

            // 3d. Dormitory (keyed by owner_id + name)
            const [existingDorms] = await conn.query(
                'SELECT id FROM dormitories WHERE owner_id = ? AND name = ?',
                [ownerId, dormData.name]
            );
            let dormitoryId;
            if (existingDorms.length > 0) {
                dormitoryId = existingDorms[0].id;
                stats.dormitories_existing += 1;
            } else {
                const waterMode = toDbUtilityMode(utilData.water_utility_mode);
                const elecMode = toDbUtilityMode(utilData.electricity_utility_mode);
                const waterRate = waterMode === 'set_price' ? utilData.water_rate : null;
                const waterBilling = waterMode === 'set_price' ? utilData.water_billing_type : null;
                const elecRate = elecMode === 'set_price' ? utilData.electricity_rate : null;
                const elecBilling = elecMode === 'set_price' ? utilData.electricity_billing_type : null;

                const cols = [
                    'owner_id',
                    'name',
                    'zone',
                    'latitude',
                    'longitude',
                    'price_per_month',
                    'total_rooms',
                    'available_rooms',
                    'water_rate',
                    'water_billing_type',
                    'electricity_rate',
                    'electricity_billing_type',
                    'description',
                    'address',
                    'contact_phone',
                    'status',
                ];
                const vals = [
                    ownerId,
                    dormData.name,
                    dormData.zone,
                    dormData.latitude,
                    dormData.longitude,
                    dormData.price_per_month,
                    dormData.total_rooms,
                    dormData.available_rooms,
                    waterRate,
                    waterBilling,
                    elecRate,
                    elecBilling,
                    dormData.description || null,
                    dormData.address || null,
                    normContactPhone,
                    'published',
                ];
                if (hasUtilityModeCols) {
                    cols.push('water_utility_mode', 'electricity_utility_mode');
                    vals.push(waterMode, elecMode);
                }
                if (dormCols.has('status_changed_by') && dormCols.has('status_changed_at')) {
                    cols.push('status_changed_by', 'status_changed_at');
                    vals.push(adminId, new Date());
                }

                const placeholders = cols.map(() => '?').join(', ');
                const [res] = await conn.query(
                    `INSERT INTO dormitories (${cols.join(', ')}) VALUES (${placeholders})`,
                    vals
                );
                dormitoryId = res.insertId;
                stats.dormitories_inserted += 1;
            }

            // 3e. Dormitory images (idempotent by dormitory_id + file_path)
            if (tableSet.has('dormitory_images')) {
                for (const img of images) {
                    const [existingImgs] = await conn.query(
                        'SELECT id, sort_order FROM dormitory_images WHERE dormitory_id = ? AND file_path = ?',
                        [dormitoryId, img.file_path]
                    );
                    if (existingImgs.length > 0) {
                        if (existingImgs[0].sort_order !== img.sort_order) {
                            await conn.query(
                                'UPDATE dormitory_images SET sort_order = ? WHERE id = ?',
                                [img.sort_order, existingImgs[0].id]
                            );
                        }
                        stats.dorm_images_existing += 1;
                    } else {
                        await conn.query(
                            'INSERT INTO dormitory_images (dormitory_id, file_path, sort_order) VALUES (?, ?, ?)',
                            [dormitoryId, img.file_path, img.sort_order]
                        );
                        stats.dorm_images_inserted += 1;
                    }
                }
            }

            // 3f. Dormitory amenities (idempotent via INSERT IGNORE on composite PK)
            if (tableSet.has('dormitory_amenities') && tableSet.has('amenities')) {
                const names = entry.amenities?.ho_phak_amenity_names || [];
                const resolvedIds = new Set();
                for (const name of names) {
                    if (amenityMap.has(name)) {
                        resolvedIds.add(amenityMap.get(name));
                    }
                }
                if (resolvedIds.size === 0 && Array.isArray(entry.amenities?.ho_phak_amenity_ids)) {
                    for (const id of entry.amenities.ho_phak_amenity_ids) {
                        resolvedIds.add(id);
                    }
                }
                for (const amenityId of resolvedIds) {
                    const [res] = await conn.query(
                        'INSERT IGNORE INTO dormitory_amenities (dormitory_id, amenity_id) VALUES (?, ?)',
                        [dormitoryId, amenityId]
                    );
                    if (res.affectedRows > 0) stats.dorm_amenities_inserted += 1;
                    else stats.dorm_amenities_existing += 1;
                }
            }

            return {
                index: entry.index,
                slug: entry.slug,
                owner_id: ownerId,
                username: ownerData.username,
                phone: normPhone,
                dormitory_id: dormitoryId,
                dorm_name: dormData.name,
                zone: dormData.zone,
            };
        });

        seededSummary.push(record);
    }

    const afterCounts = await getRowCounts(tableSet);

    console.log(
        JSON.stringify(
            {
                database: dbRow.name,
                before_counts: beforeCounts,
                after_counts: afterCounts,
                operations: stats,
                seeded_dorms: seededSummary,
            },
            null,
            2
        )
    );
}

seed()
    .catch((err) => {
        console.error('SEED_FAILED:', err.message);
        process.exitCode = 1;
    })
    .finally(async () => {
        await db.end();
    });

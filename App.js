const express = require('express');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const con = require('./Database-Config');

const app = express();
app.use(cors());
app.use(express.json());

// อ่าน key จาก .env และหยุดทำงานถ้ายังไม่ได้ตั้งค่า
const JWT_KEY = process.env.JWT_KEY;
if (!JWT_KEY) {
    throw new Error('ยังไม่ได้ตั้งค่า JWT_KEY ใน .env');
}
// ================================ Hash ================== เดี่ยวลบตอนทำ register ให้ SQL hush เอา
// Hash password 
app.get('/api/password/:raw', (req, res) => {
    const hush = argon2.hashSync(req.params.raw);
    console.log(hush.length);
    res.send(hush);
});
// ========================================Login======================================

// Login
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;

    // เช็กว่ากรอกมาครบหรือเปล่า
    if (!username || !password) {
        return res.status(400).json({ message: 'กรุณากรอก username และ password' });
    }

    const sql = "SELECT *FROM users WHERE username = ?";
    con.query(sql, [username], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        if (result.length != 1) {
            console.error('User not found');
            return res.status(401).send('User not found');
        }

        // verify the password
        // ถ้า hash ในฐานข้อมูลอ่านไม่ได้ verifySync จะ throw ต้องดักไว้ไม่ให้ server ล่ม
        let same;
        try {
            same = argon2.verifySync(result[0].password, password);
        } catch (error) {
            console.error(error);
            return res.status(500).send('Password hash error');
        }
        if (!same) {
            console.error('Password not match');
            return res.status(401).send('Password not match');
        }

        // correct login
        // สร้าง JWT token
        const payload = { id: result[0].id, username: result[0].username, role: result[0].role };
        const token = jwt.sign(payload, JWT_KEY, { expiresIn: "1d" });
        res.json({ message: 'Login success', token });
    });
});

// =========================================Middleware======================

// รับข้อมูลของ owner (ทดสอบ middleware)
app.get('/api/owner/middleware', (req, res) => {
    // get JWT from http header
    const header = req.headers['authorization'];
    // เชคว่ามี header 
    if (!header) {
        return res.status(401).json({ message: "ม่ายมี header นะ" });
    }
    if (!header.startsWith('Bearer ')) {
        return res.status(401).json({ message: "ต้องขึ้นต้นด้วย Bearer" });
    }

    // ตัดคำว่า Bearer ออก เหลือแต่ token
    const token = header.split(' ')[1];
    // ด่านตรวจที่ 1 verify JWT && token ตั้งด่านหาเงินว่า ผิดหรือหมดอายุอะป่าว
    let payload_jwt;
    try {
        payload_jwt = jwt.verify(token, JWT_KEY);
    } catch (err) {
        const message = err.name === 'TokenExpiredError' ? 'token หมดอายุแล้ว' : 'token ไม่ถูกต้อง';
        return res.status(401).json({ message });
    }

    //ด่านตรวจที่ 2 ตั้งด่านเชคสถานะว่ายศใหญ่อะป่าว check user role ตรงอะป่าว
    const role = payload_jwt.role;
    if (role !== 'owner') {
        return res.status(403).json({ message: "Wrong user role มาจากไหนนิ admin อะป่าว เฉพาะ owner นะ" });
    }

    // ด่านตรวจที่ 3 เช็คว่า owner is_verified รึยัง กัน scammer นะ ตรวจผ่าน DB เลยเพื่อให้ได้ค่าล่าสุด
    const sql = 'SELECT is_verified FROM users WHERE id = ?';
    con.query(sql, [payload_jwt.id], (err, result) => {

        if (err) {
            return res.status(500).json({ message: 'DB Error ละ' })
        }
        if (result.length !== 1) {
            return res.status(403).json({ message: 'ไม่พบผู้ใช้งานละ' })
        }
        if (!result[0].is_verified) {
            return res.status(403).json({ message: 'ผู้ใช้งานยังไม่ได้ยืนยันตัวตนนะ' })
        }

        // ผ่านทุกด่านตรวจ ส่งข้อมูลกลับไปทดสอบ
        res.json({ message: "Welcome ครับ", user: payload_jwt });
    });
});


// ========================Register===================================
app.post('/api/auth/register', (req, res) => {
    const { username, password } = req.body;
    // 1. ตรวจว่ากรอกครบและ password ยาวพอไหม 
    if (!username || !password) {
        return res.status(400).json({ message: "กรอกข้อมูลให้ครบจ้าว" })
    }
    if (password.length < 8) {
        return res.status(400).json({ message: 'password ต้องยาวอย่างน้อย 8 ตัว' });
    }
    // 2. hash password ก่อนเก็บลง DB 
    const hash = argon2.hashSync(password);
    // 3. INSERT INTO users (username, password, role, is_verified) VALUES (?, ?, 'owner', 0)
    const sql = 'INSERT INTO users (username, password, role, is_verified) VALUES (?, ?, ?, ?)';
    con.query(sql, [username, hash, 'owner', 0], (err, result) => {
        // username ซ้ำ (ต้องมี UNIQUE ที่คอลัมน์ username)
        if (err && err.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ message: 'username นี้ถูกใช้แล้ว' });
        }
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'DB error' });
        }

        // 4. สำเร็จ
        res.status(201).json({ message: 'สมัครสมาชิกสำเร็จ', id: result.insertId });
    });
});

// ========================Dormitory CRUD===================================
app.post('/api/owner/dormitories', (req, res) => {
    // ---- middleware (เหมือนเดิม) ----
    const header = req.headers['authorization'];
    if (!header) {
        return res.status(401).json({ message: "ม่ายมี header นะ" });
    }
    if (!header.startsWith('Bearer ')) {
        return res.status(401).json({ message: "ต้องขึ้นต้นด้วย Bearer" });
    }
    const token = header.split(' ')[1];
    let payload_jwt;
    try {
        payload_jwt = jwt.verify(token, JWT_KEY);
    } catch (err) {
        const message = err.name === 'TokenExpiredError' ? 'token หมดอายุแล้ว' : 'token ไม่ถูกต้อง';
        return res.status(401).json({ message });
    }
    if (payload_jwt.role !== 'owner') {
        return res.status(403).json({ message: 'เฉพาะ owner เท่านั้น' });
    }

    // ---- 4. ตรวจข้อมูลที่ส่งมา ----
    const { name, zone, latitude, longitude, price_per_month } = req.body;
    if (!name || !zone || latitude == null || longitude == null || price_per_month == null) {
        return res.status(400).json({ message: 'กรอกข้อมูลให้ครบ' });
    }
    if (!['หน้ามอ', 'หลังมอ', 'คชพลแลนด์'].includes(zone)) {
        return res.status(400).json({ message: 'zone ไม่ถูกต้อง' });
    }
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
        return res.status(400).json({ message: 'พิกัดไม่ถูกต้อง' });
    }
    if (!Number.isInteger(price_per_month) || price_per_month <= 0) {
        return res.status(400).json({ message: 'ราคาต้องเป็นจำนวนเต็มบวก' });
    }

    // ---- 5. เช็ก is_verified จาก DB ----
    const checkSql = 'SELECT is_verified FROM users WHERE id = ?';
    con.query(checkSql, [payload_jwt.id], (err, users) => {
        if (err) {
            return res.status(500).json({ message: 'DB error' });
        }
        if (users.length !== 1) {
            return res.status(403).json({ message: 'ไม่พบผู้ใช้งาน' });
        }
        if (!users[0].is_verified) {
            return res.status(403).json({ message: 'ผู้ใช้งานยังไม่ได้ยืนยันตัวตน' });
        }

        // ---- 6. INSERT โดยใช้ owner_id จาก token ----
        const sql = 'INSERT INTO dormitories (owner_id, name, zone, latitude, longitude, price_per_month) VALUES (?, ?, ?, ?, ?, ?)';
        con.query(sql, [payload_jwt.id, name, zone, latitude, longitude, price_per_month], (err, result) => {
            if (err) {
                console.error(err);
                return res.status(500).json({ message: 'DB error' });
            }

            // ---- 7. สำเร็จ ----
            res.status(201).json({ message: 'เพิ่มหอพักสำเร็จ', id: result.insertId });
        });
    });
});

// ---- GET รายการหอของ owner คนนี้ ----
app.get('/api/owner/dormitories', (req, res) => {
    // ---- middleware ----
    const header = req.headers['authorization'];
    if (!header) {
        return res.status(401).json({ message: "ม่ายมี header นะ" });
    }
    if (!header.startsWith('Bearer ')) {
        return res.status(401).json({ message: "ต้องขึ้นต้นด้วย Bearer" });
    }
    const token = header.split(' ')[1];
    let payload_jwt;
    try {
        payload_jwt = jwt.verify(token, JWT_KEY);
    } catch (err) {
        const message = err.name === 'TokenExpiredError' ? 'token หมดอายุแล้ว' : 'token ไม่ถูกต้อง';
        return res.status(401).json({ message });
    }
    if (payload_jwt.role !== 'owner') {
        return res.status(403).json({ message: 'เฉพาะ owner เท่านั้น' });
    }

    // ---- เช็ก is_verified จาก DB ----
    const checkSql = 'SELECT is_verified FROM users WHERE id = ?';
    con.query(checkSql, [payload_jwt.id], (err, users) => {
        if (err) {
            return res.status(500).json({ message: 'DB error' });
        }
        if (users.length !== 1 || !users[0].is_verified) {
            return res.status(403).json({ message: 'ผู้ใช้งานยังไม่ได้ยืนยันตัวตน' });
        }

        // ---- ดึงรายการหอของ owner คนนี้ ----
        const sql = 'SELECT * FROM dormitories WHERE owner_id = ?';
        con.query(sql, [payload_jwt.id], (err, dormitories) => {
            if (err) {
                console.error(err);
                return res.status(500).json({ message: 'DB error' });
            }
            res.status(200).json({ dormitories });
        });
    });
});

// ---- GET หอเดียว ----
app.get('/api/owner/dormitories/:id', (req, res) => {
    // ---- middleware ----
    const header = req.headers['authorization'];
    if (!header) {
        return res.status(401).json({ message: "ม่ายมี header นะ" });
    }
    if (!header.startsWith('Bearer ')) {
        return res.status(401).json({ message: "ต้องขึ้นต้นด้วย Bearer" });
    }
    const token = header.split(' ')[1];
    let payload_jwt;
    try {
        payload_jwt = jwt.verify(token, JWT_KEY);
    } catch (err) {
        const message = err.name === 'TokenExpiredError' ? 'token หมดอายุแล้ว' : 'token ไม่ถูกต้อง';
        return res.status(401).json({ message });
    }
    if (payload_jwt.role !== 'owner') {
        return res.status(403).json({ message: 'เฉพาะ owner เท่านั้น' });
    }

    // ---- ตรวจ id ต้องเป็นตัวเลข ----
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
        return res.status(404).json({ message: 'ไม่พบหอพัก' });
    }

    // ---- เช็ก is_verified จาก DB ----
    const checkSql = 'SELECT is_verified FROM users WHERE id = ?';
    con.query(checkSql, [payload_jwt.id], (err, users) => {
        if (err) {
            return res.status(500).json({ message: 'DB error' });
        }
        if (users.length !== 1 || !users[0].is_verified) {
            return res.status(403).json({ message: 'ผู้ใช้งานยังไม่ได้ยืนยันตัวตน' });
        }

        // ---- ดึงหอเดียว ต้องเป็นของ owner คนนี้ ----
        const sql = 'SELECT * FROM dormitories WHERE id = ? AND owner_id = ?';
        con.query(sql, [id, payload_jwt.id], (err, result) => {
            if (err) {
                console.error(err);
                return res.status(500).json({ message: 'DB error' });
            }
            if (result.length === 0) {
                return res.status(404).json({ message: 'ไม่พบหอพัก' });
            }
            res.status(200).json({ dormitory: result[0] });
        });
    });
});


    app.listen(3000, () => {
        console.log('server running at http://localhost:3000');
    });
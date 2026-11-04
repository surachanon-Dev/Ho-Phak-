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

// Hash password 
app.get('/api/password/:raw', (req, res) => {
    const hush = argon2.hashSync(req.params.raw);
    console.log(hush.length);
    res.send(hush);
});

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
        // jsonwebtoken ตั้งชื่อ error ไว้ ใช้แยกว่าหมดอายุหรือผิด
        const message = err.name === 'TokenExpiredError' ? 'token หมดอายุแล้ว' : 'token ไม่ถูกต้อง';
        return res.status(401).json({ message });
    }

    //ด่านตรวจที่ 2 ตั้งด่านเชคสถานะว่ายศใหญ่อะป่าว check user role ตรงอะป่าว
    const role = payload_jwt.role;
    if(role !== 'owner') {
        return res.status(401).json({ message: "Wrong user role มาจากไหนนิ admin อะป่าว เฉพาะ owner นะ" });
    }

    // ด่านตรวจที่ 3 เช็คว่า owner is_verified รึยัง กัน scammer นะ ตรวจผ่าน DB เลยเพื่อให้ได้ค่าล่าสุด
    const sql = 'SELECT is_verified FROM users WHERE id = ?';
    con.query(sql , [payload_jwt.id] , (err, result) => {
        
        if(err) {
            return res.status(500).json({message:'DB Error ละ'})
        }
        if(result.length !== 1) {
            return res.status(403).json({message:'ไม่พบผู้ใช้งานละ'})
        }
        if(!result[0].is_verified) {
            return res.status(403).json({message:'ผู้ใช้งานยังไม่ได้ยืนยันตัวตนนะ'})
        }

        // ผ่านทุกด่านตรวจ ส่งข้อมูลกลับไปทดสอบ
    res.json({ message: "Welcome ครับ", user: payload_jwt });
    });
});



app.listen(3000, () => {
    console.log('server running at http://localhost:3000');
});
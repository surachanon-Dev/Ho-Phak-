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
app.post('/api/login' , (req,res) => {
    const {username,password} = req.body;
    const  sql = "SELECT *FROM users WHERE username = ?";
    con.query(sql,[username], (err, result) => {
        if(err){
            console.error(err);
            return res.status(500).send('DB error');
        }
        if(result.length != 1) {
            console.error('User not found');
            return res.status(401).send('User not found');
        }
        // verify the password
        const same = argon2.verifySync(result[0].password,password);
        if(!same) {
            console.error('Password not match')
            return res.status(401).send('Password not match');
        }
        // correct login
        // สร้าง JWT token
        const payload ={id:result[0].id, username:result[0].username ,role:result[0].role};
        const token = jwt.sign(payload, JWT_KEY, {expiresIn:"1d"});
        res.json({ message: 'Login success', token });
    });
});

app.listen(3000, () => {
    console.log('server running at http://localhost:3000');
});
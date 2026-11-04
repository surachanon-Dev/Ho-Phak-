const express = require('express');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const con = require('./db_config');

const app = express();
app.use(cors());
app.use(express.json());

//  FIXME : ไม่ควรเขียน hardcode move it to safer place
const JWT_KEY = 'huiodgfjs;oghdifsj@4$';

// hash the password
app.get('/api/password/:raw', (req, res) => {
    // เปลี่ยนวิธีเรียกใช้ฟังก์ชัน hashSync
    const hash = argon2.hashSync(req.params.raw);
    console.log(hash.length); // ผลลัพธ์จะได้ความยาวประมาณ 96-97 ตัวอักษร
    res.send(hash);
});

// login
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    const sql = "SELECT * FROM users WHERE username = ?";
    con.query(sql,[username], (err, result) => {
        if(err) {
            console.error(err);
            res.status(500).send('DB error');
        }
        if(result.length != 1) {
            console.error('User not found');
            res.status(401).send('User not found');
        }
        // verify the password
         const same = argon2.verifySync(result[0].password, password);
         if(!same) {
            console.error('Password not match');
            res.status(401).send('Password not match');
         }
        //  correct login
        // create JWT
        const payload = {id: result[0].id, username: result[0].username ,role: result[0].role};
        const token = jwt.sign(payload, JWT_KEY, {expiresIn:"1d"});
        res.send(token);
        

    });
});



// get all tasks of a user
app.get('/api/todo', (req, res) => {
    let payload_jwt = '';
    // get JWT from http header
    const header = req.headers['authorization'];
    // 1.cilent sends "token"

    // 2.cilent sends "Bearer Token"
    let token = header;
    if(header.startsWith('Bearer ')) {
        //  split => ['Bearer', token] create the array
        token = header.split(' ')[1];
    }

    // verify JWT (valid + not expired) + decrypt JWT for payload
    jwt.verify(token, JWT_KEY, (err, payload) => {
        if(err) {
            // JWT is invalide or expired
            return res.status(403).send('Unauthorized');
        }
        // console.log(payload);
        payload_jwt = payload;
    });

    // check user role
    const role = payload_jwt.role;
    if(role != 'user') {
        console.log('Wrong user role');
        return res.status(403).send('Wrong user role');
    }
    // Valid token + role
    const sql = "SELECT * FROM todo WHERE user_id=?";
    con.query(sql, [payload_jwt.id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        res.json(result);
    });
});

// update task
app.patch('/api/todo/:id', (req, res) => {
    const id = req.params.id;
    const title = req.body.title;
    const sql = "UPDATE todo SET title = ? WHERE id = ?";
    con.query(sql, [title, id], (err, result) => {
        if (err) {
            console.error(err);
            res.status(500).send('DB error');
        }
        if (result.affectedRows != 1) {
            console.error('Updated row is not 1');
            res.status(500).send('SQL error');
        }
        res.send('Updated');
    });
});

app.listen(3000, () => console.log('Server is running at port 3000'));
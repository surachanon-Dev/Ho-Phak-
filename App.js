const express = require('express');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const con = require('./Database-Config');

const app = express();
app.use(cors());
app.use(express.json());


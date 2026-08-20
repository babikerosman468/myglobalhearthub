require('dotenv').config();
const express = require('express');
const app = express();
const mysql = require('mysql2');
const path = require('path');

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME
});

db.connect(err => {
  if (err) throw err;
  console.log('Database connected!');
});

app.set('view engine', 'ejs');
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

app.get('/', (req, res) => {
  res.render('index');
});

app.get('/about', (req, res) => {
  res.render('about');
});

app.get('/pledge', (req, res) => {
  res.render('pledge');
});

app.post('/pledge', (req, res) => {
  const { name, email } = req.body;
  db.query('INSERT INTO members (name, email) VALUES (?, ?)', [name, email], err => {
    if (err) throw err;
    res.redirect('/success');
  });
});

app.get('/success', (req, res) => {
  res.render('success');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));




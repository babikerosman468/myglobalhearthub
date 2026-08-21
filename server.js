require('dotenv').config();

const express = require('express');
const mysql = require('mysql2');

const app = express();

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS || '',
  database: process.env.DB_NAME
});

db.connect(err => {
  if (err) {
    console.error('Database connection failed:', err.message);
    return;
  }

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

app.get('/practice', (req, res) => {
  res.render('practice');
});

app.post('/pledge', (req, res) => {
  const { name, email, country } = req.body;

  if (!name || !email || !country) {
    return res.status(400).send('Name, email and country are required.');
  }

  const sql = `
    INSERT INTO members
      (name, email, country, date_joined)
    VALUES (?, ?, ?, NOW())
  `;

  db.execute(sql, [name, email, country], err => {
    if (err) {
      console.error('Database insert failed:', err.message);
      return res.status(500).send('Unable to process your pledge.');
    }

    res.redirect('/thankyou');
  });
});

app.get('/thankyou', (req, res) => {
  res.render('thankyou');
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

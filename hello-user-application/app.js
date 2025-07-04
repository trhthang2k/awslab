const express = require('express');
const multer = require('multer');
const mysql = require('mysql2/promise');
const AWS = require('aws-sdk');
const fs = require('fs');
require('dotenv').config();

const app = express();
const upload = multer({ dest: 'uploads/' });
const port = 3000;

const s3 = new AWS.S3({ region: process.env.AWS_REGION });

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

app.use(express.urlencoded({ extended: true }));

app.get('/', async (req, res) => {
  const [users] = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
  let html = `<h1>Hello users!!</h1>
    <form action="/" method="POST" enctype="multipart/form-data">
      <input type="text" name="name" placeholder="Your name" required />
      <input type="file" name="image" accept="image/*" required />
      <button type="submit">Submit</button>
    </form><hr/>`;

  for (const u of users) {
    html += `<p>Hello ${u.name}!</p><img src="${u.image_url}" width="200"/><br><br>`;
  }

  res.send(html);
});

app.post('/', upload.single('image'), async (req, res) => {
  const file = req.file;
  const name = req.body.name;
  const key = `users/${Date.now()}_${file.originalname}`;

  const result = await s3.upload({
    Bucket: process.env.S3_BUCKET,
    Key: key,
    Body: fs.createReadStream(file.path),
    ContentType: file.mimetype,
    // ACL: 'public-read'
  }).promise();

  await pool.query('INSERT INTO users (name, image_url) VALUES (?, ?)', [name, result.Location]);
  fs.unlinkSync(file.path);
  res.redirect('/');
});

app.listen(port, () => console.log(`App listening at http://localhost:${port}`));


// const express = require('express');
// const multer = require('multer');
// const mysql = require('mysql2/promise');
// const AWS = require('aws-sdk');
// const fs = require('fs');
// require('dotenv').config();

// const app = express();
// const upload = multer({ dest: 'uploads/' });
// const port = 3000;

// const s3 = new AWS.S3({ region: process.env.AWS_REGION });

// const pool = mysql.createPool({
//   host: process.env.DB_HOST,
//   user: process.env.DB_USER,
//   password: process.env.DB_PASSWORD,
//   database: process.env.DB_NAME,
// });

// app.use(express.urlencoded({ extended: true }));

// app.get('/', async (req, res) => {
//   const [users] = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
//   let html = `<h1>Hello users!!</h1>
//     <form action="/" method="POST" enctype="multipart/form-data">
//       <input type="text" name="name" placeholder="Your name" required />
//       <input type="file" name="image" accept="image/*" required />
//       <button type="submit">Submit</button>
//     </form><hr/>`;

//   for (const u of users) {
//     html += `<p>Hello ${u.name}!</p><img src="${u.image_url}" width="200"/><br><br>`;
//   }

//   res.send(html);
// });

// app.post('/', upload.single('image'), async (req, res) => {
//   const file = req.file;
//   const name = req.body.name;
//   const key = `users/${Date.now()}_${file.originalname}`;

//   const result = await s3.upload({
//     Bucket: process.env.S3_BUCKET,
//     Key: key,
//     Body: fs.createReadStream(file.path),
//     ContentType: file.mimetype,
//     // ACL: 'public-read'
//   }).promise();

//   await pool.query('INSERT INTO users (name, image_url) VALUES (?, ?)', [name, result.Location]);
//   fs.unlinkSync(file.path);
//   res.redirect('/');
// });

// app.listen(port, () => console.log(`App listening at http://localhost:${port}`));


const express = require('express');
const multer = require('multer');
const mysql = require('mysql2/promise');
const AWS = require('aws-sdk');
const fs = require('fs');
require('dotenv').config();

const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');

const app = express();
const upload = multer({ dest: 'uploads/' });
const port = 3000;

// S3 client (dùng cho upload ảnh)
const s3 = new AWS.S3({ region: process.env.AWS_REGION });
// S3Client (dùng để tạo presigned URL)
const s3Client = new S3Client({ region: process.env.AWS_REGION });

// MySQL pool
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

app.use(express.urlencoded({ extended: true }));

// GET / — render form và danh sách user
app.get('/', async (req, res) => {
  const [users] = await pool.query('SELECT * FROM users ORDER BY created_at DESC');

  let html = `<h1>Hello users!!</h1>
    <form action="/" method="POST" enctype="multipart/form-data">
      <input type="text" name="name" placeholder="Your name" required />
      <input type="file" name="image" accept="image/*" required />
      <button type="submit">Submit</button>
    </form><hr/>`;

  for (const u of users) {
    let signedUrl = '#';

    // 📌 Sử dụng Presigned URL từ S3 key đã lưu trong DB
    if (u.image_url) {
      const command = new GetObjectCommand({
        Bucket: process.env.S3_BUCKET,
        Key: u.image_url,
      });

      signedUrl = await getSignedUrl(s3Client, command, { expiresIn: 300 }); // 5 phút
    }

    html += `<p>Hello ${u.name}!</p><img src="${signedUrl}" width="200"/><br><br>`;
  }

  res.send(html);
});

// POST / — upload ảnh và lưu thông tin
app.post('/', upload.single('image'), async (req, res) => {
  const file = req.file;
  const name = req.body.name;
  const key = `users/${Date.now()}_${file.originalname}`;

  // 📌 Upload ảnh lên S3 (không public)
  const result = await s3.upload({
    Bucket: process.env.S3_BUCKET,
    Key: key,
    Body: fs.createReadStream(file.path),
    ContentType: file.mimetype,
    // ACL: 'public-read' ❌ Không cần vì dùng presigned URL
  }).promise();

  // 📌 Lưu key (not URL) vào DB để sau này dùng presigned URL
  await pool.query('INSERT INTO users (name, image_url) VALUES (?, ?)', [name, key]);

  // Xoá file tạm local
  fs.unlinkSync(file.path);

  res.redirect('/');
});

app.listen(port, () => console.log(`App listening at http://localhost:${port}`));

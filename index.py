import os
# Let's write the index.html file content to check or save it locally if needed, 
# and prepare everything nicely for the user.
html_content = """<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sistem Login TOKO DONYGK</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f6f9; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .container { background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); width: 350px; }
        h2 { text-align: center; color: #333; margin-bottom: 20px; }
        .form-group { margin-bottom: 15px; }
        label { display: block; margin-bottom: 5px; font-weight: 600; color: #555; font-size: 14px; }
        input { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box; font-size: 14px; }
        button { width: 100%; padding: 10px; background-color: #4CAF50; color: white; border: none; border-radius: 6px; font-size: 16px; font-weight: bold; cursor: pointer; transition: background 0.3s; }
        button:hover { background-color: #45a049; }
        .switch { text-align: center; margin-top: 15px; font-size: 14px; color: #666; }
        .switch a { color: #007BFF; text-decoration: none; cursor: pointer; }
        .switch a:hover { text-decoration: underline; }
        .hidden { display: none; }
        .msg { margin-top: 15px; text-align: center; font-size: 14px; font-weight: bold; }
        .success { color: #28a745; }
        .error { color: #dc3545; }
    </style>
</head>
<body>

<div class="container">
    <div id="loginForm">
        <h2>Login Akun</h2>
        <div class="form-group">
            <label>Username</label>
            <input type="text" id="loginUsername" placeholder="Masukkan username">
        </div>
        <div class="form-group">
            <label>Password</label>
            <input type="password" id="loginPassword" placeholder="Masukkan password">
        </div>
        <button onclick="prosesLogin()">Masuk</button>
        <div class="switch">Belum punya akun? <a onclick="toggleForm('register')">Daftar di sini</a></div>
    </div>

    <div id="registerForm" class="hidden">
        <h2>Daftar Akun Baru</h2>
        <div class="form-group">
            <label>Username</label>
            <input type="text" id="regUsername" placeholder="Buat username unik">
        </div>
        <div class="form-group">
            <label>Email</label>
            <input type="email" id="regEmail" placeholder="email@domain.com">
        </div>
        <div class="form-group">
            <label>Password</label>
            <input type="password" id="regPassword" placeholder="Buat password aman">
        </div>
        <div class="form-group">
            <label>Keterangan</label>
            <input type="text" id="regKeterangan" value="Member Aktif">
        </div>
        <button onclick="prosesRegister()">Daftar Sekarang</button>
        <div class="switch">Sudah punya akun? <a onclick="toggleForm('login')">Login di sini</a></div>
    </div>

    <div id="message" class="msg"></div>
</div>

<script>
    const WEB_APP_URL = "https://script.google.com/macros/s/AKfycbxuwb_Gy5m1T08GPLQXOfziysKYG94hmj7lm4LReKCcAGAEdvlNi74Xz8slCYVlhfze/exec";

    function toggleForm(type) {
        document.getElementById('message').innerText = "";
        if(type === 'register') {
            document.getElementById('loginForm').classList.add('hidden');
            document.getElementById('registerForm').classList.remove('hidden');
        } else {
            document.getElementById('registerForm').classList.add('hidden');
            document.getElementById('loginForm').classList.remove('hidden');
        }
    }

    async function prosesRegister() {
        let username = document.getElementById('regUsername').value;
        let email = document.getElementById('regEmail').value;
        let password = document.getElementById('regPassword').value;
        let keterangan = document.getElementById('regKeterangan').value;
        let msg = document.getElementById('message');

        if(!username || !email || !password) {
            msg.className = "msg error";
            msg.innerText = "Semua kolom wajib diisi!";
            return;
        }

        msg.className = "msg";
        msg.innerText = "Memproses pendaftaran...";

        try {
            let response = await fetch(WEB_APP_URL, {
                method: "POST",
                body: JSON.stringify({ action: "register", username, email, password, keterangan })
            });
            let result = await response.json();
            
            msg.className = "msg " + (result.status === "success" ? "success" : "error");
            msg.innerText = result.message;
            if(result.status === "success") {
                setTimeout(() => toggleForm('login'), 2000);
            }
        } catch (error) {
            msg.className = "msg error";
            msg.innerText = "Terjadi kesalahan koneksi!";
        }
    }

    async function prosesLogin() {
        let username = document.getElementById('loginUsername').value;
        let password = document.getElementById('loginPassword').value;
        let msg = document.getElementById('message');

        if(!username || !password) {
            msg.className = "msg error";
            msg.innerText = "Username dan password harus diisi!";
            return;
        }

        msg.className = "msg";
        msg.innerText = "Memeriksa data...";

        try {
            let response = await fetch(WEB_APP_URL, {
                method: "POST",
                body: JSON.stringify({ action: "login", username, password })
            });
            let result = await response.json();
            
            msg.className = "msg " + (result.status === "success" ? "success" : "error");
            msg.innerText = result.message + (result.keterangan ? " (" + result.keterangan + ")" : "");
        } catch (error) {
            msg.className = "msg error";
            msg.innerText = "Terjadi kesalahan koneksi!";
        }
    }
</script>

</body>
</html>
"""

with open("index.html", "w", encoding="utf-8") as f:
    f.write(html_content)

print("File index.html siap!")
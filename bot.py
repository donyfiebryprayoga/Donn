import discord
from discord.ext import commands, tasks
import random
import string
import requests
import json
from datetime import datetime

intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix="!", intents=intents)

# ================= KREDENSIAL (GANTI DENGAN MILIKMU) =================
GITHUB_TOKEN = "MASUKKAN_TOKEN_DISINI"
GIST_ID = "MASUKKAN_GIST_ID_DISINI"
BOT_TOKEN = "MASUKKAN_BOT_TOKEN_DISINI"
ROLE_NAME = "Premium"  # Role otomatis yang didapat pembeli
SCRIPT_URL = "https://raw.githubusercontent.com/donyfiebryprayoga/Donn/refs/heads/main/loader/Donnhub.lua" # Link script Lua kamu
# ====================================================================

def generate_key_string():
    chars = string.ascii_uppercase + string.digits
    p1 = ''.join(random.choices(chars, k=4))
    p2 = ''.join(random.choices(chars, k=4))
    p3 = ''.join(random.choices(chars, k=4))
    p4 = ''.join(random.choices(chars, k=4))
    return f"{p1}-{p2}-{p3}-{p4}"

def save_to_github(key, days):
    url = f"https://api.github.com/gists/{GIST_ID}"
    headers = {"Authorization": f"Bearer {GITHUB_TOKEN}", "Accept": "vnd.github+json"}
    
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        gist_data = response.json()
        filename = list(gist_data['files'].keys())[0]
        
        try:
            data_json = json.loads(gist_data['files'][filename]['content'])
        except:
            data_json = {"licenses": {}}
            
        if "licenses" not in data_json:
            data_json["licenses"] = {}
            
        data_json["licenses"][key] = {
            "status": "unused",
            "hwid": None,
            "duration_days": days,
            "expires_at": None
        }
        
        payload = {"files": {filename: {"content": json.dumps(data_json, indent=4)}}}
        update_res = requests.patch(url, headers=headers, json=payload)
        return update_res.status_code == 200
    return False

# Tugas otomatis menghapus key expired setiap 24 jam
@tasks.loop(hours=24)
async def auto_cleanup_expired_keys():
    url = f"https://api.github.com/gists/{GIST_ID}"
    headers = {"Authorization": f"Bearer {GITHUB_TOKEN}", "Accept": "vnd.github+json"}
    
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        gist_data = response.json()
        filename = list(gist_data['files'].keys())[0]
        content = gist_data['files'][filename]['content']
        
        try:
            data_json = json.loads(content)
        except:
            return
            
        licenses = data_json.get("licenses", {})
        now = datetime.now()
        keys_to_delete = []
        
        for key, info in licenses.items():
            if info["status"] == "active" and info["expires_at"]:
                expiry_date = datetime.strptime(info["expires_at"], "%Y-%m-%d %H:%M:%S")
                if now > expiry_date:
                    keys_to_delete.append(key)
                    
        if keys_to_delete:
            for key in keys_to_delete:
                del licenses[key]
                print(f"[AUTO-DELETE] Key kedaluwarsa terhapus: {key}")
                
            payload = {"files": {filename: {"content": json.dumps(data_json, indent=4)}}}
            requests.patch(url, headers=headers, json=payload)

@bot.event
async def on_ready():
    print(f"Bot {bot.user} online dan siap mengelola TOKO DONYGK!")
    auto_cleanup_expired_keys.start()

# 1. Tombol untuk Panel Pengambilan Key di Tiket
class KeyView(discord.ui.View):
    def __init__(self, days):
        super().__init__(timeout=None)
        self.days = days

    @discord.ui.button(label="🔑 Ambil License Key", style=discord.ButtonStyle.green)
    async def claim_key(self, interaction: discord.Interaction, button: discord.ui.Button):
        key = generate_key_string()
        
        if not save_to_github(key, self.days):
            await interaction.response.send_message("❌ Gagal menyimpan key ke database GitHub!", ephemeral=True)
            return

        # Auto-Role
        role_given = False
        member = interaction.user
        guild = interaction.guild
        
        if guild:
            role = discord.utils.get(guild.roles, name=ROLE_NAME)
            if role:
                try:
                    await member.add_roles(role)
                    role_given = True
                except Exception as e:
                    print(f"Gagal memberikan role: {e}")

        embed = discord.Embed(
            title="TOKO DONYGK - License Key",
            description=f"Berhasil di-generate untuk **{member.mention}**!",
            color=discord.Color.green()
        )
        embed.add_field(name="License Key:", value=f"`{key}`", inline=False)
        embed.add_field(name="Slots per License", value="1 device (HWID Locked)", inline=False)
        embed.add_field(name="Valid For", value=f"{self.days} Days", inline=False)
        if role_given:
            embed.add_field(name="Auto-Role", value=f"Berhasil mendapatkan role **{ROLE_NAME}**!", inline=False)
        embed.set_footer(text="TOKO DONYGK Control Panel")

        button.disabled = True
        button.label = "Key Sudah Diambil"
        await interaction.response.edit_message(view=self)
        
        await interaction.channel.send(embed=embed)
        await interaction.channel.send(key)

# 2. Tombol untuk Control Panel Utama (Redeem, Script, Status)
class ControlPanelView(discord.ui.View):
    def __init__(self):
        super().__init__(timeout=None)

    @discord.ui.button(label="Redeem Key", style=discord.ButtonStyle.green, custom_id="btn_redeem")
    async def redeem_key(self, interaction: discord.Interaction, button: discord.ui.Button):
        await interaction.response.send_message("🔑 Masukkan key kamu di script game untuk melakukan aktivasi HWID pertama kali.", ephemeral=True)

    @discord.ui.button(label="Get Script", style=discord.ButtonStyle.primary, custom_id="btn_script")
    async def get_script(self, interaction: discord.Interaction, button: discord.ui.Button):
        await interaction.response.send_message(f"📜 Script **TOKO DONYGK**:\n`loadstring(game:HttpGet('{SCRIPT_URL}'))()`", ephemeral=True)

    @discord.ui.button(label="Check Status", style=discord.ButtonStyle.secondary, custom_id="btn_status")
    async def check_status(self, interaction: discord.Interaction, button: discord.ui.Button):
        await interaction.response.send_message("📊 Status lisensi aktif dan terikat ke perangkat Anda.", ephemeral=True)

# Perintah untuk memunculkan Panel Tiket: !panel 30D atau !panel 7D
@bot.command()
async def panel(ctx, durasi: str = "30D"):
    durasi = durasi.upper()
    if durasi == "30D":
        days = 30
    elif durasi == "7D":
        days = 7
    else:
        await ctx.send("❌ Format salah! Gunakan **!panel 30D** atau **!panel 7D**")
        return
        
    embed = discord.Embed(
        title="🛒 TOKO DONYGK - Panel Pengambilan Lisensi",
        description=f"Klik tombol di bawah ini untuk mengambil key berdurasi **{days} Hari** dan otomatis mendapatkan role pembeli.",
        color=discord.Color.blue()
    )
    view = KeyView(days)
    await ctx.send(embed=embed, view=view)

# Perintah untuk memunculkan Control Panel Utama (Gaya Banner)
@bot.command()
async def controlpanel(ctx):
    embed = discord.Embed(
        title="TOKO DONYGK Control Panel",
        description="Selamat datang di panel kontrol resmi **TOKO DONYGK**.\n\nGunakan tombol di bawah untuk akses script atau informasi lisensi.",
        color=discord.Color.from_rgb(40, 40, 40)
    )
    embed.set_image(url="https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=1000&auto=format&fit=crop")
    embed.set_footer(text="TOKO DONYGK • Secure License System")
    
    view = ControlPanelView()
    await ctx.send(embed=embed, view=view)

bot.run(BOT_TOKEN)

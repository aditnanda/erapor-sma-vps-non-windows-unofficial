# Docker e-Rapor SMA 2025 Unofficial

**Versi package: 2025.1**

> **Unofficial Docker deployment package** untuk menjalankan aplikasi e-Rapor SMA 2025 di VPS Ubuntu menggunakan Docker.

Repository/folder ini bukan rilis resmi dari pengembang e-Rapor SMA. Gunakan dengan tanggung jawab masing-masing. Aplikasi e-Rapor SMA tetap milik pengembang/resmi terkait; paket ini hanya membantu proses deployment ke server Linux/VPS.

## Fitur

- Menjalankan aplikasi PHP/Apache di container Docker.
- Menjalankan PostgreSQL 14 di container Docker.
- Auto-import database dari `backup-erapor.dump` saat install pertama.
- Port web default mengikuti paket aplikasi: `8239`.
- Siap dipasang di belakang reverse proxy aaPanel/Nginx.

## Struktur Folder

```text
e-rapor-docker/
├── backup-erapor.dump
├── dbapp/
├── docker/
│   ├── apache/
│   │   └── 000-default.conf
│   ├── db/
│   │   └── init/
│   │       └── 01-restore-erapor.sh
│   └── php/
│       └── erapor.ini
├── docker-compose.yml
├── Dockerfile
├── README.md
└── wwwroot/
```

## Prasyarat VPS

- Ubuntu server.
- Akses SSH/root atau user sudo.
- Minimal RAM disarankan 2 GB.
- Docker dan Docker Compose standalone.

## 1. Upload Folder ke VPS

Contoh upload dari komputer lokal:

```bash
scp -r e-rapor-docker root@IP_VPS:/www/wwwroot/erapor-sma.alfalahsby.sch.id/e-rapor-docker
```

Masuk ke VPS:

```bash
ssh root@IP_VPS
cd /www/wwwroot/erapor-sma.alfalahsby.sch.id/e-rapor-docker
```

Silakan sesuaikan path deploy dengan domain/server masing-masing.

## 2. Install Docker dan Docker Compose

```bash
apt update
apt install -y docker.io curl
systemctl enable --now docker
```

Install Docker Compose standalone:

```bash
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

## 3. Pastikan File Dump Tersedia

File dump database harus ada di root folder deploy:

```bash
ls -lh backup-erapor.dump
```

Jika belum ada, salin/upload file dump PostgreSQL ke lokasi ini dengan nama:

```text
backup-erapor.dump
```

## 4. Jalankan Aplikasi

Pastikan folder `dbapp` kosong saat install pertama agar auto-import berjalan.

```bash
docker-compose up -d --build
```

Lihat proses import database:

```bash
docker-compose logs -f db
```

Jika sukses, cek container:

```bash
docker-compose ps
```

Aplikasi dapat diakses melalui:

```text
http://IP_VPS:8239
```

## 5. Cek Database

Cek database dan tabel:

```bash
docker exec erapor-sma-db psql -U postgres -p 54945 -d db_neweraporsma -c "\dt"
```

Database default:

```text
Nama database : db_neweraporsma
User          : postgres
Port internal : 54945
```

## 6. Reverse Proxy Nginx / aaPanel

Jika memakai domain dan HTTPS, arahkan reverse proxy ke:

```text
http://127.0.0.1:8239
```

Contoh blok Nginx di dalam `server { ... }`:

```nginx
location ^~ / {
    proxy_pass http://127.0.0.1:8239;
    proxy_http_version 1.1;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;

    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 300s;

    proxy_buffering off;
    proxy_redirect off;
}
```

Jika CSS/JS pecah di HTTPS karena asset masih memakai `http://`, tambahkan base URL HTTPS ke `wwwroot/.env`:

```bash
cat >> wwwroot/.env <<'ENV_EOF'

app.baseURL = 'https://domain-anda.sch.id/'
app.forceGlobalSecureRequests = true
ENV_EOF

docker-compose restart web
```

Ganti `domain-anda.sch.id` dengan domain yang digunakan.

Jika tetap muncul mixed content, tambahkan fallback berikut di blok reverse proxy Nginx:

```nginx
proxy_set_header Accept-Encoding "";
sub_filter_once off;
sub_filter 'http://domain-anda.sch.id' 'https://domain-anda.sch.id';
```

Lalu reload Nginx:

```bash
nginx -t
systemctl reload nginx
```

## 7. Restore Ulang dari Dump

Gunakan langkah ini jika ingin reset database dan import ulang dari `backup-erapor.dump`.

> Perhatian: langkah ini menghapus isi database container saat ini.

```bash
docker-compose down
rm -rf dbapp/* dbapp/.[!.]* dbapp/..?* 2>/dev/null || true
docker-compose up -d db
docker-compose logs -f db
```

Setelah restore selesai:

```bash
docker-compose up -d
docker-compose ps
```

## 8. Akses Database via DBeaver

Secara default port PostgreSQL tidak dibuka ke luar VPS. Untuk akses remote, buka mapping port di `docker-compose.yml`:

```yaml
ports:
  - "8239:80"
  - "54945:54945"
```

Restart container:

```bash
docker-compose down
docker-compose up -d
```

Buka firewall VPS/aaPanel untuk port `54945`.

Pengaturan DBeaver:

```text
Driver   : PostgreSQL
Host     : IP_VPS atau domain
Port     : 54945
Database : db_neweraporsma
Username : postgres
Password : kosong
```

> Catatan keamanan: jangan membuka port database ke publik tanpa pembatasan IP/firewall. Lebih aman gunakan SSH Tunnel di DBeaver.

## 9. Perintah Operasional

Cek status:

```bash
docker-compose ps
```

Lihat log aplikasi:

```bash
docker-compose logs -f web
```

Lihat log database:

```bash
docker-compose logs -f db
```

Restart:

```bash
docker-compose restart
```

Stop:

```bash
docker-compose down
```

Start ulang:

```bash
docker-compose up -d
```

## 10. Backup Manual

Backup folder deployment saat container berhenti:

```bash
docker-compose down
cd ..
tar -czf erapor-docker-backup-$(date +%F).tar.gz e-rapor-docker
docker-compose -f e-rapor-docker/docker-compose.yml up -d
```

Atau dump database dari container:

```bash
docker exec erapor-sma-db pg_dump -U postgres -p 54945 -F c -b -v -f /tmp/backup-erapor.dump db_neweraporsma
docker cp erapor-sma-db:/tmp/backup-erapor.dump ./backup-erapor-$(date +%F).dump
```

## Troubleshooting

### Docker compose error `unknown shorthand flag: 'd' in -d`

Gunakan command standalone:

```bash
docker-compose up -d --build
```

Bukan:

```bash
docker compose up -d --build
```

Atau install plugin Docker Compose sesuai versi Docker server.

### Database `unhealthy` karena locale Windows

Jangan mount data PostgreSQL Windows langsung ke Linux. Gunakan dump `backup-erapor.dump`, lalu biarkan container membuat database baru dan restore otomatis.

### Composer membutuhkan PHP `>= 8.2`

Pastikan `Dockerfile` memakai PHP 8.2:

```dockerfile
FROM php:8.2-apache-bullseye
```

### Halaman tampil tetapi CSS/JS pecah

Pastikan reverse proxy memakai `location ^~ /` dan asset tidak ditangani oleh blok static cache Nginx/aaPanel. Untuk HTTPS, pastikan `app.baseURL` memakai `https://`.

## Disclaimer

Project ini **unofficial** dan tidak berafiliasi dengan pengembang resmi e-Rapor SMA, Direktorat SMA, maupun instansi terkait. Gunakan hanya jika Anda memiliki hak untuk menjalankan aplikasi dan mengelola data sekolah. Selalu lakukan backup berkala dan jaga kerahasiaan data peserta didik.

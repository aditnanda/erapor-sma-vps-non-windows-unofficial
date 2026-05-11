# Deploy e-Rapor SMA ke VPS Ubuntu dengan Docker

Folder ini sudah berisi aplikasi (`wwwroot`) dan dump database (`backup-erapor.dump`). Saat pertama kali `docker-compose up`, PostgreSQL akan membuat database `db_neweraporsma` dan otomatis me-restore dump tersebut ke folder data `dbapp`.

## 1. Upload ke VPS

```bash
scp -r e-rapor-docker user@IP-VPS:/opt/e-rapor-sma
```

Masuk ke VPS:

```bash
ssh user@IP-VPS
cd /opt/e-rapor-sma
```

## 2. Install Docker & Docker Compose

```bash
sudo apt update
sudo apt install -y docker.io curl
sudo systemctl enable --now docker
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

## 3. Jalankan aplikasi

Pastikan `dbapp` kosong saat install pertama. Jika ingin restore ulang dari dump, stop container lalu hapus isi `dbapp` dulu.

```bash
sudo docker-compose up -d --build
```

Akses aplikasi:

```text
http://IP-VPS:8239
```

## 4. Cek status dan log

```bash
sudo docker-compose ps
sudo docker-compose logs -f db
sudo docker-compose logs -f web
```

Cek tabel database:

```bash
sudo docker exec erapor-sma-db psql -U postgres -p 54945 -d db_neweraporsma -c "\dt"
```

## 5. Restore ulang dari dump

Gunakan hanya jika ingin reset database sesuai `backup-erapor.dump`.

```bash
sudo docker-compose down
sudo rm -rf dbapp/* dbapp/.[!.]* dbapp/..?* 2>/dev/null || true
sudo docker-compose up -d db
sudo docker-compose logs -f db
sudo docker-compose up -d
```

## Catatan

- Port web: `8239`.
- Port PostgreSQL internal: `54945`.
- Database aplikasi: `db_neweraporsma`.
- Untuk akses DBeaver dari luar VPS, buka mapping `54945:54945` di `docker-compose.yml` dan firewall.
- Jangan hapus `backup-erapor.dump`; file ini dipakai untuk auto-import saat database baru dibuat.

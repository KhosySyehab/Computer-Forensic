# Computer Forensic - Kelompok 5 (Ganjil)

## Anggota Kelompok 5

| No. | Nama Mahasiswa  |
| :---: | :--- |
| 1 | Aras Rizky Ananta |
| 2 | Muhammad Khosyi Syehab |
| 3 | Clarissa Aydin Rahmazea |
| 4 | I Dewa Made Satya Raditya |

---

## Latar Belakang

Tugas ini merupakan bagian dari praktikum Forensik Digital. Kelompok 5 bertugas membuat sebuah **disk image berformat Windows (NTFS)** yang di dalamnya terdapat artefak forensik berupa **file tersembunyi** menggunakan NTFS hidden attribute.

---

## Skenario Forensik

Seorang administrator sistem bernama **`khosy`** ditemukan melakukan akses jarak jauh ke server lab di luar jam operasional. Ia menyembunyikan log sesinya menggunakan NTFS hidden attribute agar tidak terdeteksi oleh audit biasa.

Tugas investigator adalah menemukan file log tersembunyi tersebut beserta bukti identitas dan waktu kejadian.

---

## Metodologi Pembuatan Image

### Tools yang Digunakan

| Tool | Versi | Fungsi |
|------|-------|--------|
| `dd` | GNU coreutils | Membuat raw disk image |
| `mkfs.ntfs` (ntfs-3g) | 2022.10.3 | Format filesystem NTFS |
| `ntfs-3g` | 2022.10.3 | Mount image NTFS di Linux |
| `setfattr` (attr) | 2.5.2 | Set NTFS extended attribute (hidden) |
| `qemu-img` | 8.2.2 | Konversi RAW → VHD |

### Langkah Pembuatan

```
1. Buat raw image kosong 256MB
   dd if=/dev/zero of=win_disk_ganjil5_okt2026.raw bs=1M count=256

2. Format sebagai NTFS (Volume Label: KLP5_SYSLOG_VOL)
   mkfs.ntfs -F -L "KLP5_SYSLOG_VOL" win_disk_ganjil5_okt2026.raw

3. Mount image & tulis file artefak
   mount -t ntfs-3g -o loop ...

4. Set NTFS hidden attribute pada file artefak
   setfattr -n system.ntfs_attrib_be -v 0x00000022 session_log_admin_remote.txt
   (0x22 = 0x02 HIDDEN | 0x20 ARCHIVE)

5. Unmount, konversi ke VHD, buat chain of custody, ZIP
```

---

## Struktur File di Dalam Image

| Nama File | Status | Keterangan |
|-----------|--------|------------|
| `inventaris_perangkat_lab.txt` | Visible | File decoy — daftar inventaris perangkat lab |
| `jadwal_backup_server.txt` | Visible | File decoy — jadwal backup server rutin |
| `session_log_admin_remote.txt` | **Hidden** | **Artefak utama** — log sesi remote tidak sah |

### Isi File Tersembunyi (`session_log_admin_remote.txt`)

File ini berisi log sesi SSH administrator yang dilakukan secara tidak resmi, mencakup:
- Identitas pengguna: `*****`
- IP sumber: `********`
- Waktu akses: `********`
- Serangkaian perintah mencurigakan (`cat /etc/shadow`, eksfiltrasi data, penghapusan jejak)
- **Keyword:** `REMOTE_AKSES_RAHASIA_KLP5`

---

## Output & Deliverable

### Isi ZIP (`FORDIG_Windows_Evidence_Klp5.zip`)

```
FORDIG_Windows_Evidence_Klp5.zip
├── win_disk_ganjil5_okt2026.raw   ← RAW disk image (256 MB)
├── win_disk_ganjil5_okt2026.vhd   ← Virtual Hard Disk (VHD format)
└── chain_of_custody_klp5.txt      ← Chain of custody + integrity hashes
```

### Integritas File

| File | MD5 | SHA256 (prefix) |
|------|-----|--------|
| `win_disk_ganjil5_okt2026.raw` | `045c4d4d16f496aecd6f626d40c0286d` | `2385867a...842eec3` |
| `win_disk_ganjil5_okt2026.vhd` | `70f163dceb018238a8d1b6f6b93258b7` | `8be2098c...5d2f373` |

> Detail hash lengkap ada di [`chain_of_custody_klp5.txt`](./chain_of_custody_klp5.txt)

---

## Link Evidence

| Platform | Evidence |
|----------|------|
| Github | FORDIG_Windows_Evidence_Klp5.zip |

---

## Cross-Check Kesesuaian Soal

| Syarat Soal | Status |
|---|---|
| Kelompok ganjil membuat image OS Windows | (Done )NTFS filesystem (Windows native) |
| Image dapat diakses via Google Drive/GitHub | (Done) ZIP siap upload |
| Di dalam OS ada file tersembunyi + keyword | (Done) `session_log_admin_remote.txt` + `REMOTE_AKSES_RAHASIA_KLP5` |
| Investigator dapat temukan file tersembunyi | (Done) Detectable via Autopsy / FTK Imager |
| Investigator dapat temukan username pelaku | (Done) `*****` (di dalam isi file + NTFS metadata) |
| Investigator dapat temukan waktu kejadian | (Done) Timestamp `********` (file content + NTFS MFT) |

---

## Cara Analisis (Petunjuk untuk Investigator)

1. Download dan ekstrak ZIP
2. Buka `win_disk_ganjil5_okt2026.raw` atau `.vhd` menggunakan:
   - **Autopsy** → File > New Case > Add Data Source > Disk Image
   - **FTK Imager** → File > Add Evidence Item > Image File
3. Di file browser, aktifkan opsi **"Show All Files"** (termasuk hidden)
4. Cari file dengan NTFS attribute `0x22` (hidden + archive)
5. Buka `session_log_admin_remote.txt` untuk menemukan keyword dan identitas pelaku
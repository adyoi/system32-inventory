# Inventaris File C:\Windows\System32 - EXE dan DLL

> **Halaman interaktif:** https://adyoi.github.io/system32-inventory/ - versi lengkap dengan pencarian, filter, dan sortir. Buka juga secara lokal lewat `docs\index.html` tanpa server.
>
> Repo dokumentasi pribadi, tidak berafiliasi dengan atau didukung Microsoft.
>
> Lisensi: [MIT](LICENSE). Nama produk, file, dan merek milik Microsoft; data nama, ukuran, dan versi file adalah fakta yang dihimpun dari instalasi Windows lokal.

Inventaris lengkap file .exe dan .dll di C:\Windows\System32, disortir per kategori dan per nama, dengan penjelasan singkat fungsi tiap file.

- **Sistem ini:** Microsoft Windows 11 Pro, versi 10.0.28000 (build 28000)
- **Waktu generate:** 2026-10-04 04:44
- **Jumlah file:** 4267 total, yaitu 665 EXE dan 3602 DLL
- **Total ukuran:** 2303.2 MB
- **Sumber penjelasan:** 762 file punya penjelasan kurasi manual, 3246 file memakai FileDescription dari metadata versi, 259 file tidak punya metadata sehingga ditandai eksplisit.

## Daftar isi

1. [Cara memakai dokumen ini](#1-cara-memakai-dokumen-ini)
2. [Apa itu System32](#2-apa-itu-system32)
3. [Kategori file](#3-kategori-file)
4. [File inti](#4-file-inti)
5. [Catatan praktis](#5-catatan-praktis)
6. [Cara regenerate](#appendix-cara-regenerate)

---

## 1. Cara memakai dokumen ini

**Inventaris lengkapnya ada di [docs/index.html](docs/index.html)** atau online di **https://adyoi.github.io/system32-inventory/** - satu file HTML yang bisa dibuka langsung di browser, tanpa server dan tanpa koneksi internet. README ini hanya ringkasan; daftar 4.267 file per kategori tidak diulang di sini.

Yang bisa dilakukan di halaman HTML:

- **Cari** nama file atau kata kunci di penjelasannya, misalnya `ws2_32`, `BitLocker`, atau `font`.
- **Saring** berdasarkan tipe (EXE/DLL), kategori, atau tombol **Kurasi saja** untuk melihat file yang penjelasannya ditulis manual.
- **Urutkan** dengan klik header kolom File, Ukuran, Versi, atau Kategori, atau lewat dropdown pengurutan.
- **Unduh CSV** hasil filter yang sedang aktif.
- **Ganti tema** terang/gelap; di layar sempit tabel berubah menjadi kartu.
- **Baca penjelasan file inti** di blok "Penjelasan file inti (deep dive)" di bagian atas halaman.

Kolom yang dipakai di halaman HTML:

| Kolom | Arti |
|---|---|
| File | Nama file apa adanya di System32, termasuk kapitalisasinya |
| Ukuran | Ukuran file di disk dalam KB atau MB |
| Versi | Ambil dari sumber daya versi file (FileVersion), bukan versi produk |
| Kategori | Kelompok fungsi file; urutan kategori mengikuti urutan logis di bagian 3 |
| Penjelasan | Kurasi manual, atau FileDescription dari metadata file, atau catatan bahwa tidak terdokumentasi |

## 2. Apa itu System32

C:\Windows\System32 adalah direktori inti sistem operasi Windows. Nama "System32" berasal dari pustaka untuk sistem 32-bit, dan itu benar untuk Windows 95/98 serta edisi 32-bit. Pada Windows 64-bit, folder ini berisi pustaka 64-bit, sedangkan pustaka 32-bit pindah ke C:\Windows\SysWOW64 (WOW64 berarti Windows on Windows 64-bit, bukan kebalikannya).

Isi folder ini pada dasarnya empat kelompok:

- **Executable sistem dan utilitas** - proses boot seperti smss.exe, csrss.exe, dan winlogon.exe; host service svchost.exe; serta utilitas command prompt seperti ipconfig.exe dan robocopy.exe. Perhatikan bahwa pada Windows 11 build terbaru beberapa executable justru berada di C:\Windows (contohnya explorer.exe), bukan di System32.
- **API DLL** - implementasi Win32 dan WinNT yang dipakai semua aplikasi: kernel32.dll, user32.dll, advapi32.dll, gdi32.dll.
- **Komponen produk Microsoft** - Edge, Xbox Game Bar, Maps, App Installer, serta API modern WinRT dan .NET yang masih di-host di sini.
- **Driver dan pustaka vendor** - Intel Graphics (igd*.dll), OpenSSL (libcrypto*.dll), atau plugin keamanan pihak ketiga yang ikut terpasang di System32.

Selain .exe dan .dll, folder ini juga berisi driver .sys, pustaka 32-bit warisan, Control Panel applet .cpl, font metric, dan command script. Dokumen ini sengaja hanya mencakup .exe dan .dll.

> **Penting:** folder ini dilindungi Windows Resource Protection. File di dalamnya tidak boleh dipindah, diubah nama, dihapus, atau "dibersihkan" manual. Perubahan yang tidak disengaja dapat membuat Windows gagal boot atau service tidak berjalan.

## 3. Kategori file

Jumlah file per kategori (EXE dan DLL digabung):

| # | Kategori | Jumlah |
|---:|---|---:|
| 1 | Inti Kernel, System dan Runtime C/C++ | 50 |
| 2 | Proses, Layanan dan Service Host | 108 |
| 3 | Keamanan, Identitas dan Kripto | 180 |
| 4 | Jaringan, Internet dan Remote Access | 237 |
| 5 | Shell, Explorer dan Antarmuka Pengguna | 89 |
| 6 | Grafis, Direct3D dan DirectWrite | 77 |
| 7 | Multimedia, Audio dan Video | 103 |
| 8 | Input, Keyboard, Mouse dan Gamepad | 18 |
| 9 | Penyimpanan, File System dan Volume | 74 |
| 10 | Perangkat Keras, Driver dan PnP | 101 |
| 11 | Data, Database dan Serialisasi | 43 |
| 12 | Runtime .NET, WinRT dan Library Bahasa | 324 |
| 13 | Bahasa, Locale, Font dan Teks | 243 |
| 14 | Pengembangan, Debug dan Diagnostik | 74 |
| 15 | Cetak, Scan dan Imaging | 40 |
| 16 | Virtualisasi, Kontainer dan VM | 69 |
| 17 | Kebijakan, CSP, dan MDM | 93 |
| 18 | Settings, Repository dan Personalisasi | 109 |
| 19 | Produk dan Layanan Microsoft | 179 |
| 20 | Pihak Ketiga dan Driver Vendor | 4 |
| 21 | Lain-lain / Tidak terkategori | 2052 |

- **Inti Kernel, System dan Runtime C/C++** - Lapisan paling dasar: kernel NT, Win32 core, WOW64, dan runtime C/C++ (UCRT serta Visual C++ Runtime). Hampir semua proses Windows memuat beberapa file dari kategori ini, sehingga file di sini praktis tidak boleh hilang atau diganti.
- **Proses, Layanan dan Service Host** - Executable dan pustaka yang menjalankan siklus hidup proses serta service: start, boot, logon, penjadwalan, dan pelaporan error.
- **Keamanan, Identitas dan Kripto** - Autentikasi, otorisasi, sertifikat, penyimpanan kunci, TPM, biometrik, Windows Defender, SmartScreen, dan firmware keamanan.
- **Jaringan, Internet dan Remote Access** - Stack Winsock, HTTP, DNS, Active Directory via LDAP, Wi-Fi, VPN, broadband seluler, Bluetooth, dan protokol jaringan lama.
- **Shell, Explorer dan Antarmuka Pengguna** - Semua yang membentuk tampilan Windows: jendela, kontrol, dialog, ikon, context menu, shell Explorer, dan aksesibilitas.
- **Grafis, Direct3D dan DirectWrite** - Rendering 3D dan 2D: Direct3D 9 sampai 12, DXGI, DirectWrite, DirectComposition, OpenGL, Vulkan, dan pustaka driver GPU pihak ketiga.
- **Multimedia, Audio dan Video** - Media Foundation, DirectShow, AVI, codec audio lawas, enkode video, dan scheduler real-time untuk multimedia.
- **Input, Keyboard, Mouse dan Gamepad** - Keyboard, mouse, HID, DirectInput, dan XInput untuk kontroler game.
- **Penyimpanan, File System dan Volume** - Volume manager, filter file system, BitLocker, Offline Files, kompresi CAB, dan lapisan internal FAT, NTFS, serta ReFS.
- **Perangkat Keras, Driver dan PnP** - Plug and Play, Device Manager, BIOS/ACPI, TPM, sensor, dan firmware mikrokode CPU.
- **Data, Database dan Serialisasi** - Windows Installer, basis data (ODBC, OLE DB, SQLite, ESE), XML, Structured Query Language, dan property system.
- **Runtime .NET, WinRT dan Library Bahasa** - Hosting .NET Framework, proyeksi WinRT, dan pustaka C++ seperti ATL serta MFC.
- **Bahasa, Locale, Font dan Teks** - Data NLS, normalisasi Unicode, font, shaping teks, keyboard layout, dan MUI.
- **Pengembangan, Debug dan Diagnostik** - Simbol dan dump untuk debugging, performance counter, WMI, Error Reporting, serta alat ukur performa.
- **Cetak, Scan dan Imaging** - Print Spooler, driver filter, dialog printer, XPS/IPP, serta WIA untuk scanner dan kamera.
- **Virtualisasi, Kontainer dan VM** - Hyper-V, Host Compute Service, VMBus, Windows Sandbox, Container, dan komponen virtual machine.
- **Kebijakan, CSP, dan MDM** - Configuration Service Provider (CSP), Group Policy, kepatuhan, dan endpoint management yang dikelola tim TI. File di sini sering ditambahkan atau diubah lewat baseline kebijakan, bukan lewat aplikasi biasa.
- **Settings, Repository dan Personalisasi** - Mesin di balik Windows Settings: penyimpan state, handler tiap halaman pengaturan, wallpaper, lockscreen, tile Start, dan data pengguna yang disimpan per aplikasi.
- **Produk dan Layanan Microsoft** - Edge, Xbox Game Bar, Maps, People, App Installer, telemetry, dan komponen produk yang di-host di System32.
- **Pihak Ketiga dan Driver Vendor** - Berkas driver dan pustaka non-Microsoft yang ikut terpasang di System32, misalnya Intel Graphics, OpenSSL, atau plugin keamanan pihak ketiga.
- **Lain-lain / Tidak terkategori** - Berkas yang tidak cocok dengan pola kategori lain, umumnya komponen internal Microsoft tanpa dokumentasi publik.

## 4. File inti

Kalau bermasalah dengan satu file, biasanya ini daftar file yang paling sering ditanya. Penjelasan lengkapnya ada di blok deep dive di [halaman interaktif](https://adyoi.github.io/system32-inventory/).

| File | Fungsi |
|---|---|
| `ntdll.dll` | Lantai bawah Windows |
| `kernel32.dll` | Gerbang Win32 |
| `KernelBase.dll` | Implementasi Win32 yang tidak diekspor |
| `hal.dll` | Hardware Abstraction Layer |
| `win32u.dll` | Jembatan USER dan GDI mode user |
| `advapi32.dll` | Registry, keamanan, service, dan akun |
| `user32.dll` | Jendela, pesan, dan input |
| `ole32.dll dan oleaut32.dll` | COM, OLE, dan Automation |
| `comctl32.dll` | Kontrol common Windows |
| `ws2_32.dll` | Winsock 2 |
| `winhttp.dll` | HTTP untuk service dan aplikasi native |
| `crypt32.dll` | Sertifikat, PKI, dan Certificate Store |
| `bcrypt.dll` | Kriptografi modern (CNG) |
| `shlwapi.dll` | Utilitas shell yang ringan |
| `msvcrt.dll dan ucrtbase.dll` | Dua generasi C runtime |

## 5. Catatan praktis

- **Jangan menebak file yang "bisa dihapus".** Ukuran System32 yang besar itu normal. Kalau HDD atau SSD penuh, jalur aman adalah Storage Sense, `Dism.exe /Online /Cleanup-Image /StartComponentCleanup`, atau mematikan hibernasi dengan `powercfg /h off`.
- **Duplikasi itu normal.** Banyak file juga ada di C:\Windows\WinSxS dan C:\Windows\SysWOW64 karena Windows menyimpan beberapa versi tiap komponen untuk rollback pembaruan.
- **Error Bad Image atau ERROR_MOD_NOT_FOUND** sering berarti versi file tidak cocok antar komponen, bukan file hilang. Urutan perbaikan yang wajar: `Dism.exe /Online /Cleanup-Image /RestoreHealth` lalu `sfc.exe /scannow`.
- **Blue screen dengan kode STOP 0x0000007E atau 0x000000EF** biasanya menunjuk ke file driver tertentu yang disebut di akhir layar; kolom pada tabel ini membantu mencocokkan nama file tersebut.
- **Perspektif keamanan** - beberapa DLL di sini bisa disalahgunakan sebagai living-off-the-land binary, misalnya regsvr32.exe, rundll32.exe, mshta.exe, dan msiexec.exe. Sysinternals Sigcheck dan Sysmon membantu membedakan pemakaian yang wajar.
- **Dokumen ini read-only** - isinya deskripsi file, bukan daftar file yang boleh dihapus.
- **Tidak ada stub API set** (api-ms-win-* atau ext-ms-win-*) di System32 pada sistem ini. Pada Windows versi lama file seperti itu sangat banyak; pada build terbaru Windows menyimpannya di lokasi lain sehingga System32 jauh lebih bersih.
- **259 file tanpa metadata versi** tidak punya FileDescription, jadi penjelasannya tidak bisa diambil otomatis. Di halaman HTML, cari dengan filter **Kurasi saja** untuk melihat mana yang sudah dijelaskan manual.

---

## Appendix: cara regenerate

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\gen_docs.ps1
```

`tools\gen_readme.ps1` mengumpulkan inventaris dari metadata versi file lalu menulis README.md dan `tools\sys32_inventory.csv`. `tools\gen_docs.ps1` memakai skrip itu dan menulis halaman interaktif ke `docs\index.html`, yang menjadi sumber GitHub Pages repo ini. Data inventaris diambil langsung dari sumber daya versi file, tanpa alat pihak ketiga:

```powershell
Get-ChildItem C:\Windows\System32 -File |
  Where-Object { $_.Extension -in ".dll", ".exe" } |
  ForEach-Object {
    [PSCustomObject]@{
      Name        = $_.Name
      SizeKB      = [math]::Round($_.Length/1KB)
      FileVersion = $_.VersionInfo.FileVersion
      Description = $_.VersionInfo.FileDescription
    }
  }
```

## Lisensi

Kode generator dan dokumentasi di repo ini memakai [MIT](LICENSE), hak cipta (c) 2026 adyoi.

Nama file, produk, dan merek yang disebut di sini adalah milik Microsoft; repo ini tidak berafiliasi dengan Microsoft. Data nama, ukuran, versi, dan deskripsi file merupakan fakta yang dihimpun dari instalasi Windows lokal, bukan karya cipta Microsoft.


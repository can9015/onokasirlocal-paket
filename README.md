# Ono Local Packages

Repository package runtime untuk **Ono Local**.

Repository ini menyediakan paket server lokal yang digunakan oleh installer Ono untuk menyiapkan environment localhost secara otomatis pada Windows.

Runtime utama yang disediakan:

- Apache
- PHP
- MariaDB
- phpMyAdmin

Installer OnoKasir Local mengambil package dari GitHub Releases, memverifikasi SHA-256, kemudian mengekstrak package ke installation directory.

---

## Repository

```text
https://github.com/can9015/onokasirlocal-paket


Runtime Release

Release runtime menggunakan format:

Onolocal-vX.Y.Z

Contoh:

Onolocal-v1.0.0

Release title:

runtime-v1.0.0

Contoh release:

Tag:
Onolocal-v1.0.0

Release title:
runtime-v1.0.0


Package v1.0.0

Runtime release pertama:

Onolocal-v1.0.0

Package:

onokasirlocal-apache-1.0.0.zip
onokasirlocal-apache-1.0.0.zip.sha256

onokasirlocal-php-1.0.0.zip
onokasirlocal-php-1.0.0.zip.sha256

onokasirlocal-mariadb-1.0.0.zip
onokasirlocal-mariadb-1.0.0.zip.sha256

onokasirlocal-phpmyadmin-1.0.0.zip
onokasirlocal-phpmyadmin-1.0.0.zip.sha256

Setiap package .zip memiliki file checksum .sha256.

Package Structure

Package dirancang agar memiliki satu folder utama di dalam ZIP.

Apache
onokasirlocal-apache-1.0.0.zip
└── apache/
    ├── bin/
    │   └── httpd.exe
    ├── conf/
    │   ├── httpd.conf
    │   └── vhosts/
    │       └── onokasir.local.conf
    └── logs/

Folder logs dapat disediakan dalam keadaan kosong pada package distribution.

Log runtime yang dihasilkan saat aplikasi berjalan tidak disimpan sebagai bagian dari package release.

PHP
onokasirlocal-php-1.0.0.zip
└── php/
    ├── php.exe
    ├── php-cgi.exe
    ├── php.ini
    └── ...

PHP package berisi PHP runtime yang digunakan oleh OnoKasir Local.

MariaDB
onokasirlocal-mariadb-1.0.0.zip
└── mariadb/
    ├── bin/
    │   ├── mariadbd.exe
    │   └── mysql.exe
    ├── my.ini
    └── ...

MariaDB package menyediakan database server lokal untuk OnoKasir Local.

Data database runtime sebaiknya tidak dimasukkan ke dalam package release.

phpMyAdmin
onokasirlocal-phpmyadmin-1.0.0.zip
└── phpmyadmin/
    ├── index.php
    ├── config.inc.php
    └── ...

phpMyAdmin digunakan sebagai antarmuka administrasi database MariaDB lokal.

Download

Installer menggunakan URL GitHub Release berdasarkan tag.

Format URL:

https://github.com/can9015/onokasirlocal-paket/releases/download/{TAG}/{FILE}

Untuk release Onolocal-v1.0.0:

Apache
https://github.com/can9015/onokasirlocal-paket/releases/download/Onolocal-v1.0.0/onokasirlocal-apache-1.0.0.zip
PHP
https://github.com/can9015/onokasirlocal-paket/releases/download/Onolocal-v1.0.0/onokasirlocal-php-1.0.0.zip
MariaDB
https://github.com/can9015/onokasirlocal-paket/releases/download/Onolocal-v1.0.0/onokasirlocal-mariadb-1.0.0.zip
phpMyAdmin
https://github.com/can9015/onokasirlocal-paket/releases/download/Onolocal-v1.0.0/onokasirlocal-phpmyadmin-1.0.0.zip
SHA-256 Verification

Setiap ZIP mempunyai file checksum.

Contoh:

onokasirlocal-apache-1.0.0.zip
onokasirlocal-apache-1.0.0.zip.sha256

File .sha256 berisi SHA-256 checksum dari ZIP yang bersangkutan.

Contoh:

<sha256-hash>  onokasirlocal-apache-1.0.0.zip

Installer dapat menggunakan checksum tersebut untuk memastikan file yang di-download sesuai dengan package release.

Checksum harus dibuat ulang setiap kali isi ZIP berubah.

Installer Behavior

Installer OnoKasir Local menggunakan package runtime dengan proses umum:

Check Runtime
       ↓
Download Package
       ↓
Download SHA-256
       ↓
Verify SHA-256
       ↓
Extract ZIP
       ↓
Detect Installation Directory
       ↓
Configure Runtime
       ↓
Start Services
       ↓
Install / Start OnoKasir Local

Installer tidak bergantung pada lokasi absolut dari folder ZIP.

Package dapat diekstrak ke installation directory yang ditentukan installer.

Recursive Installation Directory

Engine installer mencari folder runtime secara recursive.

Karena itu package menggunakan satu root folder di dalam ZIP:

apache/
php/
mariadb/
phpmyadmin/

Contohnya:

ZIP
└── apache/
    └── bin/
        └── httpd.exe

Installer dapat mencari httpd.exe secara recursive untuk menentukan lokasi Apache.

Hal yang sama diterapkan pada runtime lainnya.

Runtime Separation

Setiap runtime disimpan sebagai package terpisah.

Apache
PHP
MariaDB
phpMyAdmin

Pemecahan package ini memiliki beberapa tujuan:

package dapat diperbarui secara independen
download dapat dilakukan hanya untuk runtime yang diperlukan
checksum dapat diverifikasi per package
installer dapat mendeteksi package secara terpisah
perubahan satu runtime tidak harus mengubah package runtime lainnya
Release Naming Convention

Nama package menggunakan format:

onokasirlocal-{component}-{version}.zip

Contoh:

onokasirlocal-apache-1.0.0.zip
onokasirlocal-php-1.0.0.zip
onokasirlocal-mariadb-1.0.0.zip
onokasirlocal-phpmyadmin-1.0.0.zip

Checksum:

{package}.zip.sha256

Contoh:

onokasirlocal-apache-1.0.0.zip.sha256
Versioning

Runtime menggunakan semantic versioning:

MAJOR.MINOR.PATCH

Contoh:

1.0.0
1.0.1
1.1.0
2.0.0

Tag GitHub menggunakan prefix:

Onolocal-v1.0.0

Contoh:

Onolocal-v1.0.0
Onolocal-v1.0.1
Onolocal-v1.1.0
Updating Runtime

Ketika runtime diperbarui:

Siapkan runtime baru.
Bersihkan file temporary, cache, log development, dan data machine-specific.
Pastikan struktur ZIP sesuai standar.
Buat ZIP baru.
Buat SHA-256 baru.
Upload ZIP dan checksum ke GitHub Release.
Gunakan tag versi baru.

Contoh:

Onolocal-v1.0.1

Package:

onokasirlocal-apache-1.0.1.zip
onokasirlocal-php-1.0.1.zip
onokasirlocal-mariadb-1.0.1.zip
onokasirlocal-phpmyadmin-1.0.1.zip

Checksum juga harus dibuat ulang.

Package Hygiene

Package release harus dibuat dari runtime yang bersih.

Hindari memasukkan:

*.log
cache
temporary files
temporary database data
machine-specific configuration
development files
debug output

Khusus folder log runtime, folder dapat tetap tersedia apabila diperlukan oleh konfigurasi:

apache/
└── logs/

namun file log hasil penggunaan komputer development tidak perlu dimasukkan ke release package.

Release Checklist

Sebelum membuat release baru, pastikan:

 Nama ZIP sudah benar.
 Struktur root ZIP sudah benar.
 Tidak ada file development yang tidak diperlukan.
 Tidak ada log development.
 Tidak ada data database development.
 File .sha256 dibuat dari ZIP final.
 Nama file di dalam .sha256 sama dengan nama ZIP.
 Semua package memiliki checksum.
 Tag release sesuai versi.
 Release title sesuai format runtime.
 Installer menggunakan tag yang sama.
 URL download dapat diakses.
Current Runtime

Current release:

Onolocal-v1.0.0

Release title:

runtime-v1.0.0

Components:

Apache
PHP
MariaDB
phpMyAdmin
Related Project

OnoKasir Local merupakan bagian dari ecosystem OnoKasir.

Repository ini hanya menyediakan runtime packages untuk environment lokal.

Source code aplikasi dan backend dikelola pada repository masing-masing.

License

Copyright © Ono.

Runtime package masing-masing komponen tetap tunduk pada license dan ketentuan distribusi dari project upstream masing-masing.

Periksa license masing-masing komponen sebelum melakukan redistribusi atau perubahan package.

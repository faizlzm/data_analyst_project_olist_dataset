# Analisis Pengaruh Waktu Pengiriman dan Biaya Ongkir terhadap Kepuasan Pelanggan pada E-Commerce Olist

Analisis berbasis SQL (PostgreSQL) pada Brazilian E-Commerce Public Dataset by Olist untuk mengukur seberapa besar keterlambatan pengiriman dan biaya ongkir memengaruhi review score pelanggan.

## Daftar Isi

- [Latar Belakang](#latar-belakang)
- [Rumusan Masalah](#rumusan-masalah)
- [Struktur Repositori](#struktur-repositori)
- [Dataset](#dataset)
- [Metodologi](#metodologi)
- [Temuan Utama](#temuan-utama)
- [Kesimpulan dan Rekomendasi](#kesimpulan-dan-rekomendasi)
- [Penulis](#penulis)

---

## Latar Belakang

Kepuasan pelanggan adalah indikator penting keberlangsungan bisnis, dan salah satu tolok ukurnya adalah review score yang diberikan setelah pesanan diterima. Banyak pesanan datang lebih lambat dari estimasi yang dijanjikan sistem, sementara pelanggan juga dikenakan biaya ongkir (freight) yang bervariasi, dari murah hingga sangat mahal.

## Rumusan Masalah

1. Seberapa besar dampak keterlambatan pengiriman terhadap rating yang diberikan pelanggan?
2. Apakah pelanggan yang membayar ongkir mahal benar-benar mendapatkan waktu pengiriman yang cepat?
3. Apakah pelanggan yang membayar ongkir mahal memberi rating lebih rendah ketika barangnya terlambat, dibandingkan pelanggan dengan ongkir murah?

## Struktur Repositori

```text
data_analyst_project_olist_dataset/
├── analysis_process/
│   └── mini_project_script.sql    # Seluruh proses: data understanding, cleaning, EDA, dan view analisis
├── dataset/
│   └── link_dataset               # Tautan sumber dataset di Kaggle (file CSV tidak disertakan)
├── report/
│   └── Analisis Pengaruh Waktu Pengiriman dan Biaya Ongkir terhadap Kepuasan Pelanggan pada E-Commerce Olist.pdf
└── README.md
```

## Dataset

Sumber: [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). Dataset berisi sekitar 100.000 pesanan yang terjadi antara 2016 dan 2018, terdiri dari beberapa tabel yang saling berelasi.

> File CSV tidak disimpan di repositori ini. Unduh dari tautan di atas atau dari `dataset/link_dataset`.

Analisis berfokus pada tiga tabel:

| Tabel | Isi | Kolom yang dipakai |
| --- | --- | --- |
| `olist_orders_dataset` | Siklus hidup pesanan | `order_status`, `order_purchase_timestamp`, `order_approved_at`, `order_delivered_carrier_date`, `order_delivered_customer_date`, `order_estimated_delivery_date` |
| `olist_order_items_dataset` | Rincian item per pesanan | `price`, `freight_value` |
| `olist_order_reviews_dataset` | Review pelanggan | `review_score`, komentar |

Relasi antartabel mengikuti ERD di halaman Kaggle: `orders` terhubung ke `order_items`, `order_reviews`, dan `order_payments` lewat `order_id`; ke `customers` lewat `customer_id`; sedangkan `order_items` terhubung ke `products` lewat `product_id` dan ke `sellers` lewat `seller_id`.

## Metodologi

Seluruh proses ada di `analysis_process/mini_project_script.sql` dan berjalan dalam empat tahap.

### 1. Data Understanding

- Menentukan primary key dan foreign key berdasarkan ERD Kaggle, sekaligus mengecek duplikasi karena penambahan primary key akan gagal jika ada data ganda.
- Mengecek jumlah baris, tipe data, missing value, dan outlier pada tiga tabel utama.

### 2. Data Preparation

| Temuan | Penanganan |
| --- | --- |
| `order_item_id` berulang di setiap pesanan yang memiliki lebih dari satu item, sehingga tidak bisa jadi primary key | Dibuat kolom `order_item_id_pk` (gabungan `order_id` + `order_item_id`) sebagai primary key baru |
| `review_id` bisa muncul untuk lebih dari satu `order_id` | Dibuat kolom `review_id_pk` (gabungan `review_id` + `order_id`) sebagai primary key baru |
| Kolom tanggal bertipe teks | String kosong diubah menjadi `NULL`, lalu dikonversi ke `timestamp` |
| Missing value pada kolom tanggal di `orders` (`order_approved_at` 146, `order_delivered_carrier_date` 1.783, `order_delivered_customer_date` 2.965) | Dianggap wajar karena terjadi pada pesanan yang belum berstatus `delivered`. Tanggal tidak diisi sembarangan agar tidak bias, dan analisis difokuskan pada pesanan `delivered` |
| `review_comment_title` (87.656) dan `review_comment_message` (58.247) kosong | Dianggap wajar karena komentar bersifat opsional; diisi string kosong |
| Outlier `price` (8.427 baris) dan `freight_value` (12.134 baris) dengan metode IQR | Dipertahankan karena secara bisnis mewakili transaksi sah (produk premium, promo gratis ongkir, atau pengiriman jarak jauh) |

### 3. Exploratory Data Analysis

Tiga view dibuat di PostgreSQL. Setiap view mengelompokkan data berdasarkan kuartil (Q1, Q2, Q3), lalu menghitung jumlah pesanan dan rata-rata metrik per kelompok:

| View | Pertanyaan yang dijawab | Logika utama |
| --- | --- | --- |
| `analisis_kepuasan_waktu` | Dampak keterlambatan terhadap rating | Lama pengiriman (hari) dibagi 4 kelompok kuartil dan dipisah berdasarkan status janji (`terlambat` jika tiba setelah tanggal estimasi, selain itu `tepat waktu`) |
| `analisis_ongkir_waktu` | Apakah ongkir mahal berarti pengiriman lebih cepat | Total ongkir per pesanan dibagi 4 level kuartil, lalu dihitung rata-rata lama pengiriman |
| `analisis_ekspektasi_rating` | Toleransi pelanggan terhadap keterlambatan menurut besar ongkir | Ongkir dikelompokkan menjadi rendah (≤ Q1), standar, dan tinggi (> Q3), lalu rating dibandingkan antara pesanan tepat waktu dan terlambat |

Semua view hanya memakai pesanan berstatus `delivered` dengan tanggal pengiriman yang valid.

## Temuan Utama

### 1. Keterlambatan dari janji adalah penyebab utama rating anjlok

| Kecepatan pengiriman | Status janji | Pesanan | Rata-rata rating |
| --- | --- | ---: | ---: |
| Sangat cepat (0–6 hari) | Tepat waktu | 25.814 | 4,42 |
| Sangat cepat (0–6 hari) | Terlambat | 225 | 4,29 |
| Normal (7–10 hari) | Tepat waktu | 25.767 | 4,34 |
| Normal (7–10 hari) | Terlambat | 273 | 3,82 |
| Agak lambat (11–15 hari) | Tepat waktu | 20.744 | 4,26 |
| Agak lambat (11–15 hari) | Terlambat | 422 | 3,42 |
| Sangat lambat (> 15 hari) | Tepat waktu | 16.328 | 4,06 |
| Sangat lambat (> 15 hari) | Terlambat | 6.780 | 2,41 |

- Penurunan rating paling tajam terjadi pada pengiriman yang sangat lambat **dan** melewati tanggal estimasi (rating 2,41 pada 6.780 pesanan).
- Pengiriman yang sama lambatnya tetapi tiba sesuai estimasi tetap mendapat rating 4,06. Artinya pelanggan lebih sensitif terhadap janji yang tidak ditepati daripada terhadap lamanya pengiriman itu sendiri.
- Dari tabel di atas, 7.700 dari 96.353 pesanan (sekitar 8,0%) terlambat dari estimasi.

### 2. Ongkir mahal tidak berarti pengiriman lebih cepat

| Level ongkir | Pesanan | Rata-rata waktu kirim (hari) |
| --- | ---: | ---: |
| Murah (≤ 13,85) | 24.153 | 7,31 |
| Menengah (≤ 17,17) | 24.091 | 12,50 |
| Agak mahal (≤ 24,02) | 24.112 | 13,57 |
| Sangat mahal (> 24,02) | 24.114 | 15,01 |

Semakin mahal ongkir, semakin lama pengirimannya. Ongkir termurah justru sampai paling cepat (sekitar 7 hari), sedangkan ongkir termahal rata-rata sekitar 15 hari.

### 3. Pelanggan dengan ongkir mahal paling kecewa saat terlambat

| Level ekspektasi | Status janji | Pesanan | Rata-rata rating |
| --- | --- | ---: | ---: |
| Rendah (ongkir murah) | Tepat waktu | 22.682 | 4,39 |
| Rendah (ongkir murah) | Terlambat | 1.430 | 3,09 |
| Standar (ongkir menengah) | Tepat waktu | 44.068 | 4,34 |
| Standar (ongkir menengah) | Terlambat | 4.087 | 2,47 |
| Tinggi (ongkir mahal) | Tepat waktu | 21.903 | 4,10 |
| Tinggi (ongkir mahal) | Terlambat | 2.183 | 2,40 |

- Saat terlambat, pelanggan berongkir mahal memberi rating 2,40, dibanding 3,09 pada pelanggan berongkir murah.
- Saat tepat waktu pun, pelanggan berongkir mahal memberi rating lebih rendah (4,10 dibanding 4,39), yang kemungkinan berkaitan dengan waktu tunggu mereka yang lebih lama.

## Kesimpulan dan Rekomendasi

**Kesimpulan**

1. **Ketepatan janji lebih penting daripada kecepatan.** Pelanggan toleran terhadap waktu tunggu yang panjang selama pengiriman sesuai estimasi. Kekecewaan terbesar (rating 2,41) datang dari janji yang tidak ditepati.
2. **Ongkir tidak berkorelasi dengan kecepatan.** Ongkir termurah memiliki pengiriman tercepat (sekitar 7 hari) dan ongkir termahal terlama (sekitar 15 hari), sehingga faktor lain seperti jarak diduga menjadi penentu utama biaya kirim.
3. **Kekecewaan berlapis pada pelanggan berongkir mahal.** Ongkir mahal menciptakan ekspektasi tinggi, dan saat terjadi keterlambatan kelompok ini memberi rating lebih rendah daripada pelanggan berongkir murah.

**Rekomendasi**

1. **Perbaiki algoritma estimasi** kedatangan barang agar lebih akurat, karena keterlambatan dari janji adalah pemicu rating terendah.
2. **Tambahkan fitur live tracking** dengan notifikasi pergerakan paket yang mendetail, terutama bagi pelanggan berongkir mahal yang masa tunggunya lebih lama.
3. **Audit faktor penentu ongkir** (jarak, berat, rute) untuk menyusun strategi penekanan biaya kirim.
4. **Tambahkan penjelasan di halaman checkout** ketika ongkir melampaui batas tertentu (misalnya di atas 24), bahwa biaya disesuaikan dengan jarak antarprovinsi atau berat dan dimensi paket, supaya pelanggan tidak kecewa saat barang tiba lama.

## Penulis

**Ahmad Faiz Ali Azmi**
Lulusan Teknik Informatika, Universitas Brawijaya. Peserta Offline Bootcamp Data Analyst Batch 4 di dibimbing.id.

GitHub: [@faizlzm](https://github.com/faizlzm)

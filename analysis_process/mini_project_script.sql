--DATA UNDERSTANDING
--Penentuan primary key dan foreign key didasarkan pada diagram ERD yang terdapat dalam repositori Kaggle (https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/data)
--Pada tahap ini juga dilakukan cek duplikasi karena kode menambahkan primary key akan error jika terdapat data duplikasi
alter table olist_orders_dataset
add constraint order_id primary key (order_id)

alter table olist_order_payments_dataset
add constraint order_id foreign key (order_id) references olist_orders_dataset(order_id);

alter table olist_customers_dataset
add constraint customer_id primary key (customer_id);

alter table olist_orders_dataset 
add constraint customer_id foreign key (customer_id) references olist_customers_dataset(customer_id)

--Pada Table olist_order_items_dataset, ditemukan banyak sekali duplikasi pada order_item_id yang logikanya sebagai primary key
select order_item_id, count(*)
from olist_order_items_dataset
group by order_item_id
having count(*)>1

--Membuat Primary Key baru untuk mengakomodasi kebutuhan table olist_order_items_dataset
alter table olist_order_items_dataset
add column order_item_id_pk varchar(255)

update olist_order_items_dataset
set order_item_id_pk = concat(order_id, '-', order_item_id)

alter table olist_order_items_dataset
add constraint order_item_id_pk primary key (order_item_id_pk)

--Melakukan cek apakah kolom order_item_id_pk yang di tunjuk sebagai primary key yang baru memiliki duplikasi
select order_item_id_pk, count(*)
from olist_order_items_dataset
group by order_item_id_pk
having count(*)>1

alter table olist_order_items_dataset 
add constraint order_id foreign key (order_id) references olist_orders_dataset(order_id)

alter table olist_products_dataset 
add constraint product_id primary key (product_id);

alter table olist_order_items_dataset 
add constraint product_id foreign key (product_id) references olist_products_dataset(product_id)

alter table olist_sellers_dataset  
add constraint seller_id primary key (seller_id);

alter table olist_order_items_dataset 
add constraint seller_id foreign key (seller_id) references olist_sellers_dataset(seller_id)

--Pada Table olist_order_reviews_dataset, ditemukan banyak sekali duplikasi pada review_id yang logikanya sebagai primary key
select review_id, count(*)
from olist_order_reviews_dataset 
group by review_id
having count(*)>1
order by review_id

--Membuat Primary Key baru untuk mengakomodasi kebutuhan table olist_order_reviews_dataset
alter table olist_order_reviews_dataset
add column review_id_pk varchar(255)

update olist_order_reviews_dataset
set review_id_pk = concat(review_id, '-', order_id)

alter table olist_order_reviews_dataset
add constraint review_id_pk primary key (review_id_pk)

--Melakukan cek apakah kolom review_id_pk yang di tunjuk sebagai primary key yang baru memiliki duplikasi
select review_id_pk, count(*)
from olist_order_reviews_dataset
group by review_id_pk
having count(*)>1

alter table olist_order_reviews_dataset 
add constraint order_id foreign key (order_id) references olist_orders_dataset(order_id)

--Projek kali ini akan berfokus ke 3 dataset yaitu, olist_orders_dataset.csv, olist_order_items_dataset.csv, olist_order_reviews_dataset.csv
--Cek jumlah baris
select count(*) from olist_orders_dataset

select count(*) from olist_order_items_dataset

select count(*) from olist_order_reviews_dataset

--Ubah tipe data
update olist_orders_dataset
set 
    order_purchase_timestamp = nullif(order_purchase_timestamp, ''),
    order_approved_at = nullif(order_approved_at, ''),
    order_delivered_carrier_date = nullif(order_delivered_carrier_date, ''),
    order_delivered_customer_date = nullif(order_delivered_customer_date, ''),
    order_estimated_delivery_date = nullif(order_estimated_delivery_date, '')

alter table olist_orders_dataset
    alter column order_purchase_timestamp type timestamp using order_purchase_timestamp::timestamp,
    alter column order_approved_at type timestamp using order_approved_at::timestamp,
    alter column order_delivered_carrier_date type timestamp using order_delivered_carrier_date::timestamp,
    alter column order_delivered_customer_date type timestamp using order_delivered_customer_date::timestamp,
    alter column order_estimated_delivery_date type timestamp using order_estimated_delivery_date::timestamp

alter table olist_order_items_dataset
alter column shipping_limit_date type timestamp using shipping_limit_date::timestamp
    
select column_name, data_type 
from information_schema.columns 
where table_name = 'olist_orders_dataset'

--Cek kolom yang mengandung missing value
--table olist_orders_dataset
select
    'order_id' as column_name,
    count(*) filter (where order_id is null or order_id = '') as missing_count
from olist_orders_dataset
union all
select
    'customer_id',
    count(*) filter (where customer_id is null or customer_id = '')
from olist_orders_dataset
union all
select
    'order_status',
    count(*) filter (where order_status is null or order_status = '')
from olist_orders_dataset
union all
select
    'order_purchase_timestamp',
    count(*) filter (where order_purchase_timestamp is null)
from olist_orders_dataset
union all
select
    'order_approved_at',
    count(*) filter (where order_approved_at is null)
from olist_orders_dataset
union all
select
    'order_delivered_carrier_date',
    count(*) filter (where order_delivered_carrier_date is null)
from olist_orders_dataset
union all
select
    'order_delivered_customer_date',
    count(*) filter (where order_delivered_customer_date is null)
from olist_orders_dataset
union all
select
    'order_estimated_delivery_date',
    count(*) filter (where order_estimated_delivery_date is null)
from olist_orders_dataset

--Ditemukan banyak nilai null di beberapa fitur bertipe data tanggal. tatapi hal ini logis karena NULL banyak terjadi pada status_order selain delivered. Mengisi tanggal secara sembarangan bisa membuat data menjadi bias
--Oleh karena itu, penanganan nilai null hanya order_status delivered
select *
from olist_orders_dataset
where order_status = 'delivered'

--logikanya kalau order di approved tidak jauh setelah barang dibeli
update olist_orders_dataset
set order_approved_at = order_purchase_timestamp
where order_status = 'delivered'

--table olist_order_items_dataset
select
    'order_id' as column_name,
    count(*) filter (where order_id is null or order_id = '') as missing_count
from olist_order_items_dataset
union all
select
    'order_item_id',
    count(*) filter (where order_item_id is null)
from olist_order_items_dataset
union all
select
    'product_id',
    count(*) filter (where product_id is null or product_id = '')
from olist_order_items_dataset
union all
select
    'seller_id',
    count(*) filter (where seller_id is null or seller_id = '')
from olist_order_items_dataset
union all
select
    'shipping_limit_date',
    count(*) filter (where shipping_limit_date is null)
from olist_order_items_dataset
union all
select
    'price',
    count(*) filter (where price is null)
from olist_order_items_dataset
union all
select
    'freight_value',
    count(*) filter (where freight_value is null)
from olist_order_items_dataset
union all
select
    'order_item_id_pk',
    count(*) filter (where order_item_id_pk is null)
from olist_order_items_dataset

--table olist_order_reviews_dataset
select
    'review_id' as column_name,
    count(*) filter (where review_id is null or review_id = '') as missing_count
from olist_order_reviews_dataset
union all
select
    'order_id',
    count(*) filter (where order_id is null or order_id= '')
from olist_order_reviews_dataset
union all
select
    'review_score',
    count(*) filter (where review_score is null)
from olist_order_reviews_dataset
union all
select
    'review_comment_title',
    count(*) filter (where review_comment_title is null or review_comment_title = '')
from olist_order_reviews_dataset
union all
select
    'review_comment_message',
    count(*) filter (where review_comment_message is null or review_comment_message = '')
from olist_order_reviews_dataset
union all
select
    'review_creation_date',
    count(*) filter (where review_creation_date is null)
from olist_order_reviews_dataset
union all
select
    'review_answer_timestamp',
    count(*) filter (where review_answer_timestamp is null)
from olist_order_reviews_dataset
union all
select
    'review_id_pk',
    count(*) filter (where review_id_pk is null)
from olist_order_reviews_dataset

--Banyak di temukan review_comment_title dan review_comment_message yang bernilai null dan itu logis dan sering terjadi dan di perbolehkan di beberapa aplikasi terkenal, seperti shopee dll. 
--Oleh karena itu penanganannya adalah melabeli dengan string kosong
update olist_order_reviews_dataset
set 
    review_comment_title = case 
        when review_comment_title is null then '' 
        else review_comment_title 
    end,
    review_comment_message = case 
        when review_comment_message is null then '' 
        else review_comment_message 
    end
where 
    review_comment_title is null 
    or review_comment_message is null
    
--Menghitung jumlah outlier pada kolom tertentu
--Table olist_order_items_dataset
with stats as (
    select
        percentile_cont(0.25) within group (order by price) as q1,
        percentile_cont(0.75) within group (order by price) as q3
    from olist_order_items_dataset
),
bounds as (
    select
        (q1 - 1.5 * (q3 - q1)) as lower_bound,
        (q3 + 1.5 * (q3 - q1)) as upper_bound
    from stats
)
select
    count(*) as total_outlier_price
from olist_order_items_dataset d
cross join bounds
where d.price < lower_bound
   or d.price > upper_bound
--Secara domain bisnis, harga produk tidak mungkin bernilai negatif, maka seluruh 8.427 data outlier tersebut murni merupakan produk dengan harga di atas upper_bound
   
with stats as (
    select
        percentile_cont(0.25) within group (order by freight_value) as q1,
        percentile_cont(0.75) within group (order by freight_value) as q3
    from olist_order_items_dataset
),
bounds as (
    select
        (q1 - 1.5 * (q3 - q1)) as lower_bound,
        (q3 + 1.5 * (q3 - q1)) as upper_bound
    from stats
)
select
    count(*) as total_outlier_freight_value
from olist_order_items_dataset d
cross join bounds
where d.freight_value < lower_bound
   or d.freight_value > upper_bound
--Decara domain bisnis, outlier tersebut merupakan transaksi sah yang mencerminkan promo gratis ongkir dan pengiriman jarak jauh atau berat dan lain-lain
   
with stats as (
    select
        percentile_cont(0.25) within group (order by price) as q1,
        percentile_cont(0.75) within group (order by price) as q3
    from olist_order_items_dataset
),
iqr_calc as (
    select
        q1,
        q3,
        (q3 - q1) as iqr,
        (q1 - 1.5 * (q3 - q1)) as lower_bound,
        (q3 + 1.5 * (q3 - q1)) as upper_bound
    from stats
)
select d.*
from olist_order_items_dataset d
cross join iqr_calc
where d.price < lower_bound
   or d.price > upper_bound

with stats as (
    select
        percentile_cont(0.25) within group (order by freight_value) as q1,
        percentile_cont(0.75) within group (order by freight_value) as q3
    from olist_order_items_dataset
),
iqr_calc as (
    select
        q1,
        q3,
        (q3 - q1) as iqr,
        (q1 - 1.5 * (q3 - q1)) as lower_bound,
        (q3 + 1.5 * (q3 - q1)) as upper_bound
    from stats
)
select d.*
from olist_order_items_dataset d
cross join iqr_calc
where d.freight_value < lower_bound
   or d.freight_value > upper_bound

--Table olist_order_reviews_dataset
select 
    review_score, 
    count(*) as frekuensi
from olist_order_reviews_dataset
group by review_score
order by frekuensi asc
   
--table olist_orders_dataset
select 
    order_status, 
    count(*) as frekuensi
from olist_orders_dataset
group by order_status
order by frekuensi asc

--EDA
--Pengaruh terhadap Kepuasan Pelanggan
--Melihat seberapa parah penurunan rating pesanan yang datang terlambat dari estimasi sistem, melihat tren penurunannya berdasarkan rentang waktu
create or replace view analisis_kepuasan_waktu as
with status_pengiriman as (
    select 
        o.order_id,
        r.review_score,
        extract(day from (o.order_delivered_customer_date - o.order_purchase_timestamp)) as lama_pengiriman_hari,
        case 
            when o.order_delivered_customer_date > o.order_estimated_delivery_date then 'terlambat'
            else 'tepat waktu'
        end as status_janji
    from olist_orders_dataset o
    join olist_order_reviews_dataset r on o.order_id = r.order_id
    where o.order_status = 'delivered' 
      and o.order_delivered_customer_date is not null
      and o.order_estimated_delivery_date is not null
),
hitung_kuartil as (
    select 
        percentile_cont(0.25) within group (order by lama_pengiriman_hari) as q1,
        percentile_cont(0.50) within group (order by lama_pengiriman_hari) as q2,
        percentile_cont(0.75) within group (order by lama_pengiriman_hari) as q3
    from status_pengiriman
    where lama_pengiriman_hari >= 0
),
kategori_waktu as (
    select
        s.status_janji,
        s.review_score,
        case
            when s.lama_pengiriman_hari <= k.q1 then '1. sangat cepat (0-6 hari)'
            when s.lama_pengiriman_hari <= k.q2 then '2. normal (7-10 hari)'
            when s.lama_pengiriman_hari <= k.q3 then '3. agak lambat (11-15 hari)'
            else '4. sangat lambat (> 15 hari)'
        end as kecepatan_pengiriman
    from status_pengiriman s
    cross join hitung_kuartil k
    where s.lama_pengiriman_hari >= 0
)
select 
    kecepatan_pengiriman,
    status_janji,
    count(*) as total_pesanan,
    round(avg(review_score), 2) as rata_rata_rating
from kategori_waktu
group by kecepatan_pengiriman, status_janji
order by kecepatan_pengiriman, status_janji

--Korelasi dengan Ongkos Kirim
--Apakah pelanggan yang membayar ongkir mahal benar-benar mendapatkan waktu pengiriman yang cepat?
create or replace view analisis_ongkir_waktu as
with ongkir_dan_waktu as (
    -- jumlahkan ongkir per pesanan dan hitung waktu pengirimannya
    select 
        o.order_id,
        sum(i.freight_value) as total_ongkir,
        extract(day from (o.order_delivered_customer_date - o.order_purchase_timestamp)) as lama_pengiriman_hari
    from olist_orders_dataset o
    join olist_order_items_dataset i on o.order_id = i.order_id
    where o.order_status = 'delivered' 
      and o.order_delivered_customer_date is not null
    group by o.order_id, o.order_delivered_customer_date, o.order_purchase_timestamp
),
kuartil_ongkir as (
    --tentukan batas q1, q2, q3 dari ongkos kirim
    select 
        percentile_cont(0.25) within group (order by total_ongkir) as q1,
        percentile_cont(0.50) within group (order by total_ongkir) as q2,
        percentile_cont(0.75) within group (order by total_ongkir) as q3
    from ongkir_dan_waktu
),
kategori_ongkir as (
    --kelompokkan data jadi 4 level ongkir
    select 
        w.lama_pengiriman_hari,
        case 
            when w.total_ongkir <= k.q1 then '1. ongkir murah ($13.85)'
            when w.total_ongkir <= k.q2 then '2. ongkir menengah ($17.17)'
            when w.total_ongkir <= k.q3 then '3. ongkir agak mahal ($24.02)'
            else '4. ongkir sangat mahal ($25++)'
        end as level_ongkir
    from ongkir_dan_waktu w
    cross join kuartil_ongkir k
    where w.lama_pengiriman_hari >= 0
)
--hitung rata-rata waktu pengiriman per level ongkir
select 
    level_ongkir,
    count(*) as total_pesanan,
    round(avg(lama_pengiriman_hari), 2) as rata_rata_waktu_pengiriman_hari
from kategori_ongkir
group by level_ongkir
order by level_ongkir

--Korelasi freight_value & review_score
--Apakah pelanggan yang bayar ongkir mahal akan memberi rating rendah ketika barangnya terlambat, dibandingkan orang yang ongkirnya murah?
create or replace view analisis_ekspektasi_rating as
with ongkir_per_order as (
    --hitung total ongkir per pesanan
    select 
        order_id,
        sum(freight_value) as total_ongkir
    from olist_order_items_dataset
    group by order_id
),
gabung_semua as (
    --gabung order, ongkir, review, dan tentukan status keterlambatan
    select 
        o.order_id,
        ong.total_ongkir,
        r.review_score,
        case 
            when o.order_delivered_customer_date > o.order_estimated_delivery_date then 'terlambat'
            else 'tepat waktu'
        end as status_janji
    from olist_orders_dataset o
    join ongkir_per_order ong on o.order_id = ong.order_id
    join olist_order_reviews_dataset r on o.order_id = r.order_id
    where o.order_status = 'delivered'
      and o.order_delivered_customer_date is not null
      and o.order_estimated_delivery_date is not null
),
kuartil_ongkir as (
    --cari nilai q1, q2, q3 ongkir
    select 
        percentile_cont(0.25) within group (order by total_ongkir) as q1,
        percentile_cont(0.75) within group (order by total_ongkir) as q3
    from gabung_semua
),
kategori_ekspektasi as (
    --buat kategori sederhana (murah vs mahal) agar bedanya kentara
    select 
        g.status_janji,
        g.review_score,
        case 
            when g.total_ongkir <= k.q1 then 'ekspektasi rendah (ongkir murah)'
            when g.total_ongkir > k.q3 then 'ekspektasi tinggi (ongkir mahal)'
            else 'ekspektasi standar (ongkir menengah)'
        end as level_ekspektasi
    from gabung_semua g
    cross join kuartil_ongkir k
)
--bandingkan ratingnya!
select 
    level_ekspektasi,
    status_janji,
    count(*) as total_pesanan,
    round(avg(review_score), 2) as rata_rata_rating
from kategori_ekspektasi
group by level_ekspektasi, status_janji
order by level_ekspektasi, status_janji

select * from analisis_kepuasan_waktu
select * from analisis_ongkir_waktu
select * from analisis_ekspektasi_rating
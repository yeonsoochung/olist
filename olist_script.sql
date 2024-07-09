-- Database: olist

-- DROP DATABASE IF EXISTS olist;

-- CREATE DATABASE olist
--     WITH
--     OWNER = postgres
--     ENCODING = 'UTF8'
--     LC_COLLATE = 'English_United States.1252'
--     LC_CTYPE = 'English_United States.1252'
--     LOCALE_PROVIDER = 'libc'
--     TABLESPACE = pg_default
--     CONNECTION LIMIT = -1
--     IS_TEMPLATE = False;

/**
Imported these tables (csv files)
**/
select * from customers;
select * from geolocation;
select * from order_items;
select * from order_payments;
select * from order_reviews;
select * from orders;
select * from products;
select * from sellers;
select * from product_category_name_translation;

/**
View products_eng:
Join products table with translation table so that product categories are in English.
Create product_volume column.
**/
-- drop view products_eng;

create view products_eng ("Product ID", "Product Category", "Product Name Length",  
	"Product Description Length", "Product Photos Qty", "Product Weight (g)", 
	"Product Length (cm)", "Product Height (cm)", "Product Width (cm)", "Product Volume (cm^3)")
as
select product_id, t.product_category_name_english, product_name_length,
	product_description_length, product_photos_qty, product_weight_g,
	product_length_cm, product_height_cm, product_width_cm, 
	product_length_cm * product_height_cm * product_width_cm as product_volume
from products p
left join product_category_name_translation t
on p.product_category_name = t.product_category_name;


/**
How many orders were not delivered?
**/
with order_status_count as (
	select  order_status, 
			count(order_status) as n_order_status
	from orders
	group by order_status
	order by count(order_status) desc
)
select  order_status,
		n_order_status,
		round(n_order_status::numeric/(select count(*) from orders)*100, 3) as percentage_order_status
from order_status_count;
/**
~3% of orders were not delivered.
This is a small percentage, so I will not explore this part of data for this project.
**/


/**
Create view called zip_code_coords that contains the average
lat and lng of every zip code.
This view is used to compute the Haversine distance between customer and seller
for each order in the "order_distances" view. I did not end up using this view in my report, 
but I left it here as demo.
**/
create view zip_code_coords as (
select geolocation_zip_code_prefix as zip_code, avg(geolocation_lat) as lat,
	avg(geolocation_lng) as lng
from geolocation
group by zip_code
order by zip_code );

select * from zip_code_coords;


/**
Create view called orders_base_view.
This will later be joined with the order_reviews table to form my "orders_view" view.
**/
drop view orders_base_view;

create view orders_base_view ("Order ID", "Customer ID", 
	"Order Status", "Order Purchase Timestamp", "Order Approved At", "Order Delivered Carrier Date", 
	"Order Delivered Customer Date", "Order Estimated Delivery Date", "Order Delivery Date Difference")
as (
	select order_id, o.customer_id, order_status,
		order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, 
		order_delivered_customer_date, order_estimated_delivery_date, 
		round(extract(epoch from order_estimated_delivery_date - order_delivered_customer_date) / 86400.0) as order_estimated_minus_delivery_date
	from orders o
	left join customers c
	on o.customer_id = c.customer_id );
select * from orders_base_view;


/**
Create view called order_customers. This will be used to compute order_distances.
**/
drop view order_customers;

create view order_customers ("Order ID", "Customer uniqID", "Customer Zip Code", "Customer City", "Customer State")
as (
	select order_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state
	from orders o
	left join customers c
	on o.customer_id = c.customer_id
);
select * from order_customers;


/**
Create view called order_sellers. This will be used to compute order_distances.
**/
drop view order_sellers cascade;

create view order_sellers ("Order ID", "Seller ID", "Seller Zip Code", "Seller City", "Seller State")
as (
	with unique_order_seller as (
		select distinct on (order_id) *
		from order_items
	)
	select o.order_id, u.seller_id, seller_zip_code_prefix, seller_city, seller_state
	from orders o
	left join unique_order_seller u
	on o.order_id = u.order_id
	left join sellers s
	on u.seller_id = s.seller_id
);
select * from order_sellers;


/**
Create view called order_distances that has a column of distances
between customer/seller pair. Each zip code is associated with its
average lat and lng values (a zip code can have multiple different 
coordinates based on customer/seller's location).
**/
with cte as (
	select distinct customer_unique_id from customers
)
select count (*) from cte -- 96096 unique customers; 99441 total orders

	
drop view order_distances;

create view order_distances ("Order ID", "Customer-Seller Distance (km)")
as (
	select oc."Order ID",
		2*6371*asin(sqrt(0.5*(1-cos(radians(z2.lat-z1.lat))+cos(radians(z1.lat))*cos(radians(z2.lat))*(1-cos(radians(z2.lng-z1.lng))))))
			as customer_seller_distance
	from order_customers oc
	full join order_sellers os
	on oc."Order ID" = os."Order ID"
	left join zip_code_coords z1
	on oc."Customer Zip Code" = z1.zip_code
	left join zip_code_coords z2
	on os."Seller Zip Code" = z2.zip_code
);
select * from order_distances -- 99441 rows, as expected


/**
check null values
**/
select count(*) from orders_distances; -- 113425 rows
select * from orders_distances where "Customer-Seller Distance (km)" is null; -- 1329 rows


/**
Create order_items_view.
**/
create view order_items_view ("Order ID", "Order Item ID", "Product ID", "Seller ID", 
	"Shipping Limit Date", "Price", "Freight", "Item Revenue") as
select order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value,
	price*0.1
from order_items;
select * from order_items_view;


/**
Create orders_view that merges orders_base_view, order_customers, order_items_view, and order_distances.
**/
drop view orders_view;

create view orders_view ("Order ID", 
	"Customer ID", "Customer uniqID", 
	"Seller ID", 
	"Order Item ID", "Product ID", "Item Revenue", 
	"Order Status", "Order Purchase Date", "Order Approval Date")
as (
	select ob."Order ID", 
		"Customer ID", "Customer uniqID", 
		"Seller ID", 
		"Order Item ID", "Product ID", "Item Revenue", 
		"Order Status", 
		"Order Purchase Timestamp"::date, 
		"Order Approved At"::date
	from orders_base_view ob
	join order_customers oc
	on ob."Order ID" = oc."Order ID"
	join order_items_view oi
	on ob."Order ID" = oi."Order ID"
	join order_distances od
	on ob."Order ID" = od."Order ID"
	order by "Order Purchase Timestamp" );
select * from orders_view;


/**
Create order_reviews_view. Data transformed because some orders had multiple
review scores.
**/
-- query below confirms there are duplicate order ID's in order_reviews table.
with cte as (
	select order_id, count(order_id)
	from order_reviews
	group by order_id
	having count(order_id) > 1
)
select *
from order_reviews
where order_id in (
	select order_id from cte )
order by order_id;
-- it seems that some order ID's appear more than once because the customer
-- wanted to update their review.
-- the query below for order_reviews_view keeps the most recent review score 
-- for orders with multiple reviews; the remaining order_id's are the primary key
-- for order_reviews_view.

drop view order_reviews_view;
create view order_reviews_view ("Order ID", "Customer uniqID", "Seller ID", 
	"Review Score", "Review Answer Timestamp")
as (
	with latest_review_times as (
		select order_id, max(review_answer_timestamp) as latest_review_timestamp
		from order_reviews
		group by order_id
		order by order_id ),
	latest_reviews as (
		select distinct on (lrt.order_id)
			lrt.order_id, review_score, latest_review_timestamp
		from latest_review_times lrt, order_reviews o
		where o.review_answer_timestamp = lrt.latest_review_timestamp
	),
	distinct_order_parties as (
		select distinct on ("Order ID")
			"Order ID", "Customer uniqID", "Seller ID"
		from orders_view
		order by "Order ID" )
	select lr.order_id, "Customer uniqID", "Seller ID", review_score, latest_review_timestamp
	from latest_reviews lr, distinct_order_parties dop
	where lr.order_id = dop."Order ID" -- and o.review_answer_timestamp = lr.latest_review_timestamp
	order by latest_review_timestamp
);
select * from order_reviews_view;


/**
Create rolling_sales_view: compute rolling sum of sales for each seller.
I did not end up using this but keeping as demo.
**/
drop view rolling_sales_view;

create view rolling_sales_view
as (
	select "Order ID", "Seller ID", "Item Revenue", "Order Purchase Date", 
		sum("Item Revenue") over (partition by "Seller ID" order by "Order Purchase Date") as "Seller Sales Running Total"
	from orders_view
);
select * from rolling_sales_view;


/**
Create views for the rest of tables and attributes.
Create two sellers_view (reviewed_sellers_view and ordered_sellers_view) for data modelling purposes.
**/
create view order_payments_view ("Order ID", "Payment Sequence", "Payment Type", 
	"Payment Installments", "Payment Value") as
select order_id, payment_sequential, payment_type, payment_installments, payment_value
from order_payments;
select * from order_payments_view;

drop view customers_view;
create view customers_view ("Customer ID", "Customer uniqID", "Customer Zip Code", "Customer City", 
	"Customer State", "Customer Country")
as (
	select customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state, 
		'Brazil' as customer_country
	from customer
);

drop view reviewed_sellers_view;
create view reviewed_sellers_view ("Seller ID", "Seller Zip Code", "Seller City", "Seller State", "Seller Country")
as (
	select seller_id, seller_zip_code_prefix, seller_city, seller_state, 
		'Brazil' as seller_country
	from sellers
);

drop view ordered_sellers_view;
create view ordered_sellers_view ("Seller ID", "Seller Zip Code", "Seller City", "Seller State", "Seller Country")
as (
	select seller_id, seller_zip_code_prefix, seller_city, seller_state, 
		'Brazil' as seller_country
	from sellers
);


/**
Create view for calendar_view
**/
drop view calendar_view;

create view calendar_view as (
	select generate_series('2016-01-01'::date, '2018-12-31'::date, '1 day'::interval)::date as Date );
select * from calendar_view;


-- cross-check w/ Power BI output: quantities sold of some of the product categories
select pt.product_category_name_english, count(pt.product_category_name_english)
from orders_view ov, products p, product_category_name_translation pt
where ov."Product ID" = p.product_id and p.product_category_name = pt.product_category_name
group by pt.product_category_name_english
order by count desc;

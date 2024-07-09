This project demonstrates my SQL and Power BI (PBI) skills, including data modeling and DAX. I apply these skills on Kaggle's Olist dataset, which is real-life data provided by Olist, a Brazilian e-commerce company.

Source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

A major assumption I make in this project is that Olist earns revenue from 10% of all order transaction.

After creating a new "olist" database in Postgres, the Kaggle csv files were imported to Postgres as the following tables:

- customers: customer data including city/state data. Note: customer_unique_id represents customers; customer_id is a unique ID attached to each order ID. So, if a customer makes multiple orders, they will have the same customer_unique_id but different customer_id for each order.
- geolocation: location information. The zip code prefix column is referenced by the customers and sellers data tables. I found that there are duplicate zip code values with different lat/lng coordinates.
- order_items: used to get price of each order/transaction.
- order_payments: data on payment methods. I did not use this dataset in this project.
- order_reviews: reviews left by customers on their orders; not all orders were reviewed. I focus on the review scores, which takes values {1, 2, 3, 4, 5}, more than the review comments.
- orders: data on the orders made. This forms the basis of my fact table.
- product_category_name_translation: contains English translations of each product category.
- products: data on each product. I used the product_id column as the primary key. I used only the product_category column in this project.
- sellers: seller data including city/state data.

I then created the following views with SQL code. Some of them are intermediate views used to create final views that ultimately get loaded into PBI.

- products_eng: joined products table with the translation table.
- zip_code_coords: aggregated geolocation table's zip code prefixes. There were duplicate zip codes with different coordinates, so this view aggregates zip codes by averaging the coordinates.
- orders_base_view: joined orders table with customers table. Specific columns were selected to build a later view.
- order_customers: joins orders table with customers table. Specific columns were selected to build a later view.
- order_sellers: joins orders, order_items, and sellers tables. Transformations applied so that each of row in this view is a distinct order. Specific columns were selected to build a later view.
- order_distances: multiple joins and a mathematical formula applied, resulting in a view that contains each distinct order_id and the distance between its seller and customer. I did not end up using this in my PBI dashboard but leaving this for demonstration.
- order_items_view: essentially made the order_items table into a view. A new column of price*0.1 is added to calculate revenue (10% of all transactions).
- orders_view: joins orders_base_view, order_customers, and order_items_view. Its columns are Order ID, Customer ID, Customer uniqID, Seller ID, Order Item ID, Product ID, Item Revenue, Order Status, Order Purchase Date, and Order Approval Date.
- order_reviews_view: joined select data from order_reviews table and orders_view view. I found that the order_reviews dataset contains some duplicate order ID's due to some customers updating their reviews, so I applied a transformation to have only the latest review for each order. This view contains order ID, customer uniqID, seller ID, review score, and review timestamp for all reviewed orders.
- rolling_sales_view: this view computes the rolling sum of sales for each seller using a window function. I ended up not using this view but kept it as demo.
- order_payments_view: converted order_payments table into a view. I did not use this in my PBI dashboard.
- customers_view: converted customers table to this view.
- reviewed_sellers_view: converted sellers table to this view. In my PBI data model, this has a one-to-many relationship with order_reviews_view.
- ordered_sellers_view: same data as reviewed_sellers_view. I created this view to make it have a direct one-to-many relationship with orders_view. I chose to model my data as such to make some of my visualizations render.
- calendars_view: generated a series of dates from 2016-01-01 to 2018-12-31 to create a dates view for my data model and dashboard.

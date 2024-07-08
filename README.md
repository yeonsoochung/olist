This project demonstrates my SQL and Power BI skills, including data modeling and DAX. I apply these skills on Kaggle's Olist dataset, which is real-life data provided by Olist, a Brazilian e-commerce company.

Source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

After creating a new "olist" database in Postgres, the Kaggle dataset's csv files were imported to Postgres as the following tables:

customers: customer data. Note: customer_unique_id represents customers; customer_id is a unique ID attached to the order ID. So, if a customer makes multiple orders, they will have the same customer_unique_id but different customer_id for each order.
geolocation: location information. The zip code prefix column is referenced by the customers and sellers data tables.
order_items: used to get price of each order/transaction.
order_payments: data on payment methods. I did not use this dataset in this project.
orders: data on the orders made. This forms the basis of my fact table.
product_category_name_translation: contains English translations of each product category.
products: data on each product. I used the product_id column as the primary key. I used only the product_category column in this project.
sellers: seller data.


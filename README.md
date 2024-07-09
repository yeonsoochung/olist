# Olist Data Analysis with SQL and Power BI

This project demonstrates my SQL and Power BI (PBI) skills, including SQL transformations and querying; and data modeling and DAX. I apply these skills on Kaggle's Olist dataset, which is a set of real-life data on almost 100,000 transactions provided by Olist, a Brazilian e-commerce company.

Source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

A major assumption I make in this project is that Olist earns revenue from 10% of all order transaction. This is how I define "Revenue" in my PBI dashboard.

The data schema in the Kaggle page has some many-to-many relationships, such as between the geolocation and customers tables, so I transformed the original data to achieve a star schema with only one-to-many relationships. Below is my data model.

![image](https://github.com/yeonsoochung/olist/assets/90481059/dea4d0fb-92f2-46c8-a76c-4af6017113d4)

To create this data model, I imported the original tables into Postgres, and then I applied SQL transformations and queries to create views, which were loaded into PBI.

## Skills

Before I describe the tables and views, I list the functions and techniques applied in this project.

SQL code in olist_scipt.sql:
- View creations
- Inner and left joins
- Aggregate group by & having; and order by function
- Common Table Expressions (CTE's)
- Window function

PBI DAX:

- SUM, AVERAGE, DISTINCTCOUNT
- SUMX, AVERAGEX, RANKX, COUNTX
- CALCULATE, ALL, RELATED, DIVIDE
- DAX measures created are listed in the Measures table in the data schema image above.

## Tables

After creating a new "olist" database in Postgres, the Kaggle csv files were imported to Postgres as the following tables:

- customers: customer data including city/state data. Note: customer_unique_id represents customers; customer_id is a unique ID attached to each order ID. So, if a customer makes multiple orders, they will have the same customer_unique_id but different customer_id for each order.
- geolocation: location information. The zip code prefix column is referenced by the customers and sellers data tables. I found that there are duplicate zip code values with different lat/lng coordinates.
- order_items: used to get price of each order/transaction.
- order_payments: data on payment methods. I did not use this dataset in this project.
- order_reviews: reviews left by customers on their orders; not all orders were reviewed. I focus on the review scores, which takes values {1, 2, 3, 4, 5}, more than the review comments.
- orders: data on the orders made. This forms the basis of my fact table.
- product_category_name_translation: contains English translations of each product category.
- products: data on each product. I used the product_id column as the primary key. I used only the product_category column (elements are in Portuguese) in this project.
- sellers: seller data including city/state data.

## Views

I created the following views with SQL. Some of them are intermediate views used to create views that get loaded into PBI.

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

## Insights
Page 1: Sales-I
This page can answer questions such as:
•	What is the trend of total sales revenue, which is equivalent to 10% of total transactions? The trend of the number of unique sellers on Olist?
•	Which seller states/cities generate the most revenue?
•	What is the trend in revenue from the most profitable product categories?
o	This data can guide advertising and marketing decisions by city. For example, clicking on Sao Paulo in the bar plot for top 10 customer cities updates the products revenue line chart. At the latest date, we can see that health & beauty products are most profitable, so I would recommend Olist to release ads in Sao Paulo featuring health & beauty products along with bed/bath/table and sports products. This can be done for other top cities, and control-clicking multiple customer cities will plot aggregated data in the visuals.
•	Who are the most profitable/active sellers? Clicking on their bar plot columns can provide more details on their revenue over time, types of products sold, and which of the top cities their customers were located.
o	If one of these sellers has a decrease in activity, Olist can consider offering them incentives (e.g., Olist takes a lower percentage of their transactions for a limited time) to encourage more activity.
o	We can see from the updated line charts that some sellers tend to focus on selling a specific category of product. This can also be considered in any special incentives.

Page 2: Sales-II
•	How do the total revenues of the most profitable product types compare in different customer cities? Like in the previous page, temporal trends can be visualized.
•	How do the total revenues generated from all customer cities compare? What are their temporal trends in terms of total revenue, top products’ revenues, and number of unique sellers that sold items to those cities?
•	Which customer states/cities generate the most revenue?
•	Among the customer states or cities that have low revenue, are there any with a high enough population such that they should be targeted with ads and marketing campaigns?

Page 3: Reviews
•	How are sellers’ ratings trending (overall and by region)?
•	Lower ratings will mean customers are less likely to buy from them, resulting in less revenue for Olist. Thus, cities or sellers whose monthly average ratings are declining or underperforming (e.g., less than a score of 4.0) should prompt scrutiny. Perhaps some kind of reward can be offered to the best performing sellers.





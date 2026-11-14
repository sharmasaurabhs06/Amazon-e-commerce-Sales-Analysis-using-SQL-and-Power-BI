/* =====================================================================================================
   PROJECT   : Amazon E-commerce Sales Analysis
   DATABASE  : amazon_ecomm_sales_analysis
   TABLE     : amazon_sales_data
   ===================================================================================================== */

/* =====================================================================================================
   TABLE OF CONTENTS
   -----------------------------------------------------------------------------------------------------
   SECTION 1  : Database Setup
   SECTION 2  : Data Import
   SECTION 3  : Rename Columns
   SECTION 4  : Data Quality Checks
                 4.1  Duplicate Records
                 4.2  Missing and Null Values
                 4.3  Inconsistent Values
   SECTION 5  : Data Type Correction
   SECTION 6  : Created Additional Columns
   SECTION 7  : Business Analysis
                 Q1  Monthly Revenue and Month-over-Month (MoM) Growth
                 Q2  Revenue Contribution by Product Category
                 Q3  Top 3 Products in Each Category
                 Q4  State-wise Sales Performance
                 Q5  Delivery Status by Category and Payment Method
                 Q6  One-time vs Repeat Customers
                 Q7  Ratings by Delivery Status
                 Q8  Price Band Performance
   ===================================================================================================== */



/* =====================================================================================================
   SECTION 1 : DATABASE SETUP
   ===================================================================================================== */

create database amazon_ecomm_sales_analysis;

use amazon_ecomm_sales_analysis; -- Active Databse

/* =====================================================================================================
   SECTION 2 : DATA IMPORT 
   ===================================================================================================== */
   
-- Checks total records:
select count(*) from amazon_sales_data;

-- Preview Data:
select * from amazon_sales_data;



/* =====================================================================================================
   SECTION 3 : RENAME COLUMN 
   ===================================================================================================== */

alter table amazon_sales_data
	rename column Order_ID to order_id,
	rename column Date to order_date,
	rename column Customer_ID to customer_id,
	rename column Product_Category to product_category,
	rename column Product_Name to product_name,
	rename column Quantity to quantity,
	rename column Unit_Price_INR to unit_price_rs,
	rename column Total_Sales_INR to total_sales_rs,
	rename column Payment_Method to payment_method,
	rename column Delivery_Status to delivery_status,
	rename column Review_Rating to review_rating,
	rename column Review_Text to review_text,
	rename column State to state,
	rename column Country to country;

-- Confirm the new column names.
select * from amazon_sales_data;



/* =====================================================================================================
   SECTION 4 : DATA QUALITY CHECKS
   ===================================================================================================== */

-- Checking the duplicate records:
select order_id, count(*) as c
from amazon_sales_data
group by order_id
having c > 1;

-- Describe data:
desc amazon_sales_data;

-- Checking Missing/Null values:

select
	sum(order_id = '' or order_id is null) as missing_order_id,
	sum(order_date is null) as missing_order_date,
	sum(customer_id = '' or customer_id is null) as missing_customer_id,
	sum(product_category = '' or product_category is null) as missing_product_category,
	sum(product_name = '' or product_name is null) as missing_product_name,
	sum(quantity is null) as missing_quantity,
	sum(unit_price_rs is null) as missing_unit_price,
	sum(total_sales_rs is null) as missing_total_sales,
	sum(payment_method = '' or payment_method is null) as missing_payment_method,
	sum(delivery_status = '' or delivery_status is null) as missing_delivery_status,
	sum(review_rating is null) as missing_review_rating,
	sum(review_text = '' or review_text is null) as missing_review_text,
	sum(state = '' or state is null) as missing_state,
	sum(country = '' or country is null) as missing_country
from amazon_sales_data;

-- Checking inconsistent values:

select distinct product_category from amazon_sales_data;
select distinct product_name from amazon_sales_data;
select distinct quantity from amazon_sales_data;
select distinct payment_method from amazon_sales_data;
select distinct delivery_status from amazon_sales_data;
select distinct review_rating from amazon_sales_data;
select distinct state from amazon_sales_data order by state;



/* =====================================================================================================
   SECTION 5 : DATA TYPE CORRECTION
   ===================================================================================================== */

-- Review the current data types.
desc amazon_sales_data;

-- Convert the date values to the standard YYYY-MM-DD format.
update amazon_sales_data
	set order_date = str_to_date(order_date, "%Y-%m-%d");

-- Assign the correct data type to each column.
alter table amazon_sales_data
	modify column order_id varchar(50),
	modify column customer_id varchar(50),
	modify column product_category varchar(100),
	modify column product_name varchar(200),
	modify column quantity int,
	modify column unit_price_rs decimal(10,2),
	modify column total_sales_rs decimal(12,2),
	modify column payment_method varchar(50),
	modify column delivery_status varchar(50),
	modify column review_rating tinyint,
	modify column review_text text,
	modify column state varchar(100),
	modify column country varchar(100);


/* =====================================================================================================
   SECTION 6 : CREATED NEW COLUMNS
   ===================================================================================================== */

select * from amazon_sales_data;

-- Add the new columns.
alter table amazon_sales_data
	add column order_year int,
	add column order_month int,
	add column month_name  varchar(20),
	add column day_name varchar(20),
	add column price_band varchar(20),
	add column review_band varchar(20);

-- Fill the date-based columns.
update amazon_sales_data
set
	order_year = year(order_date),
	order_month = month(order_date),
	month_name = monthname(order_date),
	day_name = dayname(order_date);

-- Fill price_band and review_band.
update amazon_sales_data
	set price_band = case
						when unit_price_rs < 10000 then 'under 10k'
						when unit_price_rs < 20000 then '10k-20k'
						when unit_price_rs < 30000 then '20k-30k'
						when unit_price_rs < 40000 then '30k-40k'
						else '40k and above' end,
	review_band = case
						when review_rating >= 4 then 'positive'
						when review_rating = 3  then 'neutral'
						else 'negative' end;



/* =====================================================================================================
   SECTION 7 : BUSINESS ANALYSIS
   ===================================================================================================== */


-- ----------------------------------------------------------------------------------------------------
-- Q1 : What is the monthly revenue, and how does it change compared to the previous month (MoM growth)?
-- ----------------------------------------------------------------------------------------------------

with prev_revenue as (
	with monthly_revenue as (
		select date_format(order_date, "%Y-%m") as month_year,
			sum(total_sales_rs) as total_revenue
		from amazon_sales_data
		where delivery_status not in ("Returned", "Pending")
		group by date_format(order_date, "%Y-%m")
		order by month_year asc)

	select *,
		lag(total_revenue) over(order by month_year) as prev_month_revuenue
	from monthly_revenue)

select *,
	round(((total_revenue - prev_month_revuenue) / prev_month_revuenue) * 100, 2) as MoM_growth_pct
from prev_revenue;


-- ----------------------------------------------------------------------------------------------------
-- Q2 : How much does each product category contribute to the total revenue?
-- ----------------------------------------------------------------------------------------------------

select product_category,
	sum(total_sales_rs) as revenue
from amazon_sales_data
where delivery_status not in ("Returned", "Pending")
group by product_category
order by revenue desc;


-- ----------------------------------------------------------------------------------------------------
-- Q3 : What are the top 3 best-selling products (by revenue) in each category?
-- ----------------------------------------------------------------------------------------------------

select * from (
	select product_category, product_name,
		sum(total_sales_rs) as revenue,
		rank() over(partition by product_category order by sum(total_sales_rs) desc) as rk
	from amazon_sales_data
	where delivery_status not in ("Returned", "Pending")
	group by product_category, product_name) as result
where rk <= 3;


-- ----------------------------------------------------------------------------------------------------
-- Q4 : Which states bring in the most revenue and orders, and what is their average review rating?
-- ----------------------------------------------------------------------------------------------------

select state,
	sum(total_sales_rs) as revenue,
	count(*) as total_orders,
	round(avg(review_rating), 2) as avg_rating
from amazon_sales_data
where delivery_status not in ("Returned", "Pending")
group by state
order by revenue desc;


-- ----------------------------------------------------------------------------------------------------
-- Q5 : How are delivered, pending and returned orders spread across
--      product categories and payment methods?
-- ----------------------------------------------------------------------------------------------------

select product_category, payment_method,
	count(*) as total_orders,
	sum(delivery_status = "Delivered") as delivered_orders,
	sum(delivery_status = "Pending") as pending_orders,
	sum(delivery_status = "Returned") as returned_orders
from amazon_sales_data
group by product_category, payment_method;


-- ----------------------------------------------------------------------------------------------------
-- Q6 : How many customers bought only once, and how many came back to buy again?
-- ----------------------------------------------------------------------------------------------------

with result as (
	select customer_id,
		count(distinct order_id) as total_orders,
		sum(total_sales_rs) as lifetime_value,
		min(order_date) as first_order,
		max(order_date) as last_order
	from amazon_sales_data
	where delivery_status not in ("Returned", "Pending")
	group by customer_id
)
select *,
	case
		when total_orders = 1 then "One Time"
		else "Repeat" end as status
from result;


-- ----------------------------------------------------------------------------------------------------
-- Q7 : Do customers give different ratings depending on the delivery status of their order?
-- ----------------------------------------------------------------------------------------------------

select delivery_status,
	count(review_rating) as orders_rating,
	round(avg(review_rating), 2) as avg_rating
from amazon_sales_data
group by delivery_status;


-- ----------------------------------------------------------------------------------------------------
-- Q8 : Which price bands sell the most units, earn the most revenue and get the best ratings?
-- ----------------------------------------------------------------------------------------------------

select price_band,
	sum(total_sales_rs) as revenue,
	sum(quantity) as total_quantity,
	round(avg(review_rating), 2) as avg_rating
from amazon_sales_data
where delivery_status not in ("Returned", "Pending")
group by price_band
order by total_quantity desc;


/* =====================================================================================================
   END OF FILE
   ===================================================================================================== */

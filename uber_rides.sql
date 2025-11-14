-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Uber Ride Analytics & Insights 

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Executive Summary
-- MAGIC
-- MAGIC This project analyzes ride-booking data from an NCR Uber-style mobility service. Using Databricks Free Edition, I built a fully SQL-based data pipeline that cleans, transforms, and analyzes ride activity to uncover insights about customer demand, ride characteristics, operational bottlenecks, and revenue trends.
-- MAGIC
-- MAGIC The end result is a clean, analytics-ready dataset, a set of business KPIs, and interactive dashboards that can support real-world decision-making for a transportation operator.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##  Step 1: Data Loading & Table Creation

-- COMMAND ----------

SELECT * FROM `workspace`.`default`.`uber_rides_dataset` LIMIT 5;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Step 2: Data Cleaning & Transformation

-- COMMAND ----------


DESCRIBE uber_rides_dataset;

-- check the first 3 lists from the table
SELECT * FROM uber_rides_dataset LIMIT 3;

-- COMMAND ----------

-- create a clean dataset named cleaned_uber_rides
CREATE OR REPLACE TEMPORARY VIEW cleaned_uber_rides AS
SELECT 
  -- heck null values
  CASE 
    WHEN `Booking ID` IS NULL OR `Booking ID` = 'null' OR TRIM(`Booking ID`) = ''
    THEN CONCAT('MISSING_', UUID())
    ELSE TRIM(REPLACE(REPLACE(`Booking ID`, '"', ''), '""', ''))
  END as Booking_ID,
  
  CASE 
    WHEN `Customer ID` IS NULL OR `Customer ID` = 'null' OR TRIM(`Customer ID`) = ''
    THEN CONCAT('UNKNOWN_CUST_', UUID())
    ELSE TRIM(REPLACE(REPLACE(`Customer ID`, '"', ''), '""', ''))
  END as Customer_ID,
  
  -- check date and time
  `Date`,
  CASE 
    WHEN `Time` LIKE '2025-%' THEN NULL  -- the dataset is for 2024, so 2025 is not correct
    ELSE `Time`
  END as Time,
  
  -- check the booking status
  CASE 
    WHEN `Booking Status` IS NULL OR `Booking Status` = 'null' OR TRIM(`Booking Status`) = ''
    THEN 'UNKNOWN'
    ELSE TRIM(`Booking Status`)
  END as Booking_Status,
  
  -- car type
  CASE 
    WHEN `Vehicle Type` IS NULL OR `Vehicle Type` = 'null' OR TRIM(`Vehicle Type`) = ''
    THEN 'UNKNOWN'
    ELSE TRIM(`Vehicle Type`)
  END as Vehicle_Type,
  
  -- location
  CASE 
    WHEN `Pickup Location` IS NULL OR `Pickup Location` = 'null' OR TRIM(`Pickup Location`) = ''
    THEN 'UNKNOWN_LOCATION'
    ELSE TRIM(`Pickup Location`)
  END as Pickup_Location,
  
  CASE 
    WHEN `Drop Location` IS NULL OR `Drop Location` = 'null' OR TRIM(`Drop Location`) = ''
    THEN 'UNKNOWN_LOCATION'
    ELSE TRIM(`Drop Location`)
  END as Drop_Location,
  
  --check null for Avg VTAT, CTAT
  CASE 
    WHEN `Avg VTAT` IS NULL OR `Avg VTAT` = 'null' OR TRIM(`Avg VTAT`) = '' THEN NULL
    WHEN TRY_CAST(`Avg VTAT` AS DOUBLE) < 0 OR TRY_CAST(`Avg VTAT` AS DOUBLE) > 60 THEN NULL
    ELSE ROUND(TRY_CAST(`Avg VTAT` AS DOUBLE), 1)
  END as Avg_VTAT,
  
  CASE 
    WHEN `Avg CTAT` IS NULL OR `Avg CTAT` = 'null' OR TRIM(`Avg CTAT`) = '' THEN NULL
    WHEN TRY_CAST(`Avg CTAT` AS DOUBLE) < 0 OR TRY_CAST(`Avg CTAT` AS DOUBLE) > 60 THEN NULL
    ELSE ROUND(TRY_CAST(`Avg CTAT` AS DOUBLE), 1)
  END as Avg_CTAT,
  
  -- check cancelled rides by customer and driver
  CASE 
    WHEN `Cancelled Rides by Customer` IS NULL OR `Cancelled Rides by Customer` = 'null' THEN 0
    ELSE TRY_CAST(`Cancelled Rides by Customer` AS INT)
  END as Cancelled_Rides_by_Customer,
  
  CASE 
    WHEN `Cancelled Rides by Driver` IS NULL OR `Cancelled Rides by Driver` = 'null' THEN 0
    ELSE TRY_CAST(`Cancelled Rides by Driver` AS INT)
  END as Cancelled_Rides_by_Driver,
  
  CASE 
    WHEN `Incomplete Rides` IS NULL OR `Incomplete Rides` = 'null' THEN 0
    ELSE TRY_CAST(`Incomplete Rides` AS INT)
  END as Incomplete_Rides,
  
  --check the reason for cancelling by customer and driver
  CASE 
    WHEN `Reason for cancelling by Customer` IS NULL OR `Reason for cancelling by Customer` = 'null' OR TRIM(`Reason for cancelling by Customer`) = ''
    THEN 'NO_REASON_PROVIDED'
    ELSE TRIM(`Reason for cancelling by Customer`)
  END as Reason_for_cancelling_by_Customer,
  
  CASE 
    WHEN `Driver Cancellation Reason` IS NULL OR `Driver Cancellation Reason` = 'null' OR TRIM(`Driver Cancellation Reason`) = ''
    THEN 'NO_REASON_PROVIDED'
    ELSE TRIM(`Driver Cancellation Reason`)
  END as Driver_Cancellation_Reason,
  
  CASE 
    WHEN `Incomplete Rides Reason` IS NULL OR `Incomplete Rides Reason` = 'null' OR TRIM(`Incomplete Rides Reason`) = ''
    THEN 'NO_REASON_PROVIDED'
    ELSE TRIM(`Incomplete Rides Reason`)
  END as Incomplete_Rides_Reason,
  
  -- check the booking value and ride distance
  CASE 
    WHEN `Booking Value` IS NULL OR `Booking Value` = 'null' OR TRIM(`Booking Value`) = '' THEN NULL
    WHEN TRY_CAST(`Booking Value` AS DOUBLE) < 0 OR TRY_CAST(`Booking Value` AS DOUBLE) > 10000 THEN NULL
    ELSE ROUND(TRY_CAST(`Booking Value` AS DOUBLE), 2)
  END as Booking_Value,
  
  CASE 
    WHEN `Ride Distance` IS NULL OR `Ride Distance` = 'null' OR TRIM(`Ride Distance`) = '' THEN NULL
    WHEN TRY_CAST(`Ride Distance` AS DOUBLE) < 0 OR TRY_CAST(`Ride Distance` AS DOUBLE) > 200 THEN NULL
    ELSE ROUND(TRY_CAST(`Ride Distance` AS DOUBLE), 2)
  END as Ride_Distance,
  
  -- rating
  CASE 
    WHEN `Driver Ratings` IS NULL OR `Driver Ratings` = 'null' OR TRIM(`Driver Ratings`) = '' THEN NULL
    WHEN TRY_CAST(`Driver Ratings` AS DOUBLE) < 1 OR TRY_CAST(`Driver Ratings` AS DOUBLE) > 5 THEN NULL
    ELSE ROUND(TRY_CAST(`Driver Ratings` AS DOUBLE), 1)
  END as Driver_Ratings,
  
  CASE 
    WHEN `Customer Rating` IS NULL OR `Customer Rating` = 'null' OR TRIM(`Customer Rating`) = '' THEN NULL
    WHEN TRY_CAST(`Customer Rating` AS DOUBLE) < 1 OR TRY_CAST(`Customer Rating` AS DOUBLE) > 5 THEN NULL
    ELSE ROUND(TRY_CAST(`Customer Rating` AS DOUBLE), 1)
  END as Customer_Rating,
  
  -- payment type
  CASE 
    WHEN `Payment Method` IS NULL OR `Payment Method` = 'null' OR TRIM(`Payment Method`) = ''
    THEN 'UNKNOWN'
    ELSE TRIM(`Payment Method`)
  END as Payment_Method

FROM uber_rides_dataset;

-- COMMAND ----------

-- check the data after cleaning
SELECT 
  'The report after cleaning' as report_section,
  '' as metric,
  '' as value

UNION ALL
SELECT 
  'keyword completion',
  'total nuber',
  CAST(COUNT(*) AS STRING)
FROM cleaned_uber_rides

UNION ALL
SELECT 
  'keyword completion',
  'effective Booking_ID',
  CAST(COUNT(Booking_ID) AS STRING)
FROM cleaned_uber_rides

UNION ALL
SELECT 
  'keyword completion',
  'effective Customer_ID',
  CAST(COUNT(Customer_ID) AS STRING)
FROM cleaned_uber_rides

UNION ALL
SELECT 
  'data completion',
  'effective Booking_Value',
  CAST(COUNT(Booking_Value) AS STRING)
FROM cleaned_uber_rides

UNION ALL
SELECT 
  'data completion',
  'effective Ride_Distance',
  CAST(COUNT(Ride_Distance) AS STRING)
FROM cleaned_uber_rides

UNION ALL
SELECT 
  'data completion',
  'effective Customer_Rating',
  CAST(COUNT(Customer_Rating) AS STRING)
FROM cleaned_uber_rides

UNION ALL
SELECT 
  'data completion',
  'effective Driver_Ratings',
  CAST(COUNT(Driver_Ratings) AS STRING)
FROM cleaned_uber_rides;

-- COMMAND ----------

-- compare the dataset before and after cleaning
SELECT 
  'orignal data' as data_type,
  `Booking ID` as booking_id,
  `Booking Value` as booking_value,
  `Ride Distance` as ride_distance,
  `Customer Rating` as customer_rating
FROM uber_rides_dataset 
LIMIT 5;

-- check the data after cleaning
SELECT 
  'after cleaning' as data_type,
  Booking_ID as booking_id,
  CAST(Booking_Value AS STRING) as booking_value,
  CAST(Ride_Distance AS STRING) as ride_distance,
  CAST(Customer_Rating AS STRING) as customer_rating
FROM cleaned_uber_rides 
LIMIT 5;

-- COMMAND ----------


SELECT 
  'total amount' as metric,
  CAST(COUNT(*) AS STRING) as value
FROM cleaned_uber_rides;

SELECT 
  'effective Booking_ID' as metric,
  CAST(COUNT(Booking_ID) AS STRING) as value
FROM cleaned_uber_rides;

SELECT 
  'effective Customer_ID' as metric,
  CAST(COUNT(Customer_ID) AS STRING) as value
FROM cleaned_uber_rides;

SELECT 
  'effective Booking_Value' as metric,
  CAST(COUNT(Booking_Value) AS STRING) as value
FROM cleaned_uber_rides;

SELECT 
  'effective Ride_Distance' as metric,
  CAST(COUNT(Ride_Distance) AS STRING) as value
FROM cleaned_uber_rides;

SELECT 
  'effective Customer_Rating' as metric,
  CAST(COUNT(Customer_Rating) AS STRING) as value
FROM cleaned_uber_rides;

SELECT 
  'effective Driver_Ratings' as metric,
  CAST(COUNT(Driver_Ratings) AS STRING) as value
FROM cleaned_uber_rides;

-- COMMAND ----------

-- check the booing distribution
SELECT 
  Booking_Status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM cleaned_uber_rides
GROUP BY Booking_Status
ORDER BY count DESC;

-- check the vehicle type distribution
SELECT 
  Vehicle_Type,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM cleaned_uber_rides
GROUP BY Vehicle_Type
ORDER BY count DESC;

-- check the payment method distribution
SELECT 
  Payment_Method,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM cleaned_uber_rides
WHERE Payment_Method != 'UNKNOWN'
GROUP BY Payment_Method
ORDER BY count DESC;

-- COMMAND ----------

-- check the booking status distribution
SELECT 
  Booking_Status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_uber_rides), 2) as percentage
FROM cleaned_uber_rides
GROUP BY Booking_Status
ORDER BY count DESC;

-- check the vehicle type distribution
SELECT 
  Vehicle_Type,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_uber_rides), 2) as percentage
FROM cleaned_uber_rides
GROUP BY Vehicle_Type
ORDER BY count DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Step 3:Data Visualization 

-- COMMAND ----------

-- 1.1 Cancellation Rate Visualization
SELECT 
  Booking_Status,
  COUNT(*) as booking_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM cleaned_uber_rides
GROUP BY Booking_Status
ORDER BY booking_count DESC;

-- COMMAND ----------

-- 1.2 Revenue by Vehicle Type Visualization
SELECT 
  Vehicle_Type,
  ROUND(SUM(Booking_Value), 2) as total_revenue,
  COUNT(*) as completed_rides
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed' AND Booking_Value IS NOT NULL
GROUP BY Vehicle_Type
ORDER BY total_revenue DESC;

-- COMMAND ----------

-- 2.1 Monthly Revenue Trend
SELECT 
  SUBSTRING(Date, 1, 7) as month,
  ROUND(SUM(Booking_Value), 2) as monthly_revenue,
  COUNT(*) as ride_count
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed' AND Booking_Value IS NOT NULL
GROUP BY SUBSTRING(Date, 1, 7)
ORDER BY month;

-- COMMAND ----------

-- 2.2 Daily Booking Patterns
SELECT 
  DAYOFWEEK(Date) as day_of_week,
  CASE DAYOFWEEK(Date)
    WHEN 1 THEN 'Sunday'
    WHEN 2 THEN 'Monday'
    WHEN 3 THEN 'Tuesday'
    WHEN 4 THEN 'Wednesday'
    WHEN 5 THEN 'Thursday'
    WHEN 6 THEN 'Friday'
    WHEN 7 THEN 'Saturday'
  END as day_name,
  COUNT(*) as bookings,
  ROUND(AVG(Booking_Value), 2) as avg_revenue
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed'
GROUP BY DAYOFWEEK(Date), 
  CASE DAYOFWEEK(Date)
    WHEN 1 THEN 'Sunday'
    WHEN 2 THEN 'Monday'
    WHEN 3 THEN 'Tuesday'
    WHEN 4 THEN 'Wednesday'
    WHEN 5 THEN 'Thursday'
    WHEN 6 THEN 'Friday'
    WHEN 7 THEN 'Saturday'
  END
ORDER BY day_of_week;

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC import matplotlib.pyplot as plt
-- MAGIC import seaborn as sns
-- MAGIC import pandas as pd
-- MAGIC
-- MAGIC # Load cleaned data into pandas dataframe
-- MAGIC df = spark.sql("SELECT * FROM cleaned_uber_rides")
-- MAGIC pandas_df = df.toPandas()
-- MAGIC
-- MAGIC # Set up the visualization style
-- MAGIC plt.style.use('seaborn-v0_8')
-- MAGIC fig, axes = plt.subplots(2, 2, figsize=(15, 12))
-- MAGIC fig.suptitle('Uber Rides Analytics Dashboard', fontsize=16, fontweight='bold')
-- MAGIC
-- MAGIC # 1. Cancellation Reasons
-- MAGIC cancellation_data = pandas_df[pandas_df['Booking_Status'].str.contains('Cancelled', na=False)]
-- MAGIC if not cancellation_data.empty:
-- MAGIC     cancellation_reasons = cancellation_data['Driver_Cancellation_Reason'].value_counts().head(10)
-- MAGIC     axes[0,0].bar(cancellation_reasons.index, cancellation_reasons.values)
-- MAGIC     axes[0,0].set_title('Top 10 Cancellation Reasons')
-- MAGIC     axes[0,0].tick_params(axis='x', rotation=45)
-- MAGIC
-- MAGIC # 2. Revenue by Vehicle Type
-- MAGIC completed_rides = pandas_df[pandas_df['Booking_Status'] == 'Completed']
-- MAGIC revenue_by_vehicle = completed_rides.groupby('Vehicle_Type')['Booking_Value'].sum().sort_values(ascending=False)
-- MAGIC axes[0,1].bar(revenue_by_vehicle.index, revenue_by_vehicle.values)
-- MAGIC axes[0,1].set_title('Revenue by Vehicle Type')
-- MAGIC axes[0,1].tick_params(axis='x', rotation=45)
-- MAGIC
-- MAGIC # 3. Rating Distribution
-- MAGIC rating_data = completed_rides['Customer_Rating'].dropna()
-- MAGIC axes[1,0].hist(rating_data, bins=10, alpha=0.7, edgecolor='black')
-- MAGIC axes[1,0].set_title('Customer Rating Distribution')
-- MAGIC axes[1,0].set_xlabel('Rating')
-- MAGIC axes[1,0].set_ylabel('Frequency')
-- MAGIC
-- MAGIC # 4. Payment Method Distribution
-- MAGIC payment_dist = pandas_df['Payment_Method'].value_counts()
-- MAGIC axes[1,1].pie(payment_dist.values, labels=payment_dist.index, autopct='%1.1f%%')
-- MAGIC axes[1,1].set_title('Payment Method Distribution')
-- MAGIC
-- MAGIC plt.tight_layout()
-- MAGIC plt.show()

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Step 4:Uber Rides Analysis

-- COMMAND ----------

-- Key Business Metrics Dashboard
SELECT 
  COUNT(*) as total_bookings,
  SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) as completed_rides,
  ROUND(SUM(CASE WHEN Booking_Status = 'Completed' THEN Booking_Value ELSE 0 END), 2) as total_revenue,
  ROUND(AVG(CASE WHEN Booking_Status = 'Completed' THEN Customer_Rating ELSE NULL END), 2) as avg_customer_rating,
  ROUND(SUM(CASE WHEN Booking_Status IN ('Cancelled by Driver', 'Cancelled by Customer') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as cancellation_rate
FROM cleaned_uber_rides;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Key Findings:
-- MAGIC
-- MAGIC Total Bookings: 150000+
-- MAGIC
-- MAGIC Service Completion Rate: ~62%
-- MAGIC
-- MAGIC Average Customer Rating: 4.4/5.0
-- MAGIC
-- MAGIC Overall Cancellation Rate: ~25%

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### 1. Cancellation Rate Analysis

-- COMMAND ----------

-- 1.1 Overall Cancellation Rate Analysis
SELECT 
  Booking_Status,
  COUNT(*) as booking_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM cleaned_uber_rides
GROUP BY Booking_Status
ORDER BY booking_count DESC;

-- 1.2 Driver Cancellation Reasons Analysis
SELECT 
  Driver_Cancellation_Reason,
  COUNT(*) as cancellation_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM cleaned_uber_rides
WHERE Booking_Status = 'Cancelled by Driver'
  AND Driver_Cancellation_Reason != 'NO_REASON_PROVIDED'
GROUP BY Driver_Cancellation_Reason
ORDER BY cancellation_count DESC;

-- 1.3 Customer Cancellation Reasons Analysis
SELECT 
  Reason_for_cancelling_by_Customer,
  COUNT(*) as cancellation_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM cleaned_uber_rides
WHERE Booking_Status = 'Cancelled by Customer'
  AND Reason_for_cancelling_by_Customer != 'NO_REASON_PROVIDED'
GROUP BY Reason_for_cancelling_by_Customer
ORDER BY cancellation_count DESC;

-- 1.4 Cancellation Rate by Vehicle Type
SELECT 
  Vehicle_Type,
  COUNT(*) as total_bookings,
  SUM(CASE WHEN Booking_Status = 'Cancelled by Driver' THEN 1 ELSE 0 END) as driver_cancellations,
  SUM(CASE WHEN Booking_Status = 'Cancelled by Customer' THEN 1 ELSE 0 END) as customer_cancellations,
  SUM(CASE WHEN Booking_Status = 'No Driver Found' THEN 1 ELSE 0 END) as no_driver_found,
  ROUND(SUM(CASE WHEN Booking_Status IN ('Cancelled by Driver', 'Cancelled by Customer', 'No Driver Found') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as overall_cancellation_rate
FROM cleaned_uber_rides
GROUP BY Vehicle_Type
ORDER BY overall_cancellation_rate DESC;

-- COMMAND ----------

SELECT 
  Booking_Status,
  COUNT(*) as booking_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM cleaned_uber_rides
GROUP BY Booking_Status
ORDER BY booking_count DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Findings:
-- MAGIC
-- MAGIC Completed Rides: 62%
-- MAGIC
-- MAGIC Cancelled by Driver: 18%
-- MAGIC
-- MAGIC Cancelled by Customer: 7%
-- MAGIC
-- MAGIC No Driver Found: 7%
-- MAGIC
-- MAGIC 1.2 Primary Cancellation Drivers
-- MAGIC Top Driver Cancellation Reasons:
-- MAGIC
-- MAGIC Personal & Car Related Issues: 32%
-- MAGIC
-- MAGIC Customer Related Issues: 28%
-- MAGIC
-- MAGIC More than Permitted People: 22%
-- MAGIC
-- MAGIC Customer Health Concerns: 18%
-- MAGIC
-- MAGIC Top Customer Cancellation Reasons:
-- MAGIC
-- MAGIC Driver Not Moving Towards Pickup: 45%
-- MAGIC
-- MAGIC Driver Asked to Cancel: 25%
-- MAGIC
-- MAGIC Change of Plans: 15%
-- MAGIC
-- MAGIC AC Not Working: 10%
-- MAGIC
-- MAGIC Wrong Address: 5%

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### 2. Revenue Analysis

-- COMMAND ----------

-- 2.1 Revenue Analysis by Vehicle Type (Completed Rides Only)
SELECT 
  Vehicle_Type,
  COUNT(*) as completed_rides,
  ROUND(AVG(Booking_Value), 2) as avg_booking_value,
  ROUND(SUM(Booking_Value), 2) as total_revenue,
  ROUND(AVG(Ride_Distance), 2) as avg_distance,
  ROUND(SUM(Booking_Value) / SUM(Ride_Distance), 2) as revenue_per_km
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed' 
  AND Booking_Value IS NOT NULL 
  AND Ride_Distance IS NOT NULL
GROUP BY Vehicle_Type
ORDER BY total_revenue DESC;

-- 2.2 Monthly Revenue Trend Analysis
SELECT 
  SUBSTRING(Date, 1, 7) as month,
  COUNT(*) as completed_rides,
  ROUND(SUM(Booking_Value), 2) as monthly_revenue,
  ROUND(AVG(Booking_Value), 2) as avg_ride_value
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed' AND Booking_Value IS NOT NULL
GROUP BY SUBSTRING(Date, 1, 7)
ORDER BY month;

-- 2.3 Payment Method Revenue Analysis
SELECT 
  Payment_Method,
  COUNT(*) as transaction_count,
  ROUND(SUM(Booking_Value), 2) as total_revenue,
  ROUND(AVG(Booking_Value), 2) as avg_transaction_value,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as payment_method_share
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed' AND Booking_Value IS NOT NULL
GROUP BY Payment_Method
ORDER BY total_revenue DESC;

-- 2.4 Peak Hours Revenue Analysis
SELECT 
  CASE 
    WHEN HOUR(Time) BETWEEN 6 AND 9 THEN 'Morning Peak (6-9)'
    WHEN HOUR(Time) BETWEEN 16 AND 19 THEN 'Evening Peak (16-19)'
    WHEN HOUR(Time) BETWEEN 20 AND 23 THEN 'Night (20-23)'
    WHEN HOUR(Time) BETWEEN 0 AND 5 THEN 'Late Night (0-5)'
    ELSE 'Off-Peak'
  END as time_slot,
  COUNT(*) as rides_count,
  ROUND(SUM(Booking_Value), 2) as total_revenue,
  ROUND(AVG(Booking_Value), 2) as avg_ride_value
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed' AND Booking_Value IS NOT NULL
GROUP BY 
  CASE 
    WHEN HOUR(Time) BETWEEN 6 AND 9 THEN 'Morning Peak (6-9)'
    WHEN HOUR(Time) BETWEEN 16 AND 19 THEN 'Evening Peak (16-19)'
    WHEN HOUR(Time) BETWEEN 20 AND 23 THEN 'Night (20-23)'
    WHEN HOUR(Time) BETWEEN 0 AND 5 THEN 'Late Night (0-5)'
    ELSE 'Off-Peak'
  END
ORDER BY total_revenue DESC;

-- COMMAND ----------

SELECT 
  Vehicle_Type,
  ROUND(SUM(Booking_Value), 2) as total_revenue,
  COUNT(*) as completed_rides,
  ROUND(AVG(Booking_Value), 2) as avg_booking_value
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed' AND Booking_Value IS NOT NULL
GROUP BY Vehicle_Type
ORDER BY total_revenue DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Revenue Performance:
-- MAGIC
-- MAGIC Premier Sedan: Highest average fare (₹450-600)
-- MAGIC
-- MAGIC Go Sedan: Balanced volume and value
-- MAGIC
-- MAGIC Auto: High volume, lower average fare
-- MAGIC
-- MAGIC Bike/eBike: Budget segment, short distances
-- MAGIC
-- MAGIC 2.2 Payment Method Analysis
-- MAGIC Current Distribution:
-- MAGIC
-- MAGIC UPI: 45.0% (Market Leader)
-- MAGIC
-- MAGIC Cash: 24.9% (Significant cash preference)
-- MAGIC
-- MAGIC Uber Wallet: 12.0%
-- MAGIC
-- MAGIC Credit Card: 10.0%
-- MAGIC
-- MAGIC Debit Card: 8.1%
-- MAGIC
-- MAGIC Insight: Digital payments dominate, but cash remains significant in certain demographics.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### 3. User Behavior Analysis

-- COMMAND ----------

-- 3.1 Customer Rating Distribution Analysis
SELECT 
  CASE 
    WHEN Customer_Rating >= 4.5 THEN '4.5-5.0 (Excellent)'
    WHEN Customer_Rating >= 4.0 THEN '4.0-4.4 (Good)'
    WHEN Customer_Rating >= 3.5 THEN '3.5-3.9 (Average)'
    WHEN Customer_Rating >= 3.0 THEN '3.0-3.4 (Below Average)'
    ELSE 'Below 3.0 (Poor)'
  END as rating_category,
  COUNT(*) as rating_count,
  ROUND(AVG(Booking_Value), 2) as avg_booking_value,
  ROUND(AVG(Ride_Distance), 2) as avg_distance
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed' AND Customer_Rating IS NOT NULL
GROUP BY 
  CASE 
    WHEN Customer_Rating >= 4.5 THEN '4.5-5.0 (Excellent)'
    WHEN Customer_Rating >= 4.0 THEN '4.0-4.4 (Good)'
    WHEN Customer_Rating >= 3.5 THEN '3.5-3.9 (Average)'
    WHEN Customer_Rating >= 3.0 THEN '3.0-3.4 (Below Average)'
    ELSE 'Below 3.0 (Poor)'
  END
ORDER BY rating_category;

-- 3.2 Wait Time Analysis by Vehicle Type
SELECT 
  Vehicle_Type,
  ROUND(AVG(Avg_VTAT), 2) as avg_vehicle_arrival_time,
  ROUND(AVG(Avg_CTAT), 2) as avg_customer_arrival_time,
  COUNT(*) as completed_rides
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed' 
  AND Avg_VTAT IS NOT NULL 
  AND Avg_CTAT IS NOT NULL
GROUP BY Vehicle_Type
ORDER BY avg_vehicle_arrival_time;

-- 3.3 Frequent User Analysis (Top 20 Users)
SELECT 
  Customer_ID,
  COUNT(*) as total_rides,
  SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) as completed_rides,
  SUM(CASE WHEN Booking_Status = 'Cancelled by Customer' THEN 1 ELSE 0 END) as customer_cancellations,
  ROUND(AVG(CASE WHEN Customer_Rating IS NOT NULL THEN Customer_Rating ELSE NULL END), 2) as avg_rating,
  ROUND(SUM(Booking_Value), 2) as total_spent
FROM cleaned_uber_rides
GROUP BY Customer_ID
HAVING COUNT(*) >= 3  -- Users with at least 3 bookings
ORDER BY total_rides DESC
LIMIT 20;

-- 3.4 User Preference Analysis (Vehicle Type vs Payment Method)
SELECT 
  Vehicle_Type,
  Payment_Method,
  COUNT(*) as preference_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY Vehicle_Type), 2) as percentage
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed'
GROUP BY Vehicle_Type, Payment_Method
ORDER BY Vehicle_Type, preference_count DESC;

-- COMMAND ----------

SELECT 
  CASE 
    WHEN Customer_Rating >= 4.5 THEN '4.5-5.0 (Excellent)'
    WHEN Customer_Rating >= 4.0 THEN '4.0-4.4 (Good)'
    WHEN Customer_Rating >= 3.5 THEN '3.5-3.9 (Average)'
    ELSE 'Below 3.5 (Needs Improvement)'
  END as rating_category,
  COUNT(*) as rating_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed' AND Customer_Rating IS NOT NULL
GROUP BY 1
ORDER BY rating_count DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Service Quality Metrics:
-- MAGIC
-- MAGIC Excellent (4.5+): 50% of ratings
-- MAGIC
-- MAGIC Good (4.0-4.4): 36% of ratings
-- MAGIC
-- MAGIC Average (3.5-3.9): 9.4% of ratings
-- MAGIC
-- MAGIC Needs Improvement (<3.5): 4.5% of ratings

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### 4. Business Intelligence & Insights

-- COMMAND ----------

-- 4.1 Key Business Metrics Dashboard
SELECT 
  -- Overall Metrics
  COUNT(*) as total_bookings,
  SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) as completed_rides,
  SUM(CASE WHEN Booking_Status IN ('Cancelled by Driver', 'Cancelled by Customer') THEN 1 ELSE 0 END) as cancelled_rides,
  
  -- Cancellation Rate
  ROUND(SUM(CASE WHEN Booking_Status IN ('Cancelled by Driver', 'Cancelled by Customer') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as cancellation_rate,
  
  -- Revenue Metrics
  ROUND(SUM(CASE WHEN Booking_Status = 'Completed' THEN Booking_Value ELSE 0 END), 2) as total_revenue,
  ROUND(AVG(CASE WHEN Booking_Status = 'Completed' THEN Booking_Value ELSE NULL END), 2) as avg_ride_value,
  
  -- Rating Metrics
  ROUND(AVG(CASE WHEN Booking_Status = 'Completed' THEN Customer_Rating ELSE NULL END), 2) as avg_customer_rating,
  ROUND(AVG(CASE WHEN Booking_Status = 'Completed' THEN Driver_Ratings ELSE NULL END), 2) as avg_driver_rating
  
FROM cleaned_uber_rides;

-- 4.2 Popular Routes Analysis (Top 15 Routes)
SELECT 
  Pickup_Location,
  Drop_Location,
  COUNT(*) as route_frequency,
  ROUND(AVG(Booking_Value), 2) as avg_fare,
  ROUND(AVG(Ride_Distance), 2) as avg_distance
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed'
GROUP BY Pickup_Location, Drop_Location
HAVING COUNT(*) >= 5  -- Routes with at least 5 completed rides
ORDER BY route_frequency DESC
LIMIT 15;

-- 4.3 Service Quality Analysis by Location
SELECT 
  Pickup_Location,
  COUNT(*) as total_rides,
  ROUND(AVG(Customer_Rating), 2) as avg_customer_rating,
  ROUND(AVG(Booking_Value), 2) as avg_booking_value,
  ROUND(SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as completion_rate
FROM cleaned_uber_rides
WHERE Pickup_Location != 'UNKNOWN_LOCATION'
GROUP BY Pickup_Location
HAVING COUNT(*) >= 10  -- Locations with at least 10 rides
ORDER BY avg_customer_rating DESC
LIMIT 15;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4.1 Top Performing Locations
-- MAGIC High-Value Pickup Zones:
-- MAGIC
-- MAGIC Cyber Hub: Premium rides, high frequency
-- MAGIC
-- MAGIC Connaught Place: Business district, consistent demand
-- MAGIC
-- MAGIC Airport Routes: High-value, predictable patterns
-- MAGIC
-- MAGIC University Areas: Student-friendly pricing tiers
-- MAGIC
-- MAGIC
-- MAGIC 4.2 Network Hub Classification
-- MAGIC
-- MAGIC

-- COMMAND ----------

SELECT 
  hub_category,
  COUNT(*) as hub_count,
  ROUND(AVG(total_revenue), 2) as avg_revenue_per_hub
FROM network_hubs
GROUP BY hub_category
ORDER BY avg_revenue_per_hub DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Hub Performance:
-- MAGIC
-- MAGIC Developing Hubs: 155 locations, ₹270000+ monthly revenue
-- MAGIC
-- MAGIC Emerging Hubs: 21 locations, ₹250000+ monthly revenue
-- MAGIC
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### 5. Advanced Analytics

-- COMMAND ----------

-- 5.1 Customer Lifetime Value (CLV) Analysis
SELECT 
  Customer_ID,
  COUNT(*) as total_rides,
  ROUND(SUM(Booking_Value), 2) as total_spend,
  ROUND(AVG(Booking_Value), 2) as avg_ride_value,
  ROUND(SUM(Booking_Value) / COUNT(*), 2) as clv_per_ride,
  MIN(Date) as first_ride_date,
  MAX(Date) as last_ride_date
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed' AND Booking_Value IS NOT NULL
GROUP BY Customer_ID
HAVING COUNT(*) >= 2  -- Customers with at least 2 completed rides
ORDER BY total_spend DESC
LIMIT 20;

-- 5.2 Driver Performance Analysis
SELECT 
  -- This would require driver_id column, using ratings as proxy
  CASE 
    WHEN Driver_Ratings >= 4.5 THEN 'Top Performers (4.5+)'
    WHEN Driver_Ratings >= 4.0 THEN 'Good Performers (4.0-4.4)'
    WHEN Driver_Ratings >= 3.5 THEN 'Average Performers (3.5-3.9)'
    ELSE 'Needs Improvement (<3.5)'
  END as performance_category,
  COUNT(*) as ride_count,
  ROUND(AVG(Booking_Value), 2) as avg_ride_value,
  ROUND(AVG(Ride_Distance), 2) as avg_ride_distance,
  ROUND(SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as completion_rate
FROM cleaned_uber_rides
WHERE Driver_Ratings IS NOT NULL
GROUP BY 
  CASE 
    WHEN Driver_Ratings >= 4.5 THEN 'Top Performers (4.5+)'
    WHEN Driver_Ratings >= 4.0 THEN 'Good Performers (4.0-4.4)'
    WHEN Driver_Ratings >= 3.5 THEN 'Average Performers (3.5-3.9)'
    ELSE 'Needs Improvement (<3.5)'
  END
ORDER BY performance_category;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Step 5:Intelligent Pattern Recognition Analysis

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### 1. Ride Pattern Clustering Analysis

-- COMMAND ----------

-- Basic customer segmentation using SQL clustering techniques
CREATE OR REPLACE TEMPORARY VIEW ride_patterns AS
SELECT 
  Customer_ID,
  -- Customer behavior features
  COUNT(*) as total_rides,
  AVG(Booking_Value) as avg_spend,
  AVG(Ride_Distance) as avg_distance,
  AVG(Customer_Rating) as avg_rating,
  -- Time pattern features
  AVG(CASE WHEN HOUR(Time) BETWEEN 7 AND 9 THEN 1 ELSE 0 END) as morning_ride_ratio,
  AVG(CASE WHEN HOUR(Time) BETWEEN 17 AND 19 THEN 1 ELSE 0 END) as evening_ride_ratio,
  AVG(CASE WHEN DAYOFWEEK(Date) IN (1,7) THEN 1 ELSE 0 END) as weekend_ride_ratio,
  -- Cancellation behavior
  SUM(CASE WHEN Booking_Status = 'Cancelled by Customer' THEN 1 ELSE 0 END) as customer_cancellations,
  -- Payment preference
  MAX(CASE WHEN Payment_Method = 'UPI' THEN 1 ELSE 0 END) as prefers_upi,
  MAX(CASE WHEN Payment_Method = 'CASH' THEN 1 ELSE 0 END) as prefers_cash,
  -- Vehicle preference
  COUNT(DISTINCT Vehicle_Type) as vehicle_variety_used
FROM cleaned_uber_rides
GROUP BY Customer_ID
HAVING COUNT(*) >= 3;  -- Only customers with 3+ rides

-- Customer segmentation based on behavior patterns
CREATE OR REPLACE TEMPORARY VIEW customer_segments AS
SELECT 
  Customer_ID,
  total_rides,
  avg_spend,
  avg_distance,
  CASE 
    WHEN total_rides >= 10 AND avg_spend > 300 THEN 'Premium Frequent'
    WHEN total_rides >= 10 AND avg_spend <= 300 THEN 'Regular Frequent'
    WHEN total_rides < 10 AND avg_spend > 300 THEN 'Premium Occasional'
    WHEN total_rides < 10 AND avg_spend <= 300 THEN 'Budget Occasional'
    ELSE 'Other'
  END as customer_segment,
  CASE 
    WHEN morning_ride_ratio > 0.6 THEN 'Morning Commuter'
    WHEN evening_ride_ratio > 0.6 THEN 'Evening Commuter'
    WHEN weekend_ride_ratio > 0.6 THEN 'Weekend User'
    ELSE 'Mixed Schedule'
  END as time_pattern
FROM ride_patterns;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### 2. Predictive Pattern Analysis

-- COMMAND ----------

-- Identify patterns that predict ride cancellations
CREATE OR REPLACE TEMPORARY VIEW cancellation_predictors AS
SELECT 
  Vehicle_Type,
  HOUR(Time) as hour_of_day,
  DAYOFWEEK(Date) as day_of_week,
  -- Cancellation rates by segment
  COUNT(*) as total_rides,
  SUM(CASE WHEN Booking_Status = 'Cancelled by Driver' THEN 1 ELSE 0 END) as driver_cancellations,
  SUM(CASE WHEN Booking_Status = 'Cancelled by Customer' THEN 1 ELSE 0 END) as customer_cancellations,
  -- Calculate cancellation probabilities
  ROUND(SUM(CASE WHEN Booking_Status = 'Cancelled by Driver' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as driver_cancel_probability,
  ROUND(SUM(CASE WHEN Booking_Status = 'Cancelled by Customer' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as customer_cancel_probability,
  -- Average wait times
  AVG(Avg_VTAT) as avg_vehicle_wait_time,
  AVG(Avg_CTAT) as avg_customer_wait_time
FROM cleaned_uber_rides
WHERE Avg_VTAT IS NOT NULL AND Avg_CTAT IS NOT NULL
GROUP BY Vehicle_Type, HOUR(Time), DAYOFWEEK(Date)
HAVING COUNT(*) >= 10;  -- Statistical significance threshold

-- High-risk cancellation segments
CREATE OR REPLACE TEMPORARY VIEW high_risk_segments AS
SELECT *
FROM cancellation_predictors
WHERE driver_cancel_probability > 15 OR customer_cancel_probability > 20
ORDER BY (driver_cancel_probability + customer_cancel_probability) DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### 3. Dynamic Performance Metrics

-- COMMAND ----------

-- Real-time operational metrics (simulated with current data)
CREATE OR REPLACE TEMPORARY VIEW operational_dashboard AS
SELECT 
  -- Time-based aggregations
  DATE_FORMAT(Date, 'yyyy-MM-dd') as ride_date,
  HOUR(Time) as hour_of_day,
  -- Key performance indicators
  COUNT(*) as total_bookings,
  SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) as completed_rides,
  SUM(CASE WHEN Booking_Status = 'Cancelled by Driver' THEN 1 ELSE 0 END) as driver_cancellations,
  SUM(CASE WHEN Booking_Status = 'Cancelled by Customer' THEN 1 ELSE 0 END) as customer_cancellations,
  -- Revenue metrics
  SUM(CASE WHEN Booking_Status = 'Completed' THEN Booking_Value ELSE 0 END) as total_revenue,
  AVG(CASE WHEN Booking_Status = 'Completed' THEN Booking_Value ELSE NULL END) as avg_revenue_per_ride,
  -- Efficiency metrics
  AVG(CASE WHEN Booking_Status = 'Completed' THEN Ride_Distance ELSE NULL END) as avg_ride_distance,
  AVG(CASE WHEN Booking_Status = 'Completed' THEN Customer_Rating ELSE NULL END) as avg_customer_rating,
  -- Service level metrics
  ROUND(SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as service_completion_rate,
  ROUND(SUM(CASE WHEN Booking_Status = 'No Driver Found' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as driver_availability_failure_rate
FROM cleaned_uber_rides
GROUP BY DATE_FORMAT(Date, 'yyyy-MM-dd'), HOUR(Time)
ORDER BY ride_date DESC, hour_of_day;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### 4. Network Effect Analysis

-- COMMAND ----------

-- Analyze location-based network effects
CREATE OR REPLACE TEMPORARY VIEW location_network_analysis AS
SELECT 
  Pickup_Location,
  -- Demand metrics
  COUNT(*) as total_pickups,
  COUNT(DISTINCT Customer_ID) as unique_customers,
  -- Supply metrics (using completed rides as proxy for driver availability)
  SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) as successful_pickups,
  SUM(CASE WHEN Booking_Status = 'No Driver Found' THEN 1 ELSE 0 END) as failed_pickups,
  -- Revenue potential
  SUM(CASE WHEN Booking_Status = 'Completed' THEN Booking_Value ELSE 0 END) as total_revenue,
  AVG(CASE WHEN Booking_Status = 'Completed' THEN Booking_Value ELSE NULL END) as avg_revenue_per_ride,
  -- Network density indicators
  COUNT(DISTINCT Drop_Location) as unique_destinations,
  -- Service quality indicators
  AVG(CASE WHEN Booking_Status = 'Completed' THEN Customer_Rating ELSE NULL END) as avg_rating,
  ROUND(SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as success_rate
FROM cleaned_uber_rides
GROUP BY Pickup_Location
HAVING COUNT(*) >= 20  -- Minimum data points for meaningful analysis
ORDER BY total_revenue DESC;

-- Identify high-value network hubs
CREATE OR REPLACE TEMPORARY VIEW network_hubs AS
SELECT 
  Pickup_Location,
  total_pickups,
  unique_customers,
  total_revenue,
  success_rate,
  CASE 
    WHEN total_revenue > 10000 AND success_rate > 80 THEN 'Premium Hub'
    WHEN total_revenue > 5000 AND success_rate > 70 THEN 'Established Hub'
    WHEN total_revenue > 1000 AND success_rate > 60 THEN 'Developing Hub'
    ELSE 'Emerging Hub'
  END as hub_category
FROM location_network_analysis;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### 5. Customer Lifetime Value Analysis

-- COMMAND ----------

-- Calculate Customer Lifetime Value (CLV) using SQL
CREATE OR REPLACE TEMPORARY VIEW customer_lifetime_value AS
SELECT 
  Customer_ID,
  -- Customer engagement metrics
  COUNT(*) as total_rides,
  MIN(Date) as first_ride_date,
  MAX(Date) as last_ride_date,
  -- Monetary value metrics
  SUM(Booking_Value) as total_spend,
  AVG(Booking_Value) as avg_ride_value,
  -- Behavioral metrics
  AVG(Customer_Rating) as avg_rating_given,
  SUM(CASE WHEN Booking_Status = 'Cancelled by Customer' THEN 1 ELSE 0 END) as cancellation_count,
  -- CLV calculation components
  DATEDIFF(MAX(Date), MIN(Date)) as customer_tenure_days,
  COUNT(*) / NULLIF(DATEDIFF(MAX(Date), MIN(Date)), 0) as rides_per_day,
  -- Customer value segmentation
  CASE 
    WHEN SUM(Booking_Value) > 1000 AND COUNT(*) > 5 THEN 'High Value'
    WHEN SUM(Booking_Value) > 500 AND COUNT(*) > 3 THEN 'Medium Value'
    WHEN SUM(Booking_Value) > 100 THEN 'Low Value'
    ELSE 'New Customer'
  END as value_segment
FROM cleaned_uber_rides
WHERE Booking_Status = 'Completed' AND Booking_Value IS NOT NULL
GROUP BY Customer_ID
HAVING COUNT(*) >= 2  -- At least 2 completed rides
ORDER BY total_spend DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### 6. Operational Efficiency Analysis

-- COMMAND ----------

-- Analyze operational efficiency across different dimensions
CREATE OR REPLACE TEMPORARY VIEW operational_efficiency AS
SELECT 
  -- Time dimension
  HOUR(Time) as operation_hour,
  DAYOFWEEK(Date) as operation_day,
  -- Vehicle type dimension
  Vehicle_Type,
  -- Efficiency metrics
  COUNT(*) as total_requests,
  SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) as completed_rides,
  SUM(CASE WHEN Booking_Status = 'No Driver Found' THEN 1 ELSE 0 END) as unmet_demand,
  -- Revenue efficiency
  SUM(CASE WHEN Booking_Status = 'Completed' THEN Booking_Value ELSE 0 END) as generated_revenue,
  SUM(CASE WHEN Booking_Status = 'No Driver Found' THEN Booking_Value ELSE 0 END) as lost_revenue,
  -- Time efficiency
  AVG(Avg_VTAT) as avg_driver_response_time,
  AVG(Avg_CTAT) as avg_customer_wait_time,
  -- Success rates
  ROUND(SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as success_rate,
  ROUND(SUM(CASE WHEN Booking_Status = 'No Driver Found' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as failure_rate,
  -- Revenue per request
  ROUND(SUM(CASE WHEN Booking_Status = 'Completed' THEN Booking_Value ELSE 0 END) / COUNT(*), 2) as revenue_per_request
FROM cleaned_uber_rides
WHERE Avg_VTAT IS NOT NULL AND Avg_CTAT IS NOT NULL
GROUP BY HOUR(Time), DAYOFWEEK(Date), Vehicle_Type
HAVING COUNT(*) >= 5  -- Statistical significance
ORDER BY operation_day, operation_hour, revenue_per_request DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Deep Behavioral Insights
-- MAGIC ### 7. Sequential Pattern Analysis

-- COMMAND ----------

-- Analyze customer ride sequences and patterns
CREATE OR REPLACE TEMPORARY VIEW sequential_analysis AS
WITH customer_sequences AS (
  SELECT 
    Customer_ID,
    Date,
    Time,
    Vehicle_Type,
    Pickup_Location,
    Drop_Location,
    Booking_Value,
    LAG(Vehicle_Type) OVER (PARTITION BY Customer_ID ORDER BY Date, Time) as previous_vehicle_type,
    LAG(Pickup_Location) OVER (PARTITION BY Customer_ID ORDER BY Date, Time) as previous_pickup,
    LAG(Drop_Location) OVER (PARTITION BY Customer_ID ORDER BY Date, Time) as previous_drop,
    LEAD(Vehicle_Type) OVER (PARTITION BY Customer_ID ORDER BY Date, Time) as next_vehicle_type
  FROM cleaned_uber_rides
  WHERE Booking_Status = 'Completed'
)
SELECT 
  -- Pattern analysis
  previous_vehicle_type,
  Vehicle_Type as current_vehicle_type,
  COUNT(*) as pattern_frequency,
  -- Location consistency
  COUNT(DISTINCT Customer_ID) as unique_customers,
  AVG(Booking_Value) as avg_ride_value,
  -- Calculate pattern strength
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY previous_vehicle_type), 2) as pattern_percentage
FROM customer_sequences
WHERE previous_vehicle_type IS NOT NULL
GROUP BY previous_vehicle_type, Vehicle_Type
HAVING COUNT(*) >= 10  -- Meaningful pattern threshold
ORDER BY pattern_frequency DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### 8. Anomaly Detection System

-- COMMAND ----------

-- Statistical anomaly detection using SQL
CREATE OR REPLACE TEMPORARY VIEW anomaly_detection AS
WITH ride_stats AS (
  SELECT 
    Vehicle_Type,
    -- Statistical measures
    AVG(Booking_Value) as avg_booking_value,
    STDDEV(Booking_Value) as std_booking_value,
    AVG(Ride_Distance) as avg_ride_distance,
    STDDEV(Ride_Distance) as std_ride_distance,
    AVG(Avg_VTAT) as avg_wait_time,
    STDDEV(Avg_VTAT) as std_wait_time
  FROM cleaned_uber_rides
  WHERE Booking_Status = 'Completed' 
    AND Booking_Value IS NOT NULL 
    AND Ride_Distance IS NOT NULL
  GROUP BY Vehicle_Type
)
SELECT 
  r.Booking_ID,
  r.Vehicle_Type,
  r.Booking_Value,
  r.Ride_Distance,
  r.Avg_VTAT,
  -- Z-score calculations for anomaly detection
  ABS((r.Booking_Value - s.avg_booking_value) / NULLIF(s.std_booking_value, 0)) as booking_value_zscore,
  ABS((r.Ride_Distance - s.avg_ride_distance) / NULLIF(s.std_ride_distance, 0)) as distance_zscore,
  ABS((r.Avg_VTAT - s.avg_wait_time) / NULLIF(s.std_wait_time, 0)) as wait_time_zscore,
  -- Anomaly flags
  CASE WHEN ABS((r.Booking_Value - s.avg_booking_value) / NULLIF(s.std_booking_value, 0)) > 3 THEN 1 ELSE 0 END as price_anomaly,
  CASE WHEN ABS((r.Ride_Distance - s.avg_ride_distance) / NULLIF(s.std_ride_distance, 0)) > 3 THEN 1 ELSE 0 END as distance_anomaly,
  CASE WHEN ABS((r.Avg_VTAT - s.avg_wait_time) / NULLIF(s.std_wait_time, 0)) > 3 THEN 1 ELSE 0 END as wait_time_anomaly
FROM cleaned_uber_rides r
JOIN ride_stats s ON r.Vehicle_Type = s.Vehicle_Type
WHERE r.Booking_Status = 'Completed' 
  AND r.Booking_Value IS NOT NULL 
  AND r.Ride_Distance IS NOT NULL
  AND r.Avg_VTAT IS NOT NULL;

-- Summary of detected anomalies
CREATE OR REPLACE TEMPORARY VIEW anomaly_summary AS
SELECT 
  COUNT(*) as total_rides_analyzed,
  SUM(price_anomaly) as price_anomalies,
  SUM(distance_anomaly) as distance_anomalies,
  SUM(wait_time_anomaly) as wait_time_anomalies,
  ROUND(SUM(price_anomaly + distance_anomaly + wait_time_anomaly) * 100.0 / COUNT(*), 2) as total_anomaly_percentage
FROM anomaly_detection;

-- COMMAND ----------

-- 1.1 Cancellation Rate Pie Chart (Use built-in chart after query)
SELECT 
  Booking_Status,
  COUNT(*) as booking_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM cleaned_uber_rides
GROUP BY Booking_Status
ORDER BY booking_count DESC;
-- VISUALIZATION: Click chart icon → Select 'Pie Chart' → Label: Booking_Status, Value: booking_count

-- 1.2 Cancellation Reasons Bar Chart
SELECT 
  Driver_Cancellation_Reason as cancellation_reason,
  COUNT(*) as cancellation_count
FROM cleaned_uber_rides
WHERE Booking_Status = 'Cancelled by Driver' 
  AND Driver_Cancellation_Reason != 'NO_REASON_PROVIDED'
GROUP BY Driver_Cancellation_Reason
ORDER BY cancellation_count DESC
LIMIT 10;
-- VISUALIZATION: Bar Chart → X-axis: cancellation_reason, Y-axis: cancellation_count

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Strategic Recommendations
-- MAGIC ##  Immediate Actions (0-3 Months)
-- MAGIC ### Reduce Driver Cancellations
-- MAGIC
-- MAGIC Implement driver incentive programs for reliability
-- MAGIC
-- MAGIC Provide maintenance support for "Car Related Issues"
-- MAGIC
-- MAGIC Create rapid response team for driver concerns
-- MAGIC
-- MAGIC ### Optimize Pricing Strategy
-- MAGIC
-- MAGIC Dynamic pricing for Premier Sedan during peak hours
-- MAGIC
-- MAGIC Promotional pricing for underutilized vehicle types
-- MAGIC
-- MAGIC Bundle offers for frequent airport routes
-- MAGIC
-- MAGIC ##  Medium-term Initiatives (3-12 Months)
-- MAGIC ### Customer Experience Enhancement
-- MAGIC
-- MAGIC Improve ETA accuracy to reduce "Driver Not Moving" cancellations
-- MAGIC
-- MAGIC Implement AC quality verification system
-- MAGIC
-- MAGIC Develop loyalty program for frequent riders
-- MAGIC
-- MAGIC ### Operational Excellence
-- MAGIC
-- MAGIC Focus on developing hubs with growth potential
-- MAGIC
-- MAGIC Optimize vehicle mix based on location demand patterns
-- MAGIC
-- MAGIC Implement predictive allocation for high-demand areas
-- MAGIC
-- MAGIC ## Long-term Strategy (12+ Months)
-- MAGIC ### Technology Investment
-- MAGIC
-- MAGIC AI-powered cancellation prediction and prevention
-- MAGIC
-- MAGIC Advanced route optimization algorithms
-- MAGIC
-- MAGIC Real-time supply-demand matching system
-- MAGIC
-- MAGIC ### Market Expansion
-- MAGIC
-- MAGIC Target underserved geographic areas
-- MAGIC
-- MAGIC Develop specialized services for corporate clients
-- MAGIC
-- MAGIC Expand premium vehicle fleet in high-demand zones
-- MAGIC
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Financial Impact Projections
-- MAGIC ###  Revenue Optimization Potential
-- MAGIC Cancellation Reduction: 15-20% revenue increase opportunity
-- MAGIC
-- MAGIC Peak Pricing Optimization: 8-12% yield improvement
-- MAGIC
-- MAGIC Customer Retention: 25% higher lifetime value from loyal customers
-- MAGIC
-- MAGIC ###  Cost Efficiency Opportunities
-- MAGIC Wait Time Reduction: 12% improvement in driver utilization
-- MAGIC
-- MAGIC Route Optimization: 8% reduction in operational costs
-- MAGIC
-- MAGIC Preventive Maintenance: 15% reduction in vehicle-related cancellations

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Future Outlook
-- MAGIC The analysis indicates strong growth potential with targeted interventions. Key success factors include:
-- MAGIC
-- MAGIC Digital Payment Expansion: Further reduce cash dependency
-- MAGIC
-- MAGIC Service Reliability: Focus on consistent quality delivery
-- MAGIC
-- MAGIC Customer Segmentation: Tailored services for different user groups
-- MAGIC
-- MAGIC Technology Integration: Leverage data for predictive optimization

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##  Conclusion
-- MAGIC The Uber NCR operations demonstrate strong market presence with significant optimization opportunities. By addressing cancellation drivers, optimizing pricing strategies, and enhancing operational efficiency, the business can achieve 20-30% revenue growth while improving customer satisfaction metrics.
-- MAGIC
-- MAGIC ### Next Steps:
-- MAGIC
-- MAGIC Implement driver reliability program
-- MAGIC
-- MAGIC Launch dynamic pricing pilot
-- MAGIC
-- MAGIC Develop customer loyalty initiative
-- MAGIC
-- MAGIC Establish continuous monitoring dashboard
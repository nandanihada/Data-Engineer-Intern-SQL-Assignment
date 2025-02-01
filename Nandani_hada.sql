CREATE DATABASE transaction_db;
USE transaction_db;
CREATE TABLE transactions (
    buyer_id INT,
    purchase_time DATETIME,
    refund_item DATETIME NULL,
    store_id VARCHAR(10),
    item_id VARCHAR(10),
    gross_transaction_value DECIMAL(10,2)
);
CREATE TABLE items (
    store_id VARCHAR(10),
    item_id VARCHAR(10),
    item_category VARCHAR(50),
    item_name VARCHAR(50)
);
INSERT INTO transactions (buyer_id, purchase_time, refund_item, store_id, item_id, gross_transaction_value) VALUES
(3, '2019-09-19 21:19:06', NULL, 'a', 'a1', 58),
(12, '2019-12-10 20:10:14', '2019-12-15 23:19:06', 'b', 'b2', 475),
(3, '2020-09-01 23:59:46', '2020-09-02 21:22:06', 'f', 'f9', 33),
(2, '2020-04-30 21:19:06', NULL, 'd', 'd3', 250),
(8, '2020-04-06 21:00:22', NULL, 'f', 'f2', 91),
(5, '2019-03-23 12:09:35', '2019-09-27 02:55:02', 'g', 'g6', 61);

INSERT INTO items (store_id, item_id, item_category, item_name) VALUES
('a', 'a1', 'pants', 'denim pants'),
('a', 'a2', 'tops', 'blouse'),
('f', 'f1', 'table', 'coffee table'),
('f', 'f9', 'chair', 'lounge chair'),
('f', 'f6', 'chair', 'armchair'),
('d', 'd2', 'jewelry', 'bracelet'),
('b', 'b4', 'earphone', 'airpods');

#Running the queris


#_________________
#Question 1: 
#Count of purchases per month (excluding refunds)
SELECT 
    DATE_FORMAT(purchase_time, '%Y-%m') AS purchase_month, 
    COUNT(*) AS purchase_count
FROM transactions
WHERE refund_item IS NULL
GROUP BY purchase_month
ORDER BY purchase_month;
#_________________________________________________
#2. Stores with at least 5 orders in October 2020
SELECT 
    store_id, 
    COUNT(*) AS transaction_count
FROM transactions
WHERE purchase_time BETWEEN '2020-10-01' AND '2020-10-31'
GROUP BY store_id
HAVING COUNT(*) >= 5;
#______________________________________________
#3. Shortest interval (in minutes) from purchase to refund per store

SELECT 
    store_id, 
    MIN(TIMESTAMPDIFF(MINUTE, purchase_time, refund_item)) AS shortest_refund_interval
FROM transactions
WHERE refund_item IS NOT NULL
GROUP BY store_id;
#_____________________________________________________________
#4. Gross transaction value of every store’s first order
WITH first_orders AS (
    SELECT *, 
           RANK() OVER (PARTITION BY store_id ORDER BY purchase_time) AS order_rank
    FROM transactions
)
SELECT store_id, gross_transaction_value
FROM first_orders
WHERE order_rank = 1;
#____________________________________________________________________
#5.Most popular item name for first purchases
WITH first_purchases AS (
    SELECT *, 
           RANK() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS purchase_rank
    FROM transactions
)
SELECT i.item_name, COUNT(*) AS order_count
FROM first_purchases f
JOIN items i ON f.item_id = i.item_id
WHERE f.purchase_rank = 1
GROUP BY i.item_name
ORDER BY order_count DESC
LIMIT 1;
#______________________________________________________
#6. Create a refund processable flag

SELECT *, 
       CASE 
           WHEN refund_item IS NOT NULL 
                AND TIMESTAMPDIFF(HOUR, purchase_time, refund_item) <= 72 
           THEN 'Yes' 
           ELSE 'No' 
       END AS refund_processable
FROM transactions;
#_________________________________________________________________
#7. Rank transactions per buyer and filter only second purchase

WITH ranked_purchases AS (
    SELECT *, 
           RANK() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS purchase_rank
    FROM transactions
    WHERE refund_item IS NULL
)
SELECT * FROM ranked_purchases
WHERE purchase_rank = 2;
#_____________________________________________________________
#8. Find the second transaction time per buyer (without MIN/MAX)

WITH purchase_order AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS purchase_rank
    FROM transactions
)
SELECT buyer_id, purchase_time
FROM purchase_order
WHERE purchase_rank = 2;

#___________________*****END****____________________
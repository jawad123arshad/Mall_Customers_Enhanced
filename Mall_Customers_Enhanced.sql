/* find top ten customer */
SELECT 
    *
FROM
    mall_customers_enhanced
LIMIT 10;
/* Write a SQL query to find all female customers who have a spending score greater than 50. */

SELECT 
    CustomerID, Gender, Age, `Spending Score (1-100)`
FROM
    Mall_Customers_Enhanced
WHERE
    Gender = 'Female'
        AND `Spending Score (1-100)` > 50;
/*Write a SQL query to count the number of customers in each age group*/
SELECT 
    Age, COUNT(*) AS Customer_Count
FROM
    Mall_Customers_Enhanced
GROUP BY Age;
/*Write a SQL query to calculate the average annual income across all customers.*/
SELECT 
    AVG(`Annual Income (k$)`) AS Average_salarly
FROM
    Mall_Customers_Enhanced
/*Write a SQL query to list the top 5 customers with the highest credit scores, including their CustomerID, Age, and Credit Score.*/
SELECT 
    CustomerID, Age, `Credit Score`
FROM
    Mall_Customers_Enhanced
ORDER BY `Credit Score` DESC
LIMIT 5;


/*Write a SQL query to calculate the average spending score for each preferred category*/
SELECT 
    `Preferred Category`,
    AVG(`Spending Score (1-100)`) AS `Avg_Spending_Score`
FROM
    Mall_Customers_Enhanced
GROUP BY `Preferred Category`;

/*Write a SQL query to find customers with an annual income greater than 80k and a spending score less than 30*/
select *
from Mall_Customers_Enhanced
where (`Annual Income (k$)`) > 80 AND (`Spending Score (1-100)`) <30

/*Write a Write a SQL query to find customers with an annual income greater than 80k and a spending score less than 30.*/
SELECT Gender, AVG(`Spending Score (1-100)`) AS Average_Spending
FROM Mall_Customers_Enhanced
GROUP BY Gender;

/*Write a SQL query to find the average loyalty years for male and female customers separately*/

SELECT 
    Gender, AVG(`Loyalty Years`) AS `Loyalty Years`
FROM
    Mall_Customers_Enhanced
GROUP BY Gender;
/*Write a SQL query to list customers with estimated savings greater than 50k, sorted by savings in descending order*/
SELECT 
    CustomerID, (`Estimated Savings (k$)`)
FROM
    Mall_Customers_Enhanced
WHERE
    (`Estimated Savings (k$)`) > 50
ORDER BY (`Estimated Savings (k$)`) DESC;

/*Write a SQL query to categorize customers into segments based on their annual income and spending score:

High Income, High Spending: Income > 80k and Spending Score > 70
High Income, Low Spending: Income > 80k and Spending Score <= 30
Low Income, High Spending: Income <= 30k and Spending Score > 70
Low Income, Low Spending: Income <= 30k and Spending Score <= 30*/
SELECT 
    CustomerID,
    (`Annual Income (k$)`),
    (`Spending Score (1-100)`),
    CASE
        WHEN
            (`Annual Income (k$)`) > 80
                AND (`Spending Score (1-100)`) > 70
        THEN
            'High Income, High Spending'
        WHEN
            (`Annual Income (k$)`) > 80
                AND (`Spending Score (1-100)`) <= 30
        THEN
            'High Income, Low Spending'
        WHEN
            (`Annual Income (k$)`) <= 30
                AND (`Spending Score (1-100)`) > 70
        THEN
            'Low Income, High Spending'
        WHEN
            (`Annual Income (k$)`) <= 30
                AND (`Spending Score (1-100)`) <= 30
        THEN
            'Low Income, Low Spending'
        ELSE 'Other'
    END AS Customer_Segment
FROM
    Mall_Customers_Enhanced;

/*Write a SQL query to calculate the average estimated savings for customers grouped by income ranges (e.g., 0-30k, 31-60k, 61-90k, 91k+)*/
SELECT 
    CASE
        WHEN (`Annual Income (k$)`) <= 30 THEN '0-30k'
        WHEN (`Annual Income (k$)`) <= 60 THEN '31-60k'
        WHEN (`Annual Income (k$)`) <= 90 THEN '61-90k'
        ELSE '90k'
    END AS Income_Range,
    AVG(`Estimated Savings (k$)`) AS Avg_Savings
FROM
    Mall_Customers_Enhanced
GROUP BY Income_Range
ORDER BY Income_Range
/*Write a SQL query to calculate the average credit score for customers grouped by loyalty years, and order by loyalty years.*/

SELECT 
    (`Loyalty Years`), AVG(`Credit Score`) AS Avg_Credit_Score
FROM
    Mall_Customers_Enhanced
GROUP BY (`Loyalty Years`)
ORDER BY (`Loyalty Years`);

/*Complex SQL Queries*/

/*Query 1: Rank Customers by Spending Score Within Each Preferred Category*/
Select CustomerID,`Preferred Category`, `Spending Score (1-100)`,
/*RANK() is a window function that assigns a rank number to each row within a group.*/
/*PARTITION BY Preferred Category → ranks are reset for each category*/
Rank() over(partition by `Preferred Category` Order by `Spending Score (1-100)` DESC )AS `Spending_Rank` 
FROM Mall_Customers_Enhanced
WHERE `Spending Score (1-100)` IS NOT NULL
ORDER BY `Spending Score (1-100)`, Spending_Rank
LIMIT 20;
/*Query 2: Identify High-Income Customers with Low Spending Relative to Their Category*/
WITH CategoryStats AS (
    SELECT 
        `Preferred Category`, 
        AVG(`Annual Income (k$)`) AS Avg_Income, 
        AVG(`Spending Score (1-100)`) AS Avg_Spending
    FROM Mall_Customers_Enhanced
    GROUP BY `Preferred Category`
)
SELECT 
    m.CustomerID, 
    m.`Preferred Category`, 
    m.`Annual Income (k$)`, 
    m.`Spending Score (1-100)`, 
    c.Avg_Income, 
    c.Avg_Spending
FROM Mall_Customers_Enhanced m
JOIN CategoryStats c 
    ON m.`Preferred Category` = c.`Preferred Category`
WHERE 
    m.`Annual Income (k$)` > c.Avg_Income 
    AND m.`Spending Score (1-100)` < c.Avg_Spending
ORDER BY m.`Preferred Category`, m.`Annual Income (k$)`;

/*Query 3: Calculate Running Total of Estimated Savings by Age*/
SELECT 
    CustomerID, 
    Age, 
    `Estimated Savings (k$)`, 
    SUM(`Estimated Savings (k$)`) OVER (ORDER BY Age ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Running_Savings
FROM Mall_Customers_Enhanced
WHERE `Estimated Savings (k$)` IS NOT NULL
ORDER BY Age;

/*Query 4: Detect Outliers in Spending Score Using Z-Scores*/
WITH Stats AS (
    SELECT 
        AVG(`Spending Score (1-100)`) AS Mean_Spending, 
        STDDEV(`Spending Score (1-100)`) AS StdDev_Spending
    FROM Mall_Customers_Enhanced
)
SELECT 
    m.CustomerID, 
    m.`Spending Score (1-100)`, 
    (m.`Spending Score (1-100)` - s.Mean_Spending) / s.StdDev_Spending AS Z_Score
FROM Mall_Customers_Enhanced m
CROSS JOIN Stats s
WHERE 
    ABS((m.`Spending Score (1-100)` - s.Mean_Spending) / s.StdDev_Spending) > 2
ORDER BY Z_Score DESC;

/*Query 5: Segment Customers by Income and Loyalty with Dynamic Buckets*/
SELECT 
    CustomerID,
    `Annual Income (k$)`,
    `Loyalty Years`,
    CASE 
        WHEN `Annual Income (k$)` <= 30 THEN 'Low Income'
        WHEN `Annual Income (k$)` <= 60 THEN 'Medium Income'
        ELSE 'High Income'
    END AS Income_Segment,
    CASE 
        WHEN `Loyalty Years` <= 3 THEN 'Short-Term'
        WHEN `Loyalty Years` <= 6 THEN 'Medium-Term'
        ELSE 'Long-Term'
    END AS Loyalty_Segment,
    COUNT(*) OVER (PARTITION BY 
        CASE 
            WHEN `Annual Income (k$)` <= 30 THEN 'Low Income'
            WHEN `Annual Income (k$)` <= 60 THEN 'Medium Income'
            ELSE 'High Income'
        END,
        CASE 
            WHEN `Loyalty Years` <= 3 THEN 'Short-Term'
            WHEN `Loyalty Years` <= 6 THEN 'Medium-Term'
            ELSE 'Long-Term'
        END
    ) AS Segment_Count
FROM Mall_Customers_Enhanced
ORDER BY `Annual Income (k$)`, `Loyalty Years`;

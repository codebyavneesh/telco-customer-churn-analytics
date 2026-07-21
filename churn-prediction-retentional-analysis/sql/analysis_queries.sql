-- =================
-- Use Database 
-- =================
USE churn_prediction;

-- ================================================================================================================
-- Q(1)- Har contract type ke andar, customers ko TotalCharges ke hisaab se rank karo (top spenders identify karo)
-- ================================================================================================================
SELECT  
    customerID,
    Contract,
    Revenue,
    ROW_NUMBER() OVER(PARTITION BY Contract ORDER BY Revenue DESC) AS top_spenders
FROM
(
    SELECT  
        customerID,
        Contract,
        SUM(TotalCharges) AS Revenue
    FROM billing
    GROUP BY Contract, customerID
) AS t 
ORDER BY top_spenders;

-- =========================================== Insight =================================================================
-- Identified the highest-spending customers within each contract type using ranking functions. This helps the business recognize its most valuable customers in every contract segment and design targeted retention or loyalty strategies.
-- =====================================================================================================================

-- ===================================================================================================================
-- Q(2)- Tenure ke order me chalte hue, churned customers ka cumulative revenue loss (running total of MonthlyCharges) kya hai?
-- ===================================================================================================================
SELECT  
    customerID,
    Churn,
    tenure,
    SUM(MonthlyCharges) OVER(ORDER BY tenure) AS cumulative_revenue_loss
FROM billing
WHERE Churn='Yes';

-- =========================================== Insight ===============================================================
-- Calculated the cumulative monthly revenue loss from churned customers in tenure order. This helps visualize how revenue loss accumulates over the customer lifecycle and identifies the stages where churn has the greatest financial impact.
-- ===================================================================================================================


-- ===============================================================================================
-- Q(3)- Har PaymentMethod segment ke andar, churn ka running count kya hai (tenure ke order me)?
-- ===============================================================================================
SELECT
    PaymentMethod,
    tenure,
    churn,
    COUNT(*) OVER(PARTITION BY PaymentMethod ORDER BY tenure) AS running_count
FROM billing
WHERE churn='Yes'
ORDER BY PaymentMethod, tenure;

-- =========================================== Insight ===============================================================
-- Calculated the running count of churned customers within each payment method based on customer tenure. This analysis helps identify how customer churn accumulates over time across different payment methods and highlights segments requiring focused retention efforts.
-- ===================================================================================================================


-- ===================================================================================================================
-- Q(4)- Har customer ka MonthlyCharges, uske apne Contract-type ke average se kitna zyada/kam hai (window function se group average vs individual row compare karo)?
-- ===================================================================================================================
SELECT
    customerID,
    Contract,
    MonthlyCharges,
    ROUND(AVG(MonthlyCharges) OVER(PARTITION BY Contract), 2) AS contract_avg,
    ROUND(MonthlyCharges - AVG(MonthlyCharges) OVER(PARTITION BY Contract), 2) AS difference
FROM billing;

-- =========================================== Insight ===============================================================
-- Compared each customer's MonthlyCharges with the average MonthlyCharges of their respective contract type. This analysis identifies customers paying above or below the segment average, helping businesses understand pricing variations and customer value within each contract group.
-- ===================================================================================================================


-- =====================================================================================================================
-- Q(5)- Tenure ke basis pe customers ko 4 quartiles me baanto (NTILE use karke) aur har quartile ka churn rate nikaalo
-- =====================================================================================================================
WITH tenure_quartile AS (
    SELECT
        customerID,
        tenure,
        Churn,
        NTILE(4) OVER(ORDER BY tenure) AS quartile
    FROM billing
)
SELECT
    quartile,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS churn_rate
FROM tenure_quartile
GROUP BY quartile
ORDER BY quartile;

-- =========================================== Insight ===============================================================
-- Segmented customers into four tenure-based quartiles using NTILE and calculated the churn rate for each group. This analysis identifies which customer lifecycle stage experiences the highest churn, enabling businesses to implement targeted retention strategies.nt average, helping businesses understand pricing variations and customer value within each contract group.
-- ===================================================================================================================


-- =====================================================================================================================
-- Q(6)- Consecutive tenure buckets (0-12, 13-24, 25-48, 49-72) ke beech churn rate ka difference kya hai (LAG function se previous bucket ke saath compare karo)
-- =====================================================================================================================
WITH tenure_buckets AS (
    SELECT
        customerID,
        churn,
        CASE
            WHEN tenure BETWEEN 0 AND 12 THEN '0-12'
            WHEN tenure BETWEEN 13 AND 24 THEN '13-24'
            WHEN tenure BETWEEN 25 AND 48 THEN '25-48'
            WHEN tenure BETWEEN 49 AND 72 THEN '49-72'
        END AS tenure_bucket
    FROM billing
),
churn_rate AS (
    SELECT
        tenure_bucket,
        ROUND(
            SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*),
            2
        ) AS churn_rate
    FROM tenure_buckets
    GROUP BY tenure_bucket  
)

SELECT
    tenure_bucket,
    churn_rate,
    LAG(churn_rate) OVER (ORDER BY
        CASE tenure_bucket
            WHEN '0-12' THEN 1
            WHEN '13-24' THEN 2
            WHEN '25-48' THEN 3
            WHEN '49-72' THEN 4
        END
    ) AS previous_churn_rate,
    ROUND(
        churn_rate -
        LAG(churn_rate) OVER (
            ORDER BY
            CASE tenure_bucket
                WHEN '0-12' THEN 1
                WHEN '13-24' THEN 2
                WHEN '25-48' THEN 3
                WHEN '49-72' THEN 4
            END
        ),
        2
    ) AS difference_rate
FROM churn_rate;

-- =========================================== Insight ===============================================================
-- Calculated the churn rate for consecutive tenure buckets and compared each bucket with the previous one using the LAG window function. This analysis highlights changes in churn behavior across different customer lifecycle stages, helping businesses identify periods where churn significantly increases or decreases.
-- ===================================================================================================================


-- ===================================================================================================================
-- Q(7)- Kaunse payment methods ka churn rate overall average churn rate se zyada hai? (pehle CTE se per-method churn rate nikaalo, phir usi CTE se average nikaal ke compare karo)
-- ===================================================================================================================
WITH payment_method_churn_rate AS (
    SELECT
        PaymentMethod,
        ROUND(SUM(CASE 
            WHEN churn='Yes' THEN 1
            ELSE 0
        END) * 100.0 / COUNT(*), 2) AS churn_rate
    FROM billing
    GROUP BY PaymentMethod
)
SELECT  
    *
FROM
(
    SELECT  
        PaymentMethod,
        churn_rate,
        ROUND(AVG(churn_rate) OVER(), 2) AS overall_avg_churn_rate
    FROM payment_method_churn_rate
) AS t 
WHERE churn_rate > overall_avg_churn_rate;

-- =========================================== Insight ===============================================================
-- Calculated the churn rate for each payment method and compared it with the overall average churn rate. This analysis identifies payment methods with above-average churn, enabling businesses to prioritize retention efforts and improve the customer payment experience for high-risk segments.
-- ===================================================================================================================


-- ===================================================================================================================
-- Q(8)- High-value customers (TotalCharges top 25%, ek CTE me percentile nikaal ke) ka churn rate, baaki customers se kaise compare hota hai?
-- ===================================================================================================================
WITH high_value_customers AS (
    SELECT
        customerID,
        churn,
        NTILE(4) OVER (ORDER BY TotalCharges DESC) AS customer_rnk
    FROM billing
),
churn_rate AS (
    SELECT
        CASE
            WHEN customer_rnk = 1 THEN 'High Value'
            ELSE 'Others'
        END AS customer_segment,
        ROUND(
            SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
            2
        ) AS customer_churn_rate
    FROM high_value_customers
    GROUP BY customer_segment
)

SELECT
    customer_segment,
    customer_churn_rate
FROM churn_rate;

-- =========================================== Insight ===============================================================
-- Segmented customers into high-value (top 25% by TotalCharges) and remaining customers using a Common Table Expression (CTE), then compared their churn rates. This analysis helps determine whether the company's most valuable customers are at a higher or lower risk of churn, enabling more effective retention planning.
-- ===================================================================================================================


-- =====================================================================================================================
-- Q(9)- Un customers ko dhoondo jinka MonthlyCharges unke apne InternetService-type ke average se zyada hai, lekin phir bhi unka tenure average se kam hai (correlated subquery ya nested CTE se — "high-paying but low-loyalty" segment identify karna)
-- =====================================================================================================================
WITH customer_monthly_charges_internet_services_type AS (
    SELECT
        b1.customerID,
        b1.MonthlyCharges,
        s1.InternetService
    FROM billing b1
    JOIN services s1
        ON b1.customerID = s1.customerID
    WHERE b1.MonthlyCharges > (
        SELECT AVG(b2.MonthlyCharges)
        FROM billing b2
        JOIN services s2
            ON b2.customerID = s2.customerID
        WHERE s2.InternetService = s1.InternetService
    )
),
tenure_average AS (
    SELECT
        customerID,
        tenure
    FROM billing
    WHERE tenure < (
        SELECT AVG(tenure)
        FROM billing
    )
)

SELECT
    cm.customerID,
    cm.MonthlyCharges,
    cm.InternetService,
    ta.tenure
FROM customer_monthly_charges_internet_services_type cm
JOIN tenure_average ta
    ON cm.customerID = ta.customerID
ORDER BY cm.MonthlyCharges DESC;

-- =========================================== Insight ===============================================================
-- Identified customers whose MonthlyCharges exceed the average of their respective Internet Service category while their tenure remains below the overall average. This analysis highlights high-paying but low-loyalty customers, enabling businesses to prioritize early retention efforts before these valuable customers are at risk of churn.
-- ===================================================================================================================


-- =====================================================================================================================
-- Q(10)- Ek CTE banao jo har customer ka "risk score" nikaale (Contract=Month-to-month → +1, no OnlineSecurity → +1, no TechSupport → +1, Fiber optic → +1), phir dekho risk score 3+ wale customers ka actual churn rate kya hai (validate karo ki manual risk scoring model ke feature importance se match karta hai ya nahi)
-- =====================================================================================================================
WITH customer_risk_score AS (
    SELECT  
        b.customerID,
        b.churn,
        (
            CASE 
                WHEN b.Contract='Month-to-month' THEN 1 
                ELSE 0
            END
            +
            CASE 
                WHEN s.OnlineSecurity='No' THEN 1 
                ELSE 0 
            END
            +
            CASE 
                WHEN s.TechSupport='No' THEN 1 
                ELSE 0 
            END
            +
            CASE 
                WHEN s.InternetService='Fiber optic' THEN 1 
                ELSE 0  
            END
        ) AS risk_score
    FROM billing b 
    JOIN customers c 
    ON b.customerID=c.customerID
    JOIN services s 
    ON c.customerID=s.customerID
)
SELECT
    risk_score,
    ROUND(SUM(
        CASE 
            WHEN churn='Yes' THEN 1 
            ELSE 0 
        END
    ) * 100.0 / (COUNT(*)), 2) AS churn_score
FROM customer_risk_score
WHERE risk_score>=3
GROUP BY risk_score;

-- =========================================== Insight ===============================================================
-- Developed a rule-based customer risk score by combining multiple churn indicators and evaluated the actual churn rate of customers with a risk score of 3 or higher. This analysis validates whether the manually designed risk model effectively identifies high-risk customers and aligns with observed churn behavior.
-- ===================================================================================================================


-- =====================================================================================================================
-- Q(11)- "At-risk" segment (Month-to-month + Fiber optic + koi add-on service nahi) ko target kiya jaaye toh kitna % of total churned revenue cover hoga?
-- =====================================================================================================================
WITH customer_segment AS (
    SELECT  
        b.customerID,
        b.churn, 
        b.TotalCharges,
        (
            CASE 
                WHEN 
                    b.Contract='Month-to-month' 
                    AND
                    s.InternetService='Fiber optic'
                    AND
                    s.OnlineSecurity='No'
                    AND
                    s.TechSupport='No'
                    AND
                    s.OnlineBackup = 'No'
                    AND
                    s.DeviceProtection = 'No'
                THEN 'At-risk'
                ELSE 'No risk'
            END
        ) AS segment
    FROM billing b 
    JOIN customers c 
    ON b.customerID=c.customerID
    JOIN services s 
    ON c.customerID=s.customerID
),
total_churn_revenue AS (
    SELECT  
        segment,
        ROUND(churned_total * 100.0 /SUM(churned_total) OVER(), 2) AS cover_churned_total
    FROM 
    (
        SELECT
            segment,
            SUM(
                CASE 
                    WHEN churn='Yes' THEN TotalCharges
                    ELSE 0 
                END
            ) AS churned_total
        FROM customer_segment
        GROUP BY segment 
    ) AS x
)

SELECT
    segment,
    cover_churned_total
FROM total_churn_revenue
WHERE segment='At-risk';

-- =========================================== Insight ===============================================================
-- Measured the share of total churned revenue contributed by customers in the at-risk segment (Month-to-month, Fiber Optic, and no value-added services). This analysis quantifies the potential business impact of focusing retention campaigns on the most vulnerable customer segment.
-- ===================================================================================================================


-- =====================================================================================================================
-- Q(12)- Total MRR (Monthly Recurring Revenue) kitna hai, churned customers ki wajah se kitna already lost ho chuka hai, aur ye lost MRR total ka kitna % hai?
-- =====================================================================================================================
WITH total_mrr AS (
    SELECT
        churn,
        MonthlyCharges,
        SUM(MonthlyCharges) OVER() AS total_mr
    FROM billing
),

churn_mrr AS (
    SELECT
        MAX(total_mr) AS total_mr,
        SUM(
            CASE
                WHEN churn = 'Yes' THEN MonthlyCharges
                ELSE 0
            END
        ) AS churn_mr
    FROM total_mrr
)

SELECT
    total_mr AS total_mrr,
    churn_mr AS lost_mrr,
    ROUND(churn_mr * 100.0 / total_mr, 2) AS lost_mrr_percentage
FROM churn_mrr;

-- =========================================== Insight ===============================================================
-- Calculated the company's total Monthly Recurring Revenue (MRR), the revenue already lost due to churned customers, and the percentage of total MRR represented by lost revenue. This provides a clear view of the financial impact of customer churn and establishes a benchmark for measuring retention performance.
-- ===================================================================================================================


-- =====================================================================================================================
--Q(13)- Agar top 20% highest-risk customers (Q10 ke risk score se) ko retention offer dena ho, toh unka combined MonthlyCharges kitna hai — matlab "agar inme se 30% bhi retain kiye, toh kitna revenue bachega" (potential savings estimate)
-- =====================================================================================================================
WITH customer_risk_score AS (
    SELECT
        b.customerID,
        b.MonthlyCharges,
        (
            CASE
                WHEN b.Contract = 'Month-to-month' THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN s.OnlineSecurity = 'No' THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN s.TechSupport = 'No' THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN s.InternetService = 'Fiber optic' THEN 1
                ELSE 0
            END
        ) AS risk_score
    FROM billing b
    JOIN customers c 
        ON b.customerID = c.customerID
    JOIN services s 
        ON c.customerID=s.customerID
),

top_20_percent_high_risk_customers AS (
    SELECT
        customerID,
        MonthlyCharges,
        risk_score
    FROM (
        SELECT
            customerID,
            MonthlyCharges,
            risk_score,
            NTILE(5) OVER (ORDER BY risk_score DESC) AS risk_group
        FROM customer_risk_score
    ) AS ranked_customers
    WHERE risk_group = 1
),

revenue_at_risk AS (
    SELECT
        SUM(MonthlyCharges) AS total_monthly_charges
    FROM top_20_percent_high_risk_customers
)

SELECT
    total_monthly_charges AS revenue_at_risk,
    ROUND(total_monthly_charges * 0.30, 2) AS potential_revenue_saved
FROM revenue_at_risk;

-- =========================================== Insight ===============================================================
-- Identified the top 20% highest-risk customers using the custom risk score and estimated their combined MonthlyCharges. By assuming a 30% retention success rate, the analysis estimates the potential monthly revenue that could be preserved through targeted retention campaigns, supporting data-driven investment decisions.
-- ===================================================================================================================
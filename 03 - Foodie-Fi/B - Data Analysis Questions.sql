-- 1. How many customers has Foodie-Fi ever had?
SELECT customer_count = COUNT(DISTINCT subs.customer_id)
FROM cs3.subscriptions AS subs;


-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use 
-- the start of the month as the group by value
SELECT
  first_of_month = DATEFROMPARTS(YEAR(subs.start_date), MONTH(subs.start_date), 1),
  cnt_subs = COUNT(*)
FROM cs3.subscriptions AS subs
WHERE subs.plan_id = 0
GROUP BY
  DATEFROMPARTS(YEAR(subs.start_date), MONTH(subs.start_date), 1)
ORDER BY
  DATEFROMPARTS(YEAR(subs.start_date), MONTH(subs.start_date), 1);


-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown 
-- by count of events for each plan_name
SELECT
  plans.plan_name,
  cnt_subs = COUNT(*)
FROM cs3.subscriptions AS subs
LEFT JOIN cs3.plans
  ON subs.plan_id = plans.plan_id
WHERE subs.start_date > DATEFROMPARTS(2020, 12, 31)
GROUP BY plans.plan_name;



-- 4. What is the customer count and percentage of customers who have churned rounded 
-- to 1 decimal place?
SELECT
  cnt_customers = COUNT(DISTINCT subs.customer_id),
  prct_churn_rate = ROUND(
    CAST(COUNT(DISTINCT subs.customer_id) AS DECIMAL(10, 1))
    / (SELECT COUNT(DISTINCT sq.customer_id) FROM cs3.subscriptions AS sq) * 100, 1
  )
FROM cs3.subscriptions AS subs
WHERE subs.plan_id = 4;



-- 5. How many customers have churned straight after their initial free trial - what percentage
-- is this rounded to the nearest whole number?
WITH
previous_plans AS (
  SELECT
    subs.customer_id,
    subs.plan_id,
    prev_plan = LAG(subs.plan_id) OVER (
      PARTITION BY subs.customer_id
      ORDER BY subs.start_date
    )
  FROM cs3.subscriptions AS subs
)

SELECT
  cnt_cancellation_after_trial = COUNT(*),
  prct_cancellation_rate = ROUND(
    CAST(COUNT(DISTINCT pp.customer_id) AS DECIMAL(10, 1))
    / (SELECT COUNT(DISTINCT subs.customer_id) FROM cs3.subscriptions AS subs) * 100, 1
  )
FROM previous_plans AS pp
WHERE pp.plan_id = 4
  AND pp.prev_plan = 0;



-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH
following_plans AS (
  SELECT
    subs.customer_id,
    subs.plan_id,
    plan_after = LEAD(subs.plan_id) OVER (
      PARTITION BY subs.customer_id
      ORDER BY subs.start_date
    )
  FROM cs3.subscriptions AS subs
)

SELECT
  plans.plan_name,
  cnt_plan_after_trial = COUNT(*),
  prct_plan_rate = ROUND(
    CAST(COUNT(DISTINCT fp.customer_id) AS DECIMAL(10, 1))
    / (SELECT COUNT(DISTINCT subs.customer_id) FROM cs3.subscriptions AS subs) * 100, 1
  )
FROM following_plans AS fp
LEFT JOIN cs3.plans
  ON fp.plan_after = plans.plan_id
WHERE fp.plan_id = 0
  AND fp.plan_after <> 4
GROUP BY plans.plan_name;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH plan_order AS (
  SELECT
    *,
    purchase_order = DENSE_RANK() OVER (
      PARTITION BY subs.customer_id
      ORDER BY subs.start_date DESC
    )
  FROM cs3.subscriptions AS subs
  WHERE subs.start_date <= '2020-12-31'
)

SELECT
  plans.plan_name,
  cnt_customers = COUNT(*),
  prct_customers = ROUND(
    CAST(COUNT(*) AS DECIMAL(10, 1))
    / (SELECT COUNT(DISTINCT subs.customer_id) FROM cs3.subscriptions AS subs) * 100, 1
  )
FROM plan_order AS po
LEFT JOIN cs3.plans
  ON po.plan_id = plans.plan_id
WHERE po.purchase_order = 1
GROUP BY plans.plan_name;



-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT cnt_upgrades_to_annual = COUNT(*)
FROM cs3.subscriptions AS subs
WHERE YEAR(subs.start_date) = 2020
  AND subs.plan_id = 3;



-- 9. How many days on average does it take for a customer to an annual plan from the day 
-- they join Foodie-Fi?
WITH join_date AS (
  SELECT
    subs.customer_id,
    trial_date = subs.start_date
  FROM cs3.subscriptions AS subs
  WHERE subs.plan_id = 0
)

SELECT avg_upgrade_duration = AVG(DATEDIFF(DAY, jd.trial_date, subs.start_date))
FROM cs3.subscriptions AS subs
LEFT JOIN join_date AS jd
  ON subs.customer_id = jd.customer_id
WHERE subs.plan_id = 3;


-- 10. Can you further breakdown this average value into 30 day periods
-- (i.e. 0-30 days, 31-60 days etc)
WITH
join_date AS (
  SELECT
    subs.customer_id,
    trial_date = subs.start_date
  FROM cs3.subscriptions AS subs
  WHERE subs.plan_id = 0
),

upgrade_duration AS (
  SELECT
    subs.customer_id,
    duration = AVG(DATEDIFF(DAY, jd.trial_date, subs.start_date))
  FROM cs3.subscriptions AS subs
  LEFT JOIN join_date AS jd
    ON subs.customer_id = jd.customer_id
  WHERE subs.plan_id = 3
  GROUP BY subs.customer_id
)

SELECT
  day_bins = CONCAT(
    (FLOOR(ud.duration / 30) * 30) + 1, ' - ', (FLOOR(ud.duration / 30) + 1) * 30, ' days'
  ),
  cnt_customers = COUNT(*)
FROM upgrade_duration AS ud
GROUP BY FLOOR(ud.duration / 30);



-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH
previous_plan AS (
  SELECT
    *,
    prev_plan_id = LAG(subs.plan_id) OVER (
      PARTITION BY subs.customer_id
      ORDER BY subs.start_date
    )
  FROM cs3.subscriptions AS subs
)

SELECT downgrades = COUNT(DISTINCT pp.customer_id)
FROM previous_plan AS pp
WHERE pp.plan_id = 1
  AND pp.prev_plan_id = 2
  AND YEAR(pp.start_date) = 2020;

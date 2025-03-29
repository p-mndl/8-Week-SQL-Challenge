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



-- 5. How many customers have churned straight after their initial free trial - what percentage
-- is this rounded to the nearest whole number?



-- 6. What is the number and percentage of customer plans after their initial free trial?



-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?



-- 8. How many customers have upgraded to an annual plan in 2020?



-- 9. How many days on average does it take for a customer to an annual plan from the day 
-- they join Foodie-Fi?



-- 10. Can you further breakdown this average value into 30 day periods
-- (i.e. 0-30 days, 31-60 days etc)



-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

-- Based off the 8 sample customers provided in the sample from the subscriptions table, 
-- write a brief description about each customer’s onboarding journey.

-- Try to keep it as short as possible - you may also want to run some sort of join to 
-- make your explanations a bit easier!

-- sample customers = ID 1, 2, 11, 13, 15, 16, 18, 19

SELECT
  subs.customer_id,
  plans.plan_name,
  effective_date = subs.start_date
FROM cs3.subscriptions AS subs
LEFT JOIN cs3.plans
  ON subs.plan_id = plans.plan_id
WHERE subs.customer_id IN (1, 2, 11, 13, 15, 16, 18, 19)
ORDER BY
  subs.customer_id ASC,
  subs.start_date ASC;

-- Customer 1 started with a trial and upgraded to basic monthly
-- Customer 2 started with a tria and upgraded to pro annual
-- Customer 11 started with a trial and cancelled
-- Customer 13 started with a trial, switched to basic monthly and upgraded to pro monthly
-- Customer 15 started with a trial, upgraded to pro monthly and then cancelled
-- Customer 16 started with a trial, went to basic monthly and then upgraded to pro annual
-- Customer 18 started with a trial and then switched to pro monthly
-- Customer 19 started with a trial, switched to pro monthly and then upgraded to pro annual

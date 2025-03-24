-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
    registration_week = DATEPART(WEEK, r.registration_date) 
  , runners_count = COUNT(r.runner_id)
FROM CS2.runners r
GROUP BY DATEPART(WEEK, r.registration_date) ;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT *
FROM CS2.runner_orders;

SELECT
    ro.runner_id
  , avg_pickup_time = AVG(CAST(DATEDIFF(MINUTE, co.order_time, ro.pickup_time) AS FLOAT))
FROM CS2.runner_orders ro
LEFT
  JOIN CS2.customer_orders co
    ON ro.order_id = co.order_id
WHERE ro.pickup_time IS NOT NULL
GROUP BY ro.runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH pizzas AS(
    SELECT
        co.order_id
      , cnt_pizzas = COUNT(co.order_id)
      , prep_time = AVG(CAST(DATEDIFF(MINUTE, co.order_time, ro.pickup_time) AS FLOAT))
    FROM CS2.customer_orders co
    LEFT
      JOIN CS2.runner_orders ro
        ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL
    GROUP BY co.order_id
)
SELECT
    cnt_pizzas
  , avg_prep_time = AVG(prep_time)
  , avg_time_per_pizza = AVG(prep_time) / cnt_pizzas
FROM pizzas
GROUP BY cnt_pizzas
ORDER BY cnt_pizzas DESC;

-- 4. What was the average distance travelled for each customer?
-- 5. What was the difference between the longest and shortest delivery times for all orders?
-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- 7. What is the successful delivery percentage for each runner?
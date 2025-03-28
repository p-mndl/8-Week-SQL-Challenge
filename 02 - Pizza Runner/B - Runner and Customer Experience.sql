-- 1. How many runners signed up for each 1 week period?
-- (i.e. week starts 2021-01-01)
SELECT
  registration_week = DATEPART(WEEK, r.registration_date),
  runners_count = COUNT(r.runner_id)
FROM cs2.runners AS r
GROUP BY DATEPART(WEEK, r.registration_date);

-- 2. What was the average time in minutes it took for each runner to arrive
-- at the Pizza Runner HQ to pickup the order?
WITH unique_orders AS (
  SELECT DISTINCT
    co.order_id,
    co.order_time
  FROM cs2.customer_orders AS co
)

SELECT
  ro.runner_id,
  avg_pickup_time = AVG(
    CAST(
      DATEDIFF(MINUTE, unique_orders.order_time, ro.pickup_time) AS FLOAT
    )
  )
FROM cs2.runner_orders AS ro
LEFT JOIN unique_orders
  ON ro.order_id = unique_orders.order_id
WHERE ro.cancellation IS NULL
GROUP BY ro.runner_id;

-- 3. Is there any relationship between the number of pizzas and how long
-- the order takes to prepare?
WITH pizzas AS (
  SELECT
    co.order_id,
    cnt_pizzas = COUNT(co.order_id),
    prep_time = AVG(
      CAST(DATEDIFF(MINUTE, co.order_time, ro.pickup_time) AS FLOAT)
    )
  FROM cs2.customer_orders AS co
  LEFT JOIN cs2.runner_orders AS ro
    ON co.order_id = ro.order_id
  WHERE ro.cancellation IS NULL
  GROUP BY co.order_id
)

SELECT
  cnt_pizzas,
  avg_prep_time = AVG(prep_time),
  avg_time_per_pizza = AVG(prep_time) / cnt_pizzas
FROM pizzas
GROUP BY cnt_pizzas
ORDER BY cnt_pizzas DESC;

-- 4. What was the average distance travelled for each customer?
WITH unique_orders AS (
  SELECT DISTINCT
    co.order_id,
    co.customer_id
  FROM cs2.customer_orders AS co
)

SELECT
  uo.customer_id,
  avg_distance = AVG(ro.distance)
FROM unique_orders AS uo
LEFT JOIN cs2.runner_orders AS ro
  ON uo.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY uo.customer_id;

-- 5. What was the difference between the longest and shortest delivery times
-- for all orders?
-- simple solution
SELECT
  min_duration = MIN(ro.duration),
  max_duration = MAX(ro.duration),
  dif_duration = MAX(ro.duration) - MIN(ro.duration)
FROM cs2.runner_orders AS ro;

-- first (apparently unnecessarily complicated) solution I came up with
WITH rmin AS (
  SELECT
    duration,
    min_rank = DENSE_RANK() OVER (
      ORDER BY duration ASC
    )
  FROM cs2.runner_orders
  WHERE duration IS NOT NULL
)

SELECT
  min_duration = rmin.duration,
  max_duration = rmax.duration,
  delta = rmax.duration - rmin.duration
-- subquery ranking the duration descendingly
FROM (
  SELECT
    duration,
    max_rank = DENSE_RANK() OVER (
      ORDER BY duration DESC
    )
  FROM cs2.runner_orders
  WHERE duration IS NOT NULL
) AS rmax
-- joining to subquery ranking the duration ascendingly
INNER JOIN rmin
  ON rmax.max_rank = rmin.min_rank
WHERE min_rank = 1;

-- 6. What was the average speed for each runner for each delivery and do you
-- notice any trend for these values?
SELECT
  ro.runner_id,
  ro.order_id,
  ro.duration,
  ro.distance,
  avg_speed = AVG(ro.distance / (CAST(ro.duration AS FLOAT) / 60))
FROM cs2.runner_orders AS ro
WHERE ro.cancellation IS NULL
GROUP BY
  ro.runner_id,
  ro.order_id,
  ro.duration,
  ro.distance
ORDER BY avg_speed DESC;

-- 7. What is the successful delivery percentage for each runner?
SELECT
  ro.runner_id,
  cnt_succesful = COUNT(ro.pickup_time),
  cnt_all = COUNT(*),
  prct_success = CAST(COUNT(ro.pickup_time) AS FLOAT) / COUNT(*)
FROM cs2.runner_orders AS ro
GROUP BY ro.runner_id;

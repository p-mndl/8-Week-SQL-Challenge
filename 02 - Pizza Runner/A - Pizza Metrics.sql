-- How many pizzas were ordered?
SELECT
  COUNT(*) AS pizzas_ordered
FROM CS2.customer_orders;

-- How many unique customer orders were made?
SELECT
  COUNT(DISTINCT order_id) AS unique_orders
FROM CS2.customer_orders;

-- How many successful orders were delivered by each runner?
SELECT
    runner_id
  , COUNT(pickup_time) AS succesful_orders
FROM CS2.runner_orders ro
GROUP BY ro.runner_id;

-- How many of each type of pizza was delivered?
SELECT
    pizza_id
  , COUNT(*) AS delivery_count
FROM CS2.customer_orders co
GROUP BY co.pizza_id;

-- How many Vegetarian and Meatlovers were ordered by each customer?
-- first try through group by
SELECT
    co.customer_id
  , pn.pizza_name
  , COUNT(co.order_id) AS order_count
FROM CS2.customer_orders co
LEFT
  JOIN CS2.pizza_names pn
    ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id, pn.pizza_name;

-- 2nd try with count as two different columns
SELECT
    customer_orders.customer_id
  , cnt_vegetarian =
      COUNT(
        CASE
          WHEN pizza_names.pizza_name = 'Vegetarian'
          THEN 1
          ELSE NULL
        END
      )
  , cnt_meatlover =
      COUNT(
        CASE
          WHEN pizza_names.pizza_name = 'Meatlovers'
          THEN 1
          ELSE NULL
        END
      )
FROM CS2.customer_orders
LEFT
  JOIN CS2.pizza_names
    ON customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY customer_orders.customer_id;

-- What was the maximum number of pizzas delivered in a single order?

WITH pizza_per_order AS(
  SELECT
      co.order_id
    , pizza_count = COUNT(pizza_id)
    , rank_pizza_count = DENSE_RANK() OVER(ORDER BY COUNT(pizza_id) DESC)
  FROM CS2.customer_orders co
  LEFT
    JOIN CS2.runner_orders ro
      ON co.order_id = ro.order_id
  WHERE ro.cancellation IS NULL
  GROUP BY co.order_id
)

SELECT
    order_id
  , pizza_count
FROM pizza_per_order
WHERE rank_pizza_count = 1;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH extras_exclusions AS(
  SELECT
    customer_id
  , order_id
  , changes = 
      CASE
        WHEN exclusions IS NULL AND extras IS NULL THEN NULL
        ELSE CONCAT(exclusions, extras)
      END
  FROM CS2.customer_orders
)

SELECT
    ee.customer_id
  , cnt_changes = COUNT(changes)
  , cnt_no_changes = COUNT(*) - COUNT(changes)
FROM extras_exclusions ee
LEFT
  JOIN CS2.runner_orders ro
    ON ee.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY customer_id
ORDER BY customer_id;

-- How many pizzas were delivered that had both exclusions and extras?
-- komplizierter
WITH extras_exclusions AS(
  SELECT
  order_id
  , changes = 
      CASE
        WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1
        ELSE NULL
      END
  FROM CS2.customer_orders
)

SELECT
    cnt_exclusions_extras = COUNT(ee.changes)
FROM extras_exclusions ee
LEFT
  JOIN CS2.runner_orders ro
    ON ee.order_id = ro.order_id
WHERE ro.cancellation IS NULL;

--einfacher
SELECT
    cnt_exclusions_extras = COUNT(*)
FROM CS2.customer_orders co
LEFT
  JOIN CS2.runner_orders ro
    ON co.order_id = ro.order_id
WHERE
  co.exclusions IS NOT NULL
  AND co.extras IS NOT NULL
  AND ro.cancellation IS NULL;

-- What was the total volume of pizzas ordered for each hour of the day?

SELECT
    hour_of_day = DATEPART(HOUR, co.order_time)
  , cnt_orders = COUNT(*)
FROM CS2.customer_orders co
GROUP BY DATEPART(HOUR, co.order_time);

-- What was the volume of orders for each day of the week?

SELECT
    weekday = DATENAME(WEEKDAY, co.order_time)
  , cnt_orders = COUNT(*)
FROM CS2.customer_orders co
GROUP BY DATENAME(WEEKDAY, co.order_time);

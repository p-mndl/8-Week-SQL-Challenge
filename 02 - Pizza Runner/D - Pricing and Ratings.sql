-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were 
-- no charges for changes -how much money has Pizza Runner made so far if there 
-- are no delivery fees?
SELECT
  pizza_revenue = SUM(
    CASE
      WHEN pn.pizza_name = 'Meatlovers' THEN 12
      WHEN pn.pizza_name = 'Vegetarian' THEN 10
    END
  )
FROM cs2.customer_orders AS co
LEFT JOIN cs2.pizza_names AS pn
  ON co.pizza_id = pn.pizza_id
LEFT JOIN cs2.runner_orders AS ro
  ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL;


-- 2. What if there was an additional $1 charge for any pizza extras?
--     Add cheese is $1 extra
WITH
extra_cost AS (
  SELECT
    co.order_id,
    extra_count = COUNT(ss_extras.value)
  FROM cs2.customer_orders AS co
  CROSS APPLY STRING_SPLIT(co.extras, ',') AS ss_extras
  GROUP BY co.order_id
)

SELECT
  pizza_revenue = SUM(
    CASE
      WHEN pn.pizza_name = 'Meatlovers' THEN 12
      WHEN pn.pizza_name = 'Vegetarian' THEN 10
    END
    + COALESCE(extra_cost.extra_count, 0)
  )
FROM cs2.customer_orders AS co
LEFT JOIN extra_cost
  ON co.order_id = extra_cost.order_id
LEFT JOIN cs2.pizza_names AS pn
  ON co.pizza_id = pn.pizza_id
LEFT JOIN cs2.runner_orders AS ro
  ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL;


-- 3. The Pizza Runner team now wants to add an additional ratings system that
-- allows customers to rate their runner, how would you design an additional
-- table for this new dataset - generate a schema for this new table and insert
-- your own data for ratings for each successful customer order between 1 to 5.
DROP TABLE IF EXISTS cs2.ratings
CREATE TABLE cs2.ratings (
  order_id INTEGER,
  rating INTEGER
);

INSERT INTO cs2.ratings
("order_id", "rating")
VALUES
(1, 3),
(2, 5),
(3, 4),
(4, 1),
(5, 3),
(6, 5),
(7, 4),
(8, 4),
(9, 3),
(10, 2);


-- 4. Using your newly generated table - can you join all of the information
-- together to form a table which has the following information for successful
-- deliveries?
--     customer_id
--     order_id
--     runner_id
--     rating
--     order_time
--     pickup_time
--     Time between order and pickup
--     Delivery duration
--     Average speed
--     Total number of pizzas
SELECT
  co.customer_id,
  co.order_id,
  ro.runner_id,
  ra.rating,
  co.order_time,
  ro.pickup_time,
  prep_time = DATEDIFF(MINUTE, co.order_time, ro.pickup_time),
  delivery_duration = ro.duration,
  avg_speed = AVG(ro.distance / (CAST(ro.duration AS FLOAT) / 60)),
  pizza_count = COUNT(co.pizza_id)
FROM cs2.customer_orders AS co
LEFT JOIN cs2.runner_orders AS ro
  ON co.order_id = ro.order_id
LEFT JOIN cs2.ratings AS ra
  ON co.order_id = ra.order_id
WHERE ro.cancellation IS NULL
GROUP BY
  co.customer_id,
  co.order_id,
  ro.runner_id,
  ra.rating,
  co.order_time,
  ro.pickup_time,
  DATEDIFF(MINUTE, co.order_time, ro.pickup_time),
  ro.duration;


-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no 
-- cost for extras and each runner is paid $0.30 per kilometre traveled - how 
-- much money does Pizza Runner have left over after these deliveries?

WITH
extra_cost AS (
  SELECT
    co.order_id,
    extra_count = COUNT(ss_extras.value)
  FROM cs2.customer_orders AS co
  CROSS APPLY STRING_SPLIT(co.extras, ',') AS ss_extras
  GROUP BY co.order_id
),

runner_expenses AS (
  SELECT
    ro.order_id,
    travel_cost = ro.distance * 2 * 0.3
  FROM cs2.runner_orders AS ro
)

SELECT
  pizza_revenue = SUM(
    CASE
      WHEN pn.pizza_name = 'Meatlovers' THEN 12
      WHEN pn.pizza_name = 'Vegetarian' THEN 10
    END
    + COALESCE(extra_cost.extra_count, 0)
    - COALESCE(re.travel_cost, 0)
  )
FROM cs2.customer_orders AS co
LEFT JOIN extra_cost
  ON co.order_id = extra_cost.order_id
LEFT JOIN cs2.pizza_names AS pn
  ON co.pizza_id = pn.pizza_id
LEFT JOIN cs2.runner_orders AS ro
  ON co.order_id = ro.order_id
LEFT JOIN runner_expenses AS re
  ON co.order_id = re.order_id
WHERE ro.cancellation IS NULL;

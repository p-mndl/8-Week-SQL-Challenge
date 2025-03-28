-- UPDATING CUSTOMER ORDERS

UPDATE cs2.customer_orders
SET
  exclusions = NULL
WHERE
  exclusions = 'null' OR exclusions = '';

UPDATE cs2.customer_orders
SET
  extras = NULL
WHERE
  extras = 'null' OR extras = '';

-- UPDATING RUNNER ORDERS

UPDATE cs2.runner_orders

SET pickup_time = NULL
WHERE pickup_time = 'null';

UPDATE cs2.runner_orders
SET
  distance =
  CASE
    WHEN distance = 'null' THEN NULL
    ELSE RTRIM(REPLACE(distance, 'km', ''))
  END;

ALTER TABLE cs2.runner_orders
ALTER COLUMN distance FLOAT;

UPDATE cs2.runner_orders
SET
  duration =
  CASE
    WHEN duration = 'null' THEN NULL
    ELSE RTRIM(
        REPLACE(
          REPLACE(REPLACE(duration, 'minutes', ''), 'mins', ''),
          'minute',
          ''
        )
      )
  END;

ALTER TABLE cs2.runner_orders
ALTER COLUMN distance INT;

ALTER TABLE cs2.runner_orders
ALTER COLUMN pickup_time DATETIME;

ALTER TABLE cs2.runner_orders
ALTER COLUMN duration INT;

UPDATE cs2.runner_orders
SET cancellation = NULL
WHERE
  cancellation = 'null'
  OR cancellation = '';

ALTER TABLE cs2.pizza_names
ALTER COLUMN pizza_name VARCHAR(10);

ALTER TABLE cs2.pizza_recipes
ALTER COLUMN toppings VARCHAR(25);

ALTER TABLE cs2.pizza_toppings
ALTER COLUMN topping_name VARCHAR(15);

-- UPDATING CUSTOMER ORDERS

UPDATE CS2.customer_orders
SET
  exclusions = NULL
WHERE
  exclusions = 'null' OR exclusions = '';

UPDATE CS2.customer_orders
SET
  extras = NULL
WHERE
  extras = 'null' OR extras = '';

-- UPDATING RUNNER ORDERS

UPDATE CS2.runner_orders

SET pickup_time = NULL
WHERE pickup_time = 'null';

UPDATE CS2.runner_orders
SET distance =
  CASE
    WHEN distance = 'null' THEN NULL
	ELSE RTRIM(REPLACE(distance, 'km', ''))
  END;

ALTER TABLE CS2.runner_orders
ALTER COLUMN distance FLOAT;

UPDATE CS2.runner_orders
SET duration =
  CASE
    WHEN duration = 'null' THEN NULL
	ELSE RTRIM(REPLACE(REPLACE(REPLACE(duration, 'minutes', ''), 'mins', ''), 'minute', ''))
  END;

ALTER TABLE CS2.runner_orders
ALTER COLUMN distance INT;

ALTER TABLE CS2.runner_orders
ALTER COLUMN pickup_time DATETIME;

ALTER TABLE CS2.runner_orders
ALTER COLUMN duration INT;

UPDATE CS2.runner_orders
SET cancellation = NULL
WHERE
  cancellation = 'null'
  OR cancellation = '';



-- 1. What are the standard ingredients for each pizza?
WITH split_toppings AS (
  SELECT
    pr.pizza_id,
    topping_id = TRIM(s.value)
  FROM cs2.pizza_recipes AS pr
  CROSS APPLY STRING_SPLIT(pr.toppings, ',') AS s
)

SELECT
  pn.pizza_name,
  toppings = STRING_AGG(pt.topping_name, ', ')
FROM split_toppings AS st
INNER JOIN cs2.pizza_names AS pn
  ON st.pizza_id = pn.pizza_id
LEFT JOIN cs2.pizza_toppings AS pt
  ON st.topping_id = pt.topping_id
GROUP BY pn.pizza_name;

-- 2. What was the most commonly added extra?
WITH ordered_extras AS (
  SELECT
    co.order_id,
    extras = TRIM(s.value)
  FROM cs2.customer_orders AS co
  CROSS APPLY STRING_SPLIT(co.extras, ',') AS s
)

SELECT
  pt.topping_name,
  cnt_extra = COUNT(oe.extras)
FROM ordered_extras AS oe
INNER JOIN cs2.pizza_toppings AS pt
  ON oe.extras = pt.topping_id
GROUP BY pt.topping_name;

-- 3. What was the most common exclusion?
WITH ordered_exclusions AS (
  SELECT
    co.order_id,
    exclusion = TRIM(s.value)
  FROM cs2.customer_orders AS co
  CROSS APPLY STRING_SPLIT(co.exclusions, ',') AS s
)

SELECT
  pt.topping_name,
  cnt_exclusion = COUNT(pt.topping_name)
FROM ordered_exclusions AS oe
INNER JOIN cs2.pizza_toppings AS pt
  ON oe.exclusion = pt.topping_id
GROUP BY pt.topping_name
ORDER BY pt.topping_name DESC;

-- 4. Generate an order item for each record in the customers_orders table in 
-- the format of one of the following:
--     Meat Lovers
--     Meat Lovers - Exclude Beef
--     Meat Lovers - Extra Bacon
--     Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
WITH
customer_order_indexed AS (
  SELECT
    co.order_id,
    co.pizza_id,
    co.extras,
    co.exclusions,
    item_id = ROW_NUMBER() OVER (
      ORDER BY co.order_id
    )
  FROM cs2.customer_orders AS co
),

ordered_extras AS (
  SELECT
    sq.item_id,
    extras = STRING_AGG(pt.topping_name, ', ')
  FROM (
    SELECT
      co.item_id,
      extras = TRIM(s.value)
    FROM customer_order_indexed AS co
    OUTER APPLY STRING_SPLIT(co.extras, ',') AS s
  ) AS sq
  LEFT JOIN cs2.pizza_toppings AS pt
    ON sq.extras = pt.topping_id
  GROUP BY sq.item_id
),

ordered_exclusions AS (
  SELECT
    sq.item_id,
    exclusions = STRING_AGG(pt.topping_name, ', ')
  FROM (
    SELECT
      co.item_id,
      exclusions = TRIM(s.value)
    FROM customer_order_indexed AS co
    CROSS APPLY STRING_SPLIT(co.exclusions, ',') AS s
  ) AS sq
  LEFT JOIN cs2.pizza_toppings AS pt
    ON sq.exclusions = pt.topping_id
  GROUP BY sq.item_id
)

SELECT
  pizza = pn.pizza_name
  + CASE
    WHEN oextr.extras IS NOT NULL THEN ' - Extra ' + oextr.extras
    ELSE ''
  END
  + CASE
    WHEN oexcl.exclusions IS NOT NULL THEN ' - Exclude ' + oexcl.exclusions
    ELSE ''
  END
FROM customer_order_indexed AS co
LEFT JOIN cs2.pizza_names AS pn
  ON co.pizza_id = pn.pizza_id
LEFT JOIN ordered_extras AS oextr
  ON co.item_id = oextr.item_id
LEFT JOIN ordered_exclusions AS oexcl
  ON co.item_id = oexcl.item_id;

-- 5. Generate an alphabetically ordered comma separated ingredient list for 
-- each pizza order from the customer_orders table and add a 2x in front of 
-- any relevant ingredients
--     For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
WITH
customer_order_indexed AS (
  SELECT
    co.order_id,
    co.pizza_id,
    co.extras,
    co.exclusions,
    pizza_recipe = pr.toppings,
    pn.pizza_name,
    item_id = ROW_NUMBER() OVER (
      ORDER BY co.order_id
    )
  FROM cs2.customer_orders AS co
  LEFT JOIN cs2.pizza_recipes AS pr
    ON co.pizza_id = pr.pizza_id
  LEFT JOIN cs2.pizza_names AS pn
    ON co.pizza_id = pn.pizza_id
),

base_ingredients AS (
  SELECT
    sq.item_id,
    sq.ingredient
  FROM (
    SELECT
      co.item_id,
      ingredient = TRIM(s.value)
    FROM customer_order_indexed AS co
    CROSS APPLY STRING_SPLIT(co.pizza_recipe, ',') AS s
  ) AS sq
),

ordered_extras AS (
  SELECT
    sq.item_id,
    ingredient = sq.extras
  FROM (
    SELECT
      co.item_id,
      extras = TRIM(s.value)
    FROM customer_order_indexed AS co
    CROSS APPLY STRING_SPLIT(co.extras, ',') AS s
  ) AS sq
),

ordered_exclusions AS (
  SELECT
    sq.item_id,
    ingredient = sq.exclusions
  FROM (
    SELECT
      co.item_id,
      exclusions = TRIM(s.value)
    FROM customer_order_indexed AS co
    CROSS APPLY STRING_SPLIT(co.exclusions, ',') AS s
  ) AS sq
),

combined_ingredients AS (
  SELECT
    bi.item_id,
    bi.ingredient
  FROM base_ingredients AS bi
  EXCEPT
  SELECT
    oexcl.item_id,
    oexcl.ingredient
  FROM ordered_exclusions AS oexcl
  UNION ALL
  SELECT
    oextr.item_id,
    oextr.ingredient
  FROM ordered_extras AS oextr
),

ingredients_cumulated AS (
  SELECT
    ci.item_id,
    pt.topping_name,
    cnt_topping = COUNT(pt.topping_name)
  FROM combined_ingredients AS ci
  INNER JOIN cs2.pizza_toppings AS pt
    ON ci.ingredient = pt.topping_id
  GROUP BY ci.item_id, pt.topping_name
),

order_text AS (
  SELECT
    ic.item_id,
    recipe = STRING_AGG(
      coi.pizza_name + ': '
      + CASE
        WHEN ic.cnt_topping >= 2
          THEN CAST(ic.cnt_topping AS VARCHAR) + 'x '
        ELSE ''
      END
      + ic.topping_name, ', '
    )
  FROM ingredients_cumulated AS ic
  INNER JOIN customer_order_indexed AS coi
    ON ic.item_id = coi.item_id
  GROUP BY ic.item_id
)

SELECT recipe
FROM order_text;


-- 6. What is the total quantity of each ingredient used in all delivered pizzas
-- sorted by most frequent first?
WITH
customer_order_indexed AS (
  SELECT
    co.order_id,
    co.pizza_id,
    co.extras,
    co.exclusions,
    pizza_recipe = pr.toppings,
    pn.pizza_name,
    item_id = ROW_NUMBER() OVER (
      ORDER BY co.order_id
    )
  FROM cs2.customer_orders AS co
  LEFT JOIN cs2.pizza_recipes AS pr
    ON co.pizza_id = pr.pizza_id
  LEFT JOIN cs2.pizza_names AS pn
    ON co.pizza_id = pn.pizza_id
),

base_ingredients AS (
  SELECT
    sq.item_id,
    sq.ingredient
  FROM (
    SELECT
      co.item_id,
      ingredient = TRIM(s.value)
    FROM customer_order_indexed AS co
    CROSS APPLY STRING_SPLIT(co.pizza_recipe, ',') AS s
  ) AS sq
),

ordered_extras AS (
  SELECT
    sq.item_id,
    ingredient = sq.extras
  FROM (
    SELECT
      co.item_id,
      extras = TRIM(s.value)
    FROM customer_order_indexed AS co
    CROSS APPLY STRING_SPLIT(co.extras, ',') AS s
  ) AS sq
),

ordered_exclusions AS (
  SELECT
    sq.item_id,
    ingredient = sq.exclusions
  FROM (
    SELECT
      co.item_id,
      exclusions = TRIM(s.value)
    FROM customer_order_indexed AS co
    CROSS APPLY STRING_SPLIT(co.exclusions, ',') AS s
  ) AS sq
),

combined_ingredients AS (
  SELECT
    bi.item_id,
    bi.ingredient
  FROM base_ingredients AS bi
  EXCEPT
  SELECT
    oexcl.item_id,
    oexcl.ingredient
  FROM ordered_exclusions AS oexcl
  UNION ALL
  SELECT
    oextr.item_id,
    oextr.ingredient
  FROM ordered_extras AS oextr
)

SELECT
  pt.topping_name,
  cnt_topping = COUNT(pt.topping_name)
FROM combined_ingredients AS ci
INNER JOIN cs2.pizza_toppings AS pt
  ON ci.ingredient = pt.topping_id
GROUP BY pt.topping_name
ORDER BY COUNT(pt.topping_name) DESC;

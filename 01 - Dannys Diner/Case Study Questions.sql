-- 3. What was the first item from the menu purchased by each customer?
WITH ranked_orders AS (
  SELECT
    s.customer_id,
    men.product_name,
    DENSE_RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY s.order_date
    ) AS order_rank
  FROM dannys_diner.sales AS s
  INNER JOIN dannys_diner.menu AS men
    ON s.product_id = men.product_id
)

SELECT DISTINCT
  customer_id,
  product_name
FROM ranked_orders
WHERE order_rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it
-- purchased by all customers?
SELECT TOP 1
  men.product_name,
  COUNT(s.product_id) AS purchase_count
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS men
  ON s.product_id = men.product_id
GROUP BY men.product_name
ORDER BY purchase_count DESC;

-- 5. Which item was the most popular for each customer?
WITH order_count AS (
  SELECT
    s.customer_id,
    men.product_name,
    COUNT(s.product_id) AS purchase_count,
    DENSE_RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY COUNT(s.product_id)
    ) AS rank
  FROM dannys_diner.sales AS s
  INNER JOIN dannys_diner.menu AS men
    ON s.product_id = men.product_id
  GROUP BY 1, 2
)

SELECT
  customer_id,
  product_name,
  purchase_count
FROM order_count
WHERE rank = 1;


-- 6. Which item was purchased first by the customer after they became a member?

WITH ranked_sales_membership AS (
  SELECT
    sales.customer_id,
    menu.product_name,
    DENSE_RANK() OVER (
      PARTITION BY sales.customer_id
      ORDER BY sales.order_date
    ) AS order_rank
  FROM dannys_diner.sales
  INNER JOIN dannys_diner.members
    ON sales.customer_id = members.customer_id
  INNER JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
  WHERE sales.order_date >= members.join_date
)

SELECT
  ranked_sales_membership.customer_id,
  ranked_sales_membership.product_name
FROM ranked_sales_membership
WHERE ranked_sales_membership.order_rank = 1;

-- 6 alternative

SELECT
  s.customer_id,
  men.product_name
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS men
  ON s.product_id = men.product_id
INNER JOIN dannys_diner.members AS mem
  ON s.customer_id = mem.customer_id
WHERE
  s.order_date >= mem.join_date
  AND s.order_date = (
    SELECT MIN(s.order_date)
    FROM dannys_diner.sales
    WHERE
      mem.customer_id = s.customer_id
      AND s.order_date >= mem.join_date
  );

-- 7. Which item was purchased just before the customer became a member?
-- Solution 1
WITH sales_before_membership AS (
  SELECT
    s.customer_id,
    men.product_name,
    DENSE_RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY s.order_date DESC
    ) AS order_rank
  FROM dannys_diner.sales AS s
  INNER JOIN dannys_diner.members AS mem
    ON s.customer_id = mem.customer_id
  INNER JOIN dannys_diner.menu AS men
    ON s.product_id = men.product_id
  WHERE s.order_date < mem.join_date
)

SELECT
  customer_id,
  product_name
FROM sales_before_membership
WHERE
  order_rank = 1;

-- Solution 2
SELECT
  s.customer_id,
  men.product_name
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS men
  ON s.product_id = men.product_id
INNER JOIN dannys_diner.members AS mem
  ON s.customer_id = mem.customer_id
WHERE
  s.order_date < mem.join_date
  AND s.order_date = (
    SELECT MAX(order_date)
    FROM dannys_diner.sales
    WHERE
      order_date < mem.join_date
      AND customer_id = mem.customer_id
  );

-- 8. What is the total items and amount spent for each member before they
-- became a member?
SELECT
  s.customer_id,
  SUM(men.price) AS money_spent,
  COUNT(s.product_id) AS items_purchased
FROM dannys_diner.sales AS s
INNER
JOIN dannys_diner.menu AS men
  ON s.product_id = men.product_id
INNER
JOIN dannys_diner.members AS mem
  ON s.customer_id = mem.customer_id
WHERE
  s.order_date < mem.join_date
GROUP BY 1;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points
-- multiplier - how many points would each customer have?
WITH point_table AS (
  SELECT
    men.product_id,
    CASE
      WHEN men.product_name = 'sushi' THEN men.price * 10 * 2
      ELSE men.price * 10
    END AS points
  FROM dannys_diner.menu AS men
)

SELECT
  s.customer_id,
  SUM(pt.points) AS total_points
FROM dannys_diner.sales AS s
INNER
JOIN point_table AS pt
  ON s.product_id = pt.product_id
GROUP BY 1
ORDER BY 1;

-- 10. In the first week after a customer joins the program (including their
-- join date) they earn 2x points on all items, not just sushi - how many
-- points do customer A and B have at the end of January?
SELECT
  s.customer_id,
  SUM(CASE
    WHEN
      (s.order_date BETWEEN mem.join_date AND mem.join_date + 6)
      OR s.product_id = 1
      THEN men.price * 10 * 2
    ELSE men.price * 10
  END) AS points
FROM dannys_diner.sales AS s
LEFT
JOIN dannys_diner.members AS mem
  ON s.customer_id = mem.customer_id
INNER
JOIN dannys_diner.menu AS men
  ON s.product_id = men.product_id
WHERE s.order_date <= CAST('2021-01-31' AS DATE)
GROUP BY s.customer_id;

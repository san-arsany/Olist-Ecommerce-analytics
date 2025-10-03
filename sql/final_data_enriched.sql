WITH sub1 AS (
  SELECT
    oi.order_id,
    p.product_category AS category,
    SUM(oi.price + oi.freight_value) AS revenue
  FROM `projectperso-472608.Olist_persoproject.order_items` AS oi
  JOIN `projectperso-472608.Olist_persoproject.products` AS p  USING (product_id)
  GROUP BY oi.order_id, category
),

main_cat AS (
  SELECT
    order_id,
    ARRAY_AGG(category ORDER BY revenue DESC LIMIT 1)[OFFSET(0)] AS product_category
  FROM sub1
  GROUP BY order_id
),

order_gmv AS (
  SELECT
    order_id,
    SUM(revenue) AS gmv,
  FROM sub1
  GROUP BY order_id
),

order_gmv_aov AS (
  SELECT 
    order_id,
    gmv,
    SAFE_DIVIDE(SUM(gmv), COUNT(DISTINCT order_id)) as aov
FROM order_gmv
  GROUP BY order_id, gmv
)

SELECT
  DATE(o.order_purchase_timestamp) AS date,
  o.order_id,
  c.customer_state,
  mc.product_category,
  oga.gmv,
  oga.aov,
  o.order_status,
  o.order_estimated_delivery_date,
  o.order_delivered_customer_date,
  SAFE_CAST(o.order_delivered_customer_date > o.order_estimated_delivery_date AS INT64) AS is_late,
  DATE_DIFF(o.order_delivered_customer_date, o.order_purchase_timestamp, DAY) AS delivery_days
FROM `projectperso-472608.Olist_persoproject.orders` AS o
JOIN `projectperso-472608.Olist_persoproject.customers` AS c USING (customer_id)
LEFT JOIN main_cat AS mc USING (order_id)
LEFT JOIN order_gmv_aov AS oga USING (order_id)

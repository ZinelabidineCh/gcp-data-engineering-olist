/* Project: Olist E-commerce Analytics
  Description: Identifies the top 10 product categories by total revenue.
  Note: Only 'delivered' orders are included to ensure data accuracy.
*/

SELECT
  product_category_name AS category,
  ROUND(SUM(total_order_item_value), 2) AS total_revenue,
  COUNT(order_id) AS sales_volume
FROM
  `your-gcp-project-id.olist_analytics.fact_order_items`
WHERE
  order_status = 'delivered'
GROUP BY
  1
ORDER BY
  total_revenue DESC
LIMIT 10
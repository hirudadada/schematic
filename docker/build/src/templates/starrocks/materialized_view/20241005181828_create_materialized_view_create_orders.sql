SELECT
  o.order_id,
  o.order_date,
  o.customer_id,
  o.total_amount,
  e.event_type,
  e.event_details
FROM
    orders o
LEFT JOIN
    events e
ON
    o.customer_id = e.user_id
WHERE
    e.event_time > '2019-02-01'

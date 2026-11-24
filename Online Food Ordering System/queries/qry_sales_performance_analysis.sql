SET VERIFY OFF     
SET LINESIZE 200
SET PAGESIZE 100
SET WRAP OFF

COLUMN "Member ID"        FORMAT A10
COLUMN "Customer Name"    FORMAT A20
COLUMN "Total Orders"     FORMAT 9999
COLUMN "Total Spent"      FORMAT A16
COLUMN "Avg Order Value"  FORMAT A16
COLUMN "Customer Tier"    FORMAT A15

UNDEFINE search

CREATE OR REPLACE VIEW vw_member_sales AS
SELECT o.order_id,
       o.member_id,
       m.name,
       -- Logic: Gross - Promo - Voucher (Using CASE instead of NVL)
       (o.total_amount - 
        (CASE WHEN o.discount_amount IS NULL THEN 0 ELSE o.discount_amount END) - 
        (CASE WHEN vr.savings_amount IS NULL THEN 0 ELSE vr.savings_amount END)
       ) AS net_spent,
       o.order_date
FROM Orders o
JOIN Member m 
  ON o.member_id = m.member_id
LEFT JOIN VoucherRedemption vr 
  ON vr.order_id = o.order_id;

SELECT m.member_id AS "Member ID",
       m.name AS "Customer Name",
       COUNT(*) AS "Total Orders",
       'RM ' || TO_CHAR(SUM(m.net_spent), 'FM999,990.00') AS "Total Spent",
       'RM ' || TO_CHAR(AVG(m.net_spent), 'FM999,990.00') AS "Avg Order Value",
       CASE 
           WHEN SUM(m.net_spent) >= 500 THEN 'Pro'
           WHEN SUM(m.net_spent) >= 200 THEN 'Normal'
           ELSE 'Low'
       END AS "Customer Tier"
FROM vw_member_sales m
WHERE LOWER(TRIM(m.name)) LIKE LOWER(TRIM('&search')) || '%'
GROUP BY m.member_id, m.name
HAVING SUM(m.net_spent) > 0
ORDER BY SUM(m.net_spent) DESC;
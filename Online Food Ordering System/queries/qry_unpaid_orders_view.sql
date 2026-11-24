SET VERIFY OFF     
SET LINESIZE 300
SET PAGESIZE 100
SET WRAP OFF

COLUMN "Order ID"         FORMAT A10
COLUMN "Customer Name"    FORMAT A20
COLUMN "Phone Number"     FORMAT A15
COLUMN "Total Items"      FORMAT 9999
COLUMN "Items Subtotal"   FORMAT A16
COLUMN "Recorded Total"   FORMAT A16
COLUMN "Balance Variance" FORMAT A16
COLUMN "Final Bill"       FORMAT A16
COLUMN "Order Date"       FORMAT A12

UNDEFINE search

CREATE OR REPLACE VIEW vw_unpaid_orders AS
SELECT o.order_id,
       o.member_id,
       m.name,
       m.phone,
       o.order_date,
       o.total_amount AS gross_total,
       o.discount_amount AS promo_discount,
       o.order_status
FROM Orders o
JOIN Member m ON o.member_id = m.member_id
WHERE LOWER(TRIM(o.order_status)) = 'pending';

SELECT u.order_id                                                           AS "Order ID",
       u.name                                                               AS "Customer Name",
       u.phone                                                              AS "Phone Number",
       COUNT(od.food_id)                                                    AS "Total Items",
       'RM ' || TO_CHAR(SUM(od.subtotal), 'FM999,990.00')                   AS "Items Subtotal",
       'RM ' || TO_CHAR(u.gross_total, 'FM999,990.00')                      AS "Recorded Total",
       -- Variance should be 0 because both are Gross
       'RM ' || TO_CHAR((u.gross_total - SUM(od.subtotal)), 'FM999,990.00') AS "Balance Variance",
       -- Calculation: Gross - Promo - Voucher (Using CASE instead of NVL)
       'RM ' || TO_CHAR(u.gross_total - 
               (CASE WHEN u.promo_discount IS NULL THEN 0 ELSE u.promo_discount END) - 
               (CASE WHEN vr.savings_amount IS NULL THEN 0 ELSE vr.savings_amount END), 
               'FM999,990.00')                                              AS "Final Bill",
       u.order_date                                                         AS "Order Date"
FROM vw_unpaid_orders u
JOIN OrderDetails od ON u.order_id = od.order_id
LEFT JOIN VoucherRedemption vr ON u.order_id = vr.order_id
WHERE TRIM(u.phone) LIKE TRIM('&search') || '%'
GROUP BY u.order_id,
         u.name,
         u.phone,
         u.gross_total,
         u.promo_discount,
         vr.savings_amount,
         u.order_date
ORDER BY u.order_date DESC;
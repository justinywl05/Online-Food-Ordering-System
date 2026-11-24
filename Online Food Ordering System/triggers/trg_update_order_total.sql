CREATE OR REPLACE TRIGGER trg_update_order_total
AFTER INSERT OR UPDATE OR DELETE ON OrderDetails
BEGIN
    UPDATE Orders o
    SET total_amount = (
        SELECT CASE 
                   WHEN SUM(subtotal) IS NULL THEN 0 
                   ELSE SUM(subtotal) 
               END
        FROM OrderDetails od
        WHERE od.order_id = o.order_id
    )
    WHERE o.order_id IN (SELECT DISTINCT order_id FROM OrderDetails);
END;
/
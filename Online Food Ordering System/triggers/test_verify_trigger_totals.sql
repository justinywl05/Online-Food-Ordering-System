SELECT 
    order_id, 
    total_amount AS "Base Total", 
    CASE WHEN discount_amount IS NULL THEN 0 ELSE discount_amount END AS "Promo Discount",
    (
        total_amount - 
        CASE WHEN discount_amount IS NULL THEN 0 ELSE discount_amount END - 
        CASE WHEN (SELECT vr.savings_amount FROM VoucherRedemption vr WHERE vr.order_id = Orders.order_id) IS NULL 
             THEN 0 
             ELSE (SELECT vr.savings_amount FROM VoucherRedemption vr WHERE vr.order_id = Orders.order_id) 
        END
    ) AS "FINAL_PAYABLE"
FROM Orders
WHERE order_id = 'O5000';
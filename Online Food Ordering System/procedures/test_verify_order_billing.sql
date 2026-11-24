SELECT 
    o.total_amount AS "Gross",
    (CASE WHEN o.discount_amount IS NULL THEN 0 ELSE o.discount_amount END) AS "Promo",
    (CASE WHEN vr.savings_amount IS NULL THEN 0 ELSE vr.savings_amount END) AS "Voucher",
    (o.total_amount - 
     (CASE WHEN o.discount_amount IS NULL THEN 0 ELSE o.discount_amount END) - 
     (CASE WHEN vr.savings_amount IS NULL THEN 0 ELSE vr.savings_amount END)
    ) AS "Final_Bill"
FROM Orders o
LEFT JOIN VoucherRedemption vr ON o.order_id = vr.order_id
WHERE o.order_id = 'O4000';
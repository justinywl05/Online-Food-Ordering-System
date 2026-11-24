SET DEFINE OFF
SET SERVEROUTPUT ON

CREATE OR REPLACE PROCEDURE rpt_member_promotion_summary (
    p_member_id IN Member.member_id%TYPE
) IS
    -- OUTER CURSOR: Get each order
    CURSOR c_orders IS
        SELECT o.order_id, 
               o.order_date, 
               o.total_amount AS gross_price,
               -- Get voucher amount manually using CASE (No NVL)
               (CASE WHEN (SELECT MAX(savings_amount) FROM VoucherRedemption vr WHERE vr.order_id = o.order_id) IS NULL 
                     THEN 0 
                     ELSE (SELECT MAX(savings_amount) FROM VoucherRedemption vr WHERE vr.order_id = o.order_id) 
                END) AS voucher_val
        FROM Orders o
        WHERE o.member_id = p_member_id;

    -- INNER CURSOR: Get items
    CURSOR c_promo_items(p_order_id VARCHAR2) IS
        SELECT od.food_id, 
               f.name, 
               od.quantity, 
               od.subtotal,
               (SELECT p.discount_percentage FROM Promotion p 
                JOIN PromotionItem pi ON p.promo_id = pi.promo_id 
                WHERE pi.food_id = od.food_id AND p.status = 'Active' AND ROWNUM = 1) AS item_pct
        FROM OrderDetails od
        JOIN FoodItem f ON od.food_id = f.food_id
        WHERE od.order_id = p_order_id;

    v_member_name       Member.name%TYPE;
    v_item_discount     NUMBER(10,2);
    v_order_promo_sum   NUMBER(10,2); -- Sum of item discounts in THIS order
    v_order_grand_total NUMBER(10,2); -- Promo + Voucher for THIS order
    v_lifetime_savings  NUMBER(10,2) := 0; -- Grand total for all orders

BEGIN
    -- Get member name
    SELECT name INTO v_member_name FROM Member WHERE member_id = p_member_id;

    -- HEADER
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
    DBMS_OUTPUT.PUT_LINE('                       MEMBER SAVINGS & PROMOTION ANALYTICS');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
    DBMS_OUTPUT.PUT_LINE('Member ID : ' || p_member_id || '   Name : ' || v_member_name);
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));

    FOR o IN c_orders LOOP
        v_order_promo_sum := 0; -- Reset for every new order

        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Order: ' || o.order_id || ' | Date: ' || TO_CHAR(o.order_date, 'DD-MON-YYYY'));
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));
        DBMS_OUTPUT.PUT_LINE(RPAD('Food Item', 25) || RPAD('Qty', 10) || RPAD('Gross', 15) || RPAD('Promo %', 12) || 'Saved (RM)');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));

        FOR i in c_promo_items(o.order_id) LOOP
            -- Calculate item savings
            v_item_discount := i.subtotal * (CASE WHEN i.item_pct IS NULL THEN 0 ELSE i.item_pct END / 100);
            
            -- Add to this order's total
            v_order_promo_sum := v_order_promo_sum + v_item_discount;

            DBMS_OUTPUT.PUT_LINE(
                RPAD(i.name, 25) || 
                RPAD(i.quantity, 10) || 
                RPAD(TO_CHAR(i.subtotal, 'FM9990.00'), 15) || 
                RPAD((CASE WHEN i.item_pct IS NULL THEN '0' ELSE TO_CHAR(i.item_pct) END) || '%', 12) ||
                TO_CHAR(v_item_discount, 'FM9990.00')
            );
        END LOOP;

        -- Calculate Order Total (Promo sum + Voucher from Outer Cursor)
        v_order_grand_total := v_order_promo_sum + o.voucher_val;
        v_lifetime_savings := v_lifetime_savings + v_order_grand_total;

        DBMS_OUTPUT.PUT_LINE(RPAD('.', 80, '.'));
        DBMS_OUTPUT.PUT_LINE('   > Order Gross Total    : RM ' || TO_CHAR(o.gross_price, 'FM9990.00'));
        DBMS_OUTPUT.PUT_LINE('   > Voucher Applied      : RM ' || TO_CHAR(o.voucher_val, 'FM9990.00'));
        -- Now this total will ALWAYS match the items above
        DBMS_OUTPUT.PUT_LINE('   > TOTAL SAVED IN ORDER : RM ' || TO_CHAR(v_order_grand_total, 'FM9990.00'));
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));
    END LOOP;

    -- FINAL LIFETIME SUMMARY
    DBMS_OUTPUT.PUT_LINE(CHR(10) || RPAD('=', 80, '='));
    DBMS_OUTPUT.PUT_LINE('                              LIFETIME SAVINGS SUMMARY');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));
    DBMS_OUTPUT.PUT_LINE('   TOTAL MONEY SAVED TO DATE : RM ' || TO_CHAR(v_lifetime_savings, 'FM9,990.00'));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
    DBMS_OUTPUT.PUT_LINE('                                 END OF REPORT');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Member ID not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
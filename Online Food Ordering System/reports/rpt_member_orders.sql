CREATE OR REPLACE PROCEDURE rpt_member_orders IS

    CURSOR c_member IS
        SELECT member_id, name FROM Member;

    CURSOR c_orders(p_member_id VARCHAR2) IS
        SELECT order_id, 
               order_date, 
               total_amount AS base_total,
               CASE WHEN discount_amount IS NULL THEN 0 ELSE discount_amount END AS promo_discount,
               (SELECT CASE WHEN MAX(savings_amount) IS NULL THEN 0 ELSE MAX(savings_amount) END 
                FROM VoucherRedemption 
                WHERE order_id = Orders.order_id) AS voucher_discount
        FROM Orders
        WHERE member_id = p_member_id;

    CURSOR c_details(p_order_id VARCHAR2) IS
        SELECT food_id, quantity, subtotal
        FROM OrderDetails
        WHERE order_id = p_order_id;

    v_has_order BOOLEAN;
    v_final_total NUMBER(10,2);
    v_total_discounts NUMBER(10,2);

BEGIN
    -- TOP HEADER
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
    -- Exactly 30 spaces before the text
    DBMS_OUTPUT.PUT_LINE('                              MEMBER ORDER REPORT');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));

    FOR m IN c_member LOOP

        -- MEMBER INFO HEADER
        DBMS_OUTPUT.PUT_LINE(CHR(10));
        DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
        DBMS_OUTPUT.PUT_LINE('Member ID : ' || m.member_id ||
                             '   Name : ' || m.name);
        DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));

        v_has_order := FALSE;

        FOR o IN c_orders(m.member_id) LOOP
            v_has_order := TRUE;
            
            -- Calculate Final Pricing
            v_total_discounts := o.promo_discount + o.voucher_discount;
            v_final_total := o.base_total - v_total_discounts;

            -- SPACE BEFORE EACH ORDER
            DBMS_OUTPUT.PUT_LINE(CHR(10));

            DBMS_OUTPUT.PUT_LINE(
                'Order ID : ' || o.order_id ||
                '   Date : ' || TO_CHAR(o.order_date, 'DD-MON-YYYY')
            );
            
            -- PRICING BREAKDOWN
            DBMS_OUTPUT.PUT_LINE(
                'Base: RM ' || TO_CHAR(o.base_total, '9990.00') || 
                ' | Discounts: RM ' || TO_CHAR(v_total_discounts, '9990.00') ||
                ' | FINAL TOTAL: RM ' || TO_CHAR(v_final_total, '9990.00')
            );

            DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));

            DBMS_OUTPUT.PUT_LINE(
                RPAD('Food ID', 15) ||
                RPAD('Qty', 10) ||
                RPAD('Subtotal (RM)', 15)
            );

            DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));

            FOR d IN c_details(o.order_id) LOOP
                DBMS_OUTPUT.PUT_LINE(
                    RPAD(d.food_id, 15) ||
                    RPAD(d.quantity, 10) ||
                    TO_CHAR(d.subtotal, '9990.00')
                );
            END LOOP;

            -- SPACE AFTER EACH ORDER
            DBMS_OUTPUT.PUT_LINE(CHR(10));

        END LOOP;

        -- NO ORDER HANDLING
        IF NOT v_has_order THEN
            DBMS_OUTPUT.PUT_LINE('No orders found for this member.');
        END IF;

    END LOOP;

    -- FOOTER
    DBMS_OUTPUT.PUT_LINE(CHR(10) || RPAD('=', 80, '='));
    -- Exactly 33 spaces before the text
    DBMS_OUTPUT.PUT_LINE('                                 END OF REPORT');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));

END;
/
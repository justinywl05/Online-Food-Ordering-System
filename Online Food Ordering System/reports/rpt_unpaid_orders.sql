CREATE OR REPLACE PROCEDURE rpt_unpaid_orders (
    p_member_id IN Member.member_id%TYPE
) IS

    CURSOR c_orders IS
        SELECT v.order_id, 
               v.name, 
               v.order_date, 
               o.total_amount AS base_total, -- Changed from v.total_amount to o.total_amount
               CASE WHEN o.discount_amount IS NULL THEN 0 ELSE o.discount_amount END AS promo_discount,
               (SELECT CASE WHEN MAX(savings_amount) IS NULL THEN 0 ELSE MAX(savings_amount) END 
                FROM VoucherRedemption 
                WHERE order_id = v.order_id) AS voucher_discount
        FROM vw_unpaid_orders v
        JOIN Orders o ON v.order_id = o.order_id
        WHERE v.member_id = p_member_id;

    CURSOR c_details(p_order_id Orders.order_id%TYPE) IS
        SELECT food_id, quantity, subtotal
        FROM OrderDetails
        WHERE order_id = p_order_id;

    v_count NUMBER := 0;
    v_total_unpaid NUMBER := 0;
    
    v_final_total NUMBER(10,2);
    v_total_discounts NUMBER(10,2);

BEGIN
    -- TOP HEADER
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
    -- Added 30 spaces for "UNPAID ORDERS REPORT"
    DBMS_OUTPUT.PUT_LINE('                              UNPAID ORDERS REPORT');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));

    FOR o IN c_orders LOOP
        v_count := v_count + 1;
        
        -- Calculate Final Pricing
        v_total_discounts := o.promo_discount + o.voucher_discount;
        v_final_total := o.base_total - v_total_discounts;
        
        -- Add ONLY the Final Total to the Unpaid Summary
        v_total_unpaid := v_total_unpaid + v_final_total;

        DBMS_OUTPUT.PUT_LINE(CHR(10));

        DBMS_OUTPUT.PUT_LINE(
            'Order ID : ' || o.order_id ||
            '   Name : ' || o.name ||
            '   Date : ' || TO_CHAR(o.order_date, 'DD-MON-YYYY')
        );
        
        -- PRICING BREAKDOWN
        DBMS_OUTPUT.PUT_LINE(
            'Base: RM ' || TO_CHAR(o.base_total, '9990.00') || 
            ' | Discounts: RM ' || TO_CHAR(v_total_discounts, '9990.00') ||
            ' | AMOUNT DUE: RM ' || TO_CHAR(v_final_total, '9990.00')
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

        DBMS_OUTPUT.PUT_LINE(CHR(10));

    END LOOP;

    -- SUMMARY SECTION
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
    -- Added 36 spaces for "SUMMARY"
    DBMS_OUTPUT.PUT_LINE('                                    SUMMARY');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));
    DBMS_OUTPUT.PUT_LINE('Total Unpaid Orders : ' || v_count);
    DBMS_OUTPUT.PUT_LINE('Total Amount Due    : RM ' || TO_CHAR(v_total_unpaid, '9990.00'));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));

    -- NO DATA CASE
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001,
            'No unpaid orders found for Member ID: ' || p_member_id);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;
END;
/
CREATE SEQUENCE seq_payment_id
START WITH 2000
INCREMENT BY 1;

CREATE OR REPLACE PROCEDURE proc_make_payment (
    p_order_id   IN VARCHAR2,
    p_amount     IN NUMBER,
    p_method     IN VARCHAR2
)
IS
    v_status     Orders.order_status%TYPE;
    v_total      NUMBER(10,2);
    v_payment_id VARCHAR2(20);
BEGIN
    -- Generate Payment ID
    v_payment_id := 'P' || seq_payment_id.NEXTVAL;

    -- Get order status + FINAL TOTAL
    SELECT 
        o.order_status, 
        (o.total_amount - 
         (CASE WHEN o.discount_amount IS NULL THEN 0 ELSE o.discount_amount END) - 
         (CASE WHEN (SELECT vr.savings_amount FROM VoucherRedemption vr WHERE vr.order_id = o.order_id) IS NULL 
               THEN 0 
               ELSE (SELECT vr.savings_amount FROM VoucherRedemption vr WHERE vr.order_id = o.order_id) 
          END)
        )
    INTO v_status, v_total
    FROM Orders o
    WHERE o.order_id = p_order_id;

    -- Rule 1: Cannot pay cancelled order
    IF v_status = 'Cancelled' THEN
        RAISE_APPLICATION_ERROR(-20001,
        'Error: Cannot make payment for a cancelled order.');
    END IF;

    -- Rule 2: Prevent double payment
    IF v_status = 'Paid' THEN
        RAISE_APPLICATION_ERROR(-20002,
        'Error: Order is already paid.');
    END IF;

    -- Rule 3: Payment must match FINAL total
    -- Note: We use ABS difference < 0.01 to avoid floating point issues with NUMBER
    IF ABS(p_amount - v_total) > 0.01 THEN
        RAISE_APPLICATION_ERROR(-20003,
        'Error: Payment amount RM' || p_amount || ' does not match final order total RM' || v_total);
    END IF;

    -- Insert payment
    INSERT INTO Payment (
        payment_id,
        order_id,
        amount,
        payment_method
    )
    VALUES (
        v_payment_id,
        p_order_id,
        p_amount,
        p_method
    );

    -- Update status
    UPDATE Orders
    SET order_status = 'Paid'
    WHERE order_id = p_order_id;

    -- RECEIPT
    DBMS_OUTPUT.PUT_LINE(RPAD('=',50,'='));
    DBMS_OUTPUT.PUT_LINE(LPAD('PAYMENT RECEIPT',32));
    DBMS_OUTPUT.PUT_LINE(RPAD('=',50,'='));

    DBMS_OUTPUT.PUT_LINE('Payment ID    : ' || v_payment_id);
    DBMS_OUTPUT.PUT_LINE('Order ID      : ' || p_order_id);
    DBMS_OUTPUT.PUT_LINE('Amount Paid   : RM ' || TO_CHAR(p_amount,'9990.00'));
    DBMS_OUTPUT.PUT_LINE('Payment Method: ' || p_method);
    DBMS_OUTPUT.PUT_LINE('Order Status  : Paid');

    DBMS_OUTPUT.PUT_LINE(RPAD('-',50,'-'));
    DBMS_OUTPUT.PUT_LINE('FINAL TOTAL   : RM ' || TO_CHAR(v_total,'9990.00'));
    DBMS_OUTPUT.PUT_LINE(RPAD('-',50,'-'));

    DBMS_OUTPUT.PUT_LINE('Payment Successful. Thank you!');
    DBMS_OUTPUT.PUT_LINE(RPAD('=',50,'='));

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004,
        'Error: Order does not exist.');

    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20005,
        'Error: Payment record already exists for this ID.');
END;
/
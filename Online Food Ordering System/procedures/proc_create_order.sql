SET SERVEROUTPUT ON


-- 1. SEQUENCE

CREATE SEQUENCE seq_order_detail_id
START WITH 1265
INCREMENT BY 1;


-- 2. INDEXES 

CREATE INDEX idx_orders_member 
ON Orders(member_id);

CREATE INDEX idx_orderdetails_order 
ON OrderDetails(order_id);

-- 3. PROCEDURE: ADD ORDER DETAILS

CREATE OR REPLACE PROCEDURE proc_add_order_detail (
    p_order_id IN VARCHAR2,
    p_food_id  IN VARCHAR2,
    p_quantity IN NUMBER
)
IS
    ex_invalid_quantity EXCEPTION;

    v_price    NUMBER(7,2);
    v_subtotal NUMBER(7,2);
    v_count    NUMBER;

BEGIN
    -- Validate quantity
    IF p_quantity <= 0 THEN
        RAISE ex_invalid_quantity;
    END IF;

    -- Check if order exists
    SELECT COUNT(*) INTO v_count
    FROM Orders
    WHERE order_id = p_order_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Order does not exist.');
    END IF;

    -- Get food price
    SELECT price INTO v_price
    FROM FoodItem
    WHERE food_id = p_food_id;

    -- Calculate subtotal
    v_subtotal := v_price * p_quantity;

    -- Insert order detail
    INSERT INTO OrderDetails (
        order_detail_id,
        order_id,
        food_id,
        quantity,
        subtotal
    )
    VALUES (
        'OD' || seq_order_detail_id.NEXTVAL,
        p_order_id,
        p_food_id,
        p_quantity,
        v_subtotal
    );

   DBMS_OUTPUT.PUT_LINE(RPAD('=',50,'='));
   DBMS_OUTPUT.PUT_LINE('ORDER DETAIL ADDED SUCCESSFULLY');
   DBMS_OUTPUT.PUT_LINE(RPAD('=',50,'='));

   DBMS_OUTPUT.PUT_LINE('Order ID   : ' || p_order_id);
   DBMS_OUTPUT.PUT_LINE('Food ID    : ' || p_food_id);
   DBMS_OUTPUT.PUT_LINE('Quantity   : ' || p_quantity);
   DBMS_OUTPUT.PUT_LINE('Unit Price : RM ' || TO_CHAR(v_price,'9990.00'));
   DBMS_OUTPUT.PUT_LINE('Subtotal   : RM ' || TO_CHAR(v_subtotal,'9990.00'));

   DBMS_OUTPUT.PUT_LINE(RPAD('=',50,'='));

EXCEPTION
    WHEN ex_invalid_quantity THEN
        RAISE_APPLICATION_ERROR(-20031, 'Quantity must be greater than 0.');

    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20032, 'Invalid food ID.');

    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('REAL ERROR: ' || SQLERRM);
    RAISE;
END;
/
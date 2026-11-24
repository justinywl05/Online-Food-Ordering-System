CREATE OR REPLACE TRIGGER trg_auto_apply_promotion
AFTER INSERT ON OrderDetails
FOR EACH ROW
DECLARE
    v_pct NUMBER;
    v_member VARCHAR2(10);
    v_is_vip CHAR(1) := 'N';
    v_min_spend NUMBER;
    v_vip_only CHAR(1);
    v_discount NUMBER;
    v_total NUMBER;
    v_current_discount NUMBER;
BEGIN
    -- Get current total & discount normally (No NVL)
    SELECT total_amount, member_id, discount_amount
    INTO v_total, v_member, v_current_discount
    FROM Orders
    WHERE order_id = :NEW.order_id;

    -- Manual NULL handling for the main order
    IF v_total IS NULL THEN 
        v_total := 0; 
    END IF;
    
    IF v_current_discount IS NULL THEN 
        v_current_discount := 0; 
    END IF;

    -- Check VIP status
    BEGIN
        SELECT 'Y' INTO v_is_vip
        FROM MembershipSubscription
        WHERE member_id = v_member
        AND status = 'ACTIVE'
        AND (end_date IS NULL OR end_date >= SYSDATE)
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN v_is_vip := 'N';
    END;

    -- Get promotion details normally (No NVL)
    BEGIN
        SELECT p.discount_percentage, pc.min_spend, pc.vip_only
        INTO v_pct, v_min_spend, v_vip_only
        FROM Promotion p
        JOIN PromotionItem pi ON p.promo_id = pi.promo_id
        LEFT JOIN PromotionCondition pc ON p.promo_id = pc.promo_id
        WHERE pi.food_id = :NEW.food_id
        AND p.status = 'Active'
        AND ROWNUM = 1;
        
        -- Manual NULL handling for the promotion conditions
        IF v_min_spend IS NULL THEN 
            v_min_spend := 0; 
        END IF;
        
        IF v_vip_only IS NULL THEN 
            v_vip_only := 'N'; 
        END IF;
        
        -- Apply if min spend is reached (Current Total + New Item Subtotal)
        IF (v_total + :NEW.subtotal) >= v_min_spend AND
           (v_vip_only = 'N' OR (v_vip_only = 'Y' AND v_is_vip = 'Y')) THEN

            v_discount := :NEW.subtotal * (v_pct / 100);

            UPDATE Orders
            SET discount_amount = v_current_discount + v_discount
            WHERE order_id = :NEW.order_id;
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL; -- No active promo for this item
    END;
END;
/
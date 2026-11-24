DROP TABLE MemberAddress CASCADE CONSTRAINTS;
DROP TABLE Member CASCADE CONSTRAINTS;
DROP TABLE MembershipSubscription CASCADE CONSTRAINTS;
DROP TABLE MembershipType CASCADE CONSTRAINTS;
DROP TABLE FoodItem CASCADE CONSTRAINTS;
DROP TABLE FoodCategory CASCADE CONSTRAINTS;
DROP TABLE Restaurant CASCADE CONSTRAINTS;
DROP TABLE OrderDetails CASCADE CONSTRAINTS;
DROP TABLE Payment CASCADE CONSTRAINTS;
DROP TABLE Delivery CASCADE CONSTRAINTS;
DROP TABLE DeliveryCompany CASCADE CONSTRAINTS;
DROP TABLE Orders CASCADE CONSTRAINTS;
DROP TABLE PromotionUsage CASCADE CONSTRAINTS;
DROP TABLE PromotionCondition CASCADE CONSTRAINTS;
DROP TABLE PromotionItem CASCADE CONSTRAINTS;
DROP TABLE Promotion CASCADE CONSTRAINTS;
DROP TABLE VoucherRedemption CASCADE CONSTRAINTS;
DROP TABLE Voucher CASCADE CONSTRAINTS;

CREATE TABLE MembershipType (
    membership_type_id VARCHAR2(10) PRIMARY KEY,
    type_name VARCHAR2(20) NOT NULL,
    fee NUMBER(5,2) DEFAULT 0 NOT NULL
);


CREATE TABLE Member (
    member_id VARCHAR2(10) PRIMARY KEY,
    name VARCHAR2(50) NOT NULL,
    email VARCHAR2(50) UNIQUE NOT NULL,
    phone VARCHAR2(15) UNIQUE NOT NULL,
    membership_type_id VARCHAR2(10) NOT NULL,
    CONSTRAINT fk_member_membership FOREIGN KEY (membership_type_id)
        REFERENCES MembershipType(membership_type_id)
);

CREATE TABLE MembershipSubscription (
    subscription_id VARCHAR2(10) PRIMARY KEY,
    member_id VARCHAR2(10) NOT NULL,
    membership_type_id VARCHAR2(10) NOT NULL,
    start_date DATE DEFAULT SYSDATE,
    end_date DATE,
    status VARCHAR2(10) DEFAULT 'ACTIVE',
    CONSTRAINT fk_sub_member FOREIGN KEY (member_id)
        REFERENCES Member(member_id),
    CONSTRAINT fk_sub_type FOREIGN KEY (membership_type_id)
        REFERENCES MembershipType(membership_type_id)
);

CREATE TABLE MemberAddress (
    address_id VARCHAR2(10) PRIMARY KEY,
    member_id VARCHAR2(10) NOT NULL,
    address VARCHAR2(100) NOT NULL,
    is_default CHAR(1) CHECK (is_default IN ('Y','N')),
    CONSTRAINT fk_address_member FOREIGN KEY (member_id)
        REFERENCES Member(member_id)
);


CREATE TABLE FoodCategory (
    category_id VARCHAR2(10) PRIMARY KEY,
    category_name VARCHAR2(50) NOT NULL
);

CREATE TABLE Restaurant (
    restaurant_id VARCHAR2(10) PRIMARY KEY,
    name VARCHAR2(50) NOT NULL,
    halal_status VARCHAR2(10) CHECK (halal_status IN ('Halal','Non-Halal')) NOT NULL
);

CREATE TABLE FoodItem (
    food_id VARCHAR2(10) PRIMARY KEY,
    restaurant_id VARCHAR2(10) NOT NULL,
    category_id VARCHAR2(10) NOT NULL,
    name VARCHAR2(50) NOT NULL,
    price NUMBER(7,2) NOT NULL,
    status VARCHAR2(15) DEFAULT 'Available' CHECK (status IN ('Available','Unavailable')),
    CONSTRAINT fk_food_restaurant FOREIGN KEY (restaurant_id)
        REFERENCES Restaurant(restaurant_id),
    CONSTRAINT fk_food_category FOREIGN KEY (category_id)
        REFERENCES FoodCategory(category_id)
);


CREATE TABLE Orders (
    order_id VARCHAR2(10) PRIMARY KEY,
    member_id VARCHAR2(10) NOT NULL,
    order_date DATE DEFAULT SYSDATE,
    total_amount NUMBER(7,2) NOT NULL,
    discount_amount NUMBER(7,2) DEFAULT 0,
    delivery_option VARCHAR2(10) DEFAULT 'Delivery' 
        CHECK (delivery_option IN ('Pickup','Delivery')),
    order_status VARCHAR2(20) DEFAULT 'Pending'
        CHECK (order_status IN ('Pending','Paid','Cancelled','Completed')),
    CONSTRAINT fk_order_member FOREIGN KEY (member_id)
        REFERENCES Member(member_id)
);

CREATE TABLE OrderDetails (
    order_detail_id VARCHAR2(10) PRIMARY KEY,
    order_id VARCHAR2(10) NOT NULL,
    food_id VARCHAR2(10) NOT NULL,
    quantity NUMBER DEFAULT 1 CHECK (quantity > 0),
    subtotal NUMBER(7,2) NOT NULL,
    CONSTRAINT fk_orderdetails_order FOREIGN KEY (order_id)
        REFERENCES Orders(order_id),
    CONSTRAINT fk_orderdetails_food FOREIGN KEY (food_id)
        REFERENCES FoodItem(food_id)
);

CREATE TABLE Payment (
    payment_id VARCHAR2(10) PRIMARY KEY,
    order_id VARCHAR2(10) UNIQUE NOT NULL,
    amount NUMBER(7,2) NOT NULL,
    payment_method VARCHAR2(20) CHECK (payment_method IN ('Card','Cash','E-wallet')) NOT NULL,
    CONSTRAINT fk_payment_order FOREIGN KEY (order_id)
        REFERENCES Orders(order_id)
);

CREATE TABLE DeliveryCompany (
    company_id VARCHAR2(10) PRIMARY KEY,
    name VARCHAR2(50) NOT NULL
);

CREATE TABLE Delivery (
    delivery_id VARCHAR2(10) PRIMARY KEY,
    order_id VARCHAR2(10) UNIQUE NOT NULL,
    company_id VARCHAR2(10) NOT NULL,
    delivery_status VARCHAR2(20) DEFAULT 'Pending' CHECK (delivery_status IN ('Delivered','Pending','Cancelled')),
    CONSTRAINT fk_delivery_order FOREIGN KEY (order_id)
        REFERENCES Orders(order_id),
    CONSTRAINT fk_delivery_company FOREIGN KEY (company_id)
        REFERENCES DeliveryCompany(company_id)
);

CREATE TABLE Promotion (
    promo_id VARCHAR2(10) PRIMARY KEY,
    promo_name VARCHAR2(50) NOT NULL,
    description VARCHAR2(200),
    discount_percentage NUMBER(5,2) NOT NULL,
    status VARCHAR2(10) DEFAULT 'Active'
        CHECK (status IN ('Active','Inactive')),
    -- Ensure valid percentage (0–100)
    CONSTRAINT chk_promo_percentage CHECK (
        discount_percentage > 0 AND discount_percentage <= 100
    )
);

CREATE TABLE PromotionItem (
    promo_item_id VARCHAR2(10) PRIMARY KEY,
    promo_id VARCHAR2(10) NOT NULL,
    food_id VARCHAR2(10) NOT NULL,
    CONSTRAINT fk_promoitem_promo FOREIGN KEY (promo_id)
        REFERENCES Promotion(promo_id),
    CONSTRAINT fk_promoitem_food FOREIGN KEY (food_id)
        REFERENCES FoodItem(food_id),
    CONSTRAINT uq_promo_food UNIQUE (promo_id, food_id) -- (5)
);

CREATE TABLE PromotionCondition (
    cond_id VARCHAR2(10) PRIMARY KEY,
    promo_id VARCHAR2(10) NOT NULL,
    min_spend NUMBER(7,2) DEFAULT 0,
    vip_only CHAR(1) DEFAULT 'N' CHECK (vip_only IN ('Y','N')),
    food_category_id VARCHAR2(10),
    CONSTRAINT fk_condition_promo FOREIGN KEY (promo_id)
        REFERENCES Promotion(promo_id),
    CONSTRAINT fk_condition_category FOREIGN KEY (food_category_id)
        REFERENCES FoodCategory(category_id)
);

CREATE TABLE PromotionUsage (
    usage_id VARCHAR2(10) PRIMARY KEY,
    promo_id VARCHAR2(10) NOT NULL,
    member_id VARCHAR2(10) NOT NULL,
    order_id VARCHAR2(10) UNIQUE NOT NULL, -- (3)
    CONSTRAINT fk_usage_promo FOREIGN KEY (promo_id)
        REFERENCES Promotion(promo_id),
    CONSTRAINT fk_usage_member FOREIGN KEY (member_id)
        REFERENCES Member(member_id),
    CONSTRAINT fk_usage_order FOREIGN KEY (order_id)
        REFERENCES Orders(order_id)
);

CREATE TABLE Voucher (
    voucher_id VARCHAR2(10) PRIMARY KEY,
    voucher_code VARCHAR2(20) UNIQUE NOT NULL,
    description VARCHAR2(200),
    voucher_type VARCHAR2(15) NOT NULL 
        CHECK (voucher_type IN ('AMOUNT','PERCENTAGE','DELIVERY')),
    discount_amount NUMBER(7,2),
    discount_percentage NUMBER(5,2),
    min_spend NUMBER(7,2) DEFAULT 0,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    vip_only CHAR(1) DEFAULT 'N' CHECK (vip_only IN ('Y','N')),
    status VARCHAR2(10) DEFAULT 'Active' CHECK (status IN ('Active','Inactive')),
    CONSTRAINT chk_voucher_discount CHECK (
        (voucher_type = 'AMOUNT' AND discount_amount IS NOT NULL AND discount_percentage IS NULL)
        OR
        (voucher_type = 'PERCENTAGE' AND discount_percentage IS NOT NULL AND discount_amount IS NULL)
        OR
        (voucher_type = 'DELIVERY' AND discount_amount IS NULL AND discount_percentage IS NULL)),
    CONSTRAINT chk_voucher_date CHECK (end_date > start_date)
);

CREATE TABLE VoucherRedemption (
    redemption_id VARCHAR2(10) PRIMARY KEY,
    voucher_id VARCHAR2(10) NOT NULL,
    member_id VARCHAR2(10) NOT NULL,
    order_id VARCHAR2(10) UNIQUE,
    savings_amount NUMBER(7,2) DEFAULT 0, 
    CONSTRAINT fk_redemption_voucher FOREIGN KEY (voucher_id)
        REFERENCES Voucher(voucher_id),
    CONSTRAINT fk_redemption_member FOREIGN KEY (member_id)
        REFERENCES Member(member_id),
    CONSTRAINT fk_redemption_order FOREIGN KEY (order_id)
        REFERENCES Orders(order_id)
);


UPDATE Voucher 
SET start_date = SYSDATE - 1, 
    end_date = SYSDATE + 365;

UPDATE MembershipSubscription 
SET start_date = SYSDATE - 1, 
    end_date = SYSDATE + 365, 
    status = 'ACTIVE';

COMMIT;
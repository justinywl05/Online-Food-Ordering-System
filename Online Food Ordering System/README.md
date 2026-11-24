#  Oracle PL/SQL Food Delivery & Order Management System

A normalized enterprise relational database architecture built with **Oracle Database & PL/SQL**. Designed to model and simulate an end-to-end food delivery and restaurant management ecosystem (similar to GrabFood / Foodpanda), handling multi-table transactional workflows, automated discount calculation triggers, and analytical reporting.

---

##  Tech Stack & Key Database Concepts
- **Database Engine:** Oracle Database (PL/SQL)
- **Tooling:** Oracle SQL Developer / SQL*Plus
- **Key Concepts:** Relational Data Modeling (3NF), Referential Integrity Constraints, Stored Procedures, Automated Triggers, Explicit Cursors, Transaction Management, Analytical Reporting

---

##  System Architecture & Schema (18 Tables)
The database structure is modularized into 4 core functional domains:

1. **Member & Subscriptions:** `Member`, `MembershipType`, `MembershipSubscription`, `MemberAddress`
2. **Restaurant & Menu Catalog:** `Restaurant`, `FoodCategory`, `FoodItem`
3. **Ordering & Logistics:** `Orders`, `OrderDetails`, `DeliveryCompany`, `Delivery`, `Payment`
4. **Promotions & Loyalty:** `Promotion`, `PromotionItem`, `PromotionCondition`, `PromotionUsage`, `Voucher`, `VoucherRedemption`

---

##  Repository Structure

```text
├── 01_create_tables.sql                  # DDL: 18 tables, primary/foreign keys, and check constraints
├── 02_insert_sample_data.sql             # DML: Comprehensive enterprise test dataset
│
├── procedures/
│   ├── proc_create_order.sql             # Transactional procedure to validate & place new orders
│   ├── proc_make_payment.sql             # Payment processing procedure with balance validation
│   └── test_verify_order_billing.sql     # Verification query testing order final billing calculations
│
├── triggers/
│   ├── trg_auto_apply_promotion.sql      # Trigger: Auto-detects and applies active promotional discounts
│   ├── trg_update_order_total.sql        # Trigger: Dynamically recalculates order totals on item changes
│   └── test_verify_trigger_totals.sql    # Verification query validating automated trigger calculations
│
├── reports/
│   ├── rpt_member_orders.sql             # Report 1: Formatted summary of member order histories
│   ├── rpt_unpaid_orders.sql             # Report 2: Detailed audit report of outstanding unpaid orders
│   └── rpt_member_promotion_summary.sql  # Report 3: Analytical breakdown of promotion usage & savings
│
└── queries/
    ├── qry_unpaid_orders_view.sql        # Formatted SQL*Plus view query for order balances
    └── qry_sales_performance_analysis.sql # Aggregated sales performance across food categories
```

---

##  Core Business Logic & PL/SQL Features

### 1. Stored Procedures
* **`proc_create_order`**: Validates member eligibility, inserts order master records, and attaches itemized details while ensuring referential integrity.
* **`proc_make_payment`**: Validates payment methods, processes redemption vouchers, reconciles outstanding balances, and transitions order status.

### 2. Autonomous Triggers
* **`trg_auto_apply_promotion`**: Fires on order line insertion; automatically queries active promotional campaigns and deducts the correct discount percentage.
* **`trg_update_order_total`**: Maintains data consistency by recalculating the gross total amount whenever order line items are added, updated, or removed.

### 3. Business Intelligence Reports
* Built using **explicit cursors** and formatted with `DBMS_OUTPUT` to generate structured text-based invoices, member spending reports, and promotion performance audits.

---

##  Execution Guide

Execute the scripts in order using **Oracle SQL Developer** or **SQL*Plus**:

```sql
-- Step 1: Initialize Database Schema
@01_create_tables.sql

-- Step 2: Populate Sample Data
@02_insert_sample_data.sql

-- Step 3: Compile Triggers & Procedures
@triggers/trg_auto_apply_promotion.sql
@triggers/trg_update_order_total.sql
@procedures/proc_create_order.sql
@procedures/proc_make_payment.sql

-- Step 4: Compile & Run Reports
SET SERVEROUTPUT ON;
@reports/rpt_member_orders.sql
@reports/rpt_unpaid_orders.sql
@reports/rpt_member_promotion_summary.sql
```

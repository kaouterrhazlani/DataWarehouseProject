# Data Catalog for Gold Layer in DW_Sales Database

## Purpose
This catalog documents the views created in the **DW_Sales** database for the Gold layer. The views are structured in a star schema for dimensional modeling, used for business intelligence and reporting.
---

## 1. **gold.dim_customers** (Customer Dimension)

This view contains information about customers, joining data from CRM and ERP sources to enrich customer details.

### Columns:

| Column Name        | Data Type     | Description                                                                                   |
|--------------------|-------------- |-----------------------------------------------------------------------------------------------|
| `customer_key`     | BIGINT        | Surrogate key for the customer. Automatically generated to uniquely identify each customer.   |
| `customer_id`      | INT           | Business key for the customer from the CRM system.                                            |
| `customer_number`  | NVARCHAR      | Customer number from the CRM system.                                                          |
| `first_name`       | NVARCHAR      | Customer's first name from the CRM system.                                                    |
| `last_name`        | NVARCHAR      | Customer's last name from the CRM system.                                                     |
| `country`          | NVARCHAR      | Country of the customer from ERP system.                                                    |
| `marital_status`   | NVARCHAR      | Customer's marital status from CRM system.                                                  |
| `gender`           | NVARCHAR      | Customer's gender, determined based on data from CRM and ERP systems.                         |
| `birthdate`        | DATE          | Customer's birthdate from ERP system..                                                                         |
| `create_date`      | DATE          | Date when the customer record was created in the CRM system.                                  |

---

## 2. **gold.dim_products** (Product Dimension)

This view contains information about products, combining details from the CRM and ERP systems to provide product-specific data.

### Columns:

| Column Name                | Data Type    | Description                                                                                 |
|----------------------------|--------------|---------------------------------------------------------------------------------------------|
| `product_key`              | BIGINT       | Surrogate key for the product. Automatically generated to uniquely identify each product.   |
| `product_id`               | INT          | Business key for the product from the CRM system.                                           |
| `product_number`           | NVARCHAR     | Product number from the CRM system.                                                         |
| `product_name`             | NVARCHAR     | Name of the product from the CRM system.                                                    |
| `category_id`              | NVARCHAR     | ID of the product category from the ERP system.                                             |
| `category`                 | NVARCHAR     | Name of the product category from the ERP system.                                           |
| `subcategory`              | NVARCHAR     | Name of the product subcategory from the ERP system.                                        |
| `maintenance`              | NVARCHAR     | Maintenance information for the product from the ERP system.                                |
| `product_cost`             | INT          | Cost of the product from the CRM system.                                                    |
| `product_line`             | NVARCHAR     | Product line the product belongs to from the CRM system.                                    |
| `product_last_update_date` | DATE         | Last date when the product information was updated in the CRM system.                       |

---

## 3. **gold.fact_sales** (Sales Fact)

This view represents the sales data, linking customer and product dimensions to provide a comprehensive view of sales transactions.

### Columns:

| Column Name          | Data Type    | Description                                                                                 |
|----------------------|--------------|---------------------------------------------------------------------------------------------|
| `order_number`       | NVARCHAR     | Unique identifier for the sales order from the CRM system.                                  |
| `product_key`        | BIGINT       | Foreign key from `gold.dim_products` representing the product involved in the sale.         |
| `customer_key`       | BIGINT       | Foreign key from `gold.dim_customers` representing the customer making the purchase.        |
| `order_date`         | DATE         | Date when the order was placed from the CRM system.                                         |
| `shipping_date`      | DATE         | Date when the order was shipped from the CRM system.                                        |
| `due_date`           | DATE         | Date when the order is expected to be delivered from the CRM system.                        |
| `sales_amount`       | INT          | Total sales amount for the order from the CRM system.                                       |
| `quantity`           | INT          | Quantity of products sold in the order from the CRM system.                                 |
| `price`              | INT          | Price of the product sold in the order from the CRM system.                                 |

---

## Surrogate Key Usage:

- **Surrogate Key**: A surrogate key is used as a unique identifier for each record in the dimensional tables (`dim_customers` and `dim_products`). These keys are system-generated (e.g., `AUTO_INCREMENT` or `UUID`) and are not based on business data. They ensure consistency and efficiency when linking data between tables.

  - In `dim_customers`, the `customer_key` is the surrogate key.
  - In `dim_products`, the `product_key` is the surrogate key.
  - In `fact_sales`, the `order_number`, `product_key`, and `customer_key` are used as foreign keys to link to the respective dimension tables.

---

### Notes:
- **Surrogate Key**: These keys are essential in ensuring the data remains consistent, especially when natural keys might change or have duplicates.
- **Relationships**: The views join data from the Silver layer (CRM and ERP sources) to create a clean, dimensional model suitable for reporting and analytics.
- **Performance**: Using surrogate keys helps improve performance in large datasets, especially for join operations, as these keys are smaller and more efficient than natural keys.

This data catalog provides a comprehensive overview of the schema used for reporting and analytics in the `DW_Sales` database. Be sure to refer to it for understanding the structure of the data and the relationships between the different dimensions and fact tables.


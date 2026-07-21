-- ================
-- Create Database
-- ================
CREATE DATABASE churn_prediction;

USE churn_prediction;

-- =======================
-- Create Customers Table
-- =======================
CREATE TABLE customers (
    customerID   VARCHAR(20) PRIMARY KEY,
    gender       VARCHAR(10),
    SeniorCitizen VARCHAR(5),   -- cleaned to Yes/No in Phase 1
    Partner      VARCHAR(5),
    Dependents   VARCHAR(5)
);

-- =======================
-- Create Services Table
-- =======================
CREATE TABLE services (
    customerID       VARCHAR(20),
    PhoneService     VARCHAR(5),
    MultipleLines    VARCHAR(30),
    InternetService  VARCHAR(20),
    OnlineSecurity   VARCHAR(30),
    OnlineBackup     VARCHAR(30),
    DeviceProtection VARCHAR(30),
    TechSupport      VARCHAR(30),
    StreamingTV      VARCHAR(30),
    StreamingMovies  VARCHAR(30),
    FOREIGN KEY (customerID) REFERENCES customers(customerID)
);

-- =======================
-- Create billing Table
-- =======================
CREATE TABLE billing (
    customerID      VARCHAR(20),
    tenure          INT,
    Contract        VARCHAR(20),
    PaperlessBilling VARCHAR(5),
    PaymentMethod   VARCHAR(30),
    MonthlyCharges  DECIMAL(6,2),
    TotalCharges    DECIMAL(8,2),
    Churn           VARCHAR(5),
    FOREIGN KEY (customerID) REFERENCES customers(customerID)
);

-- ============
-- Show Tables
-- ============
DESC TABLE billing;

SELECT * FROM customers;   
SELECT * FROM services;   
SELECT * FROM billing; 


SELECT COUNT(*) FROM customers;   -- expect 7043 (ya cleaning ke baad jitne bache)
SELECT COUNT(*) FROM services;    -- same count
SELECT COUNT(*) FROM billing;     -- same count

-- JOIN karke check karo koi customerID chhoot toh nahi raha
SELECT COUNT(*) FROM customers c
JOIN billing b ON c.customerID = b.customerID
JOIN services s ON c.customerID = s.customerID;
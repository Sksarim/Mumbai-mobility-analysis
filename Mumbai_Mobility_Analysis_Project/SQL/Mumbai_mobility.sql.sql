-- ============================================
-- Mumbai Mobility Analysis
-- Author: Sarim Shaikh
-- Description: Star schema creation and advanced 
-- analytics for Mumbai RTO vehicle registrations (2021-2024).
-- ============================================

CREATE DATABASE IF NOT EXISTS mumbai_mobility;
USE mumbai_mobility;

-- ── 1. Staging Table (Landing Zone) ──
-- Used for initial data import before normalization
CREATE TABLE IF NOT EXISTS staging_raw (
    id BIGINT,
    state VARCHAR(100),
    rto INT,
    rto_name VARCHAR(100),
    year INT,
    month INT,
    metric VARCHAR(100),
    name VARCHAR(150),
    count INT
);

-- ── 2. Dimension Tables ──

-- RTO Office Locations
CREATE TABLE IF NOT EXISTS dim_rto (
    rto_id INT PRIMARY KEY AUTO_INCREMENT,
    rto_code INT,
    rto_name VARCHAR(100) NOT NULL,
    state VARCHAR(10) NOT NULL
);

-- Metric Categories (Fuel, Manufacturer, Class)
CREATE TABLE IF NOT EXISTS dim_metric (
    metric_id INT PRIMARY KEY AUTO_INCREMENT,
    metric VARCHAR(100) NOT NULL,
    name VARCHAR(150) NOT NULL
);

-- Date Dimension
CREATE TABLE IF NOT EXISTS dim_date (
    date_id INT PRIMARY KEY AUTO_INCREMENT,
    year INT NOT NULL,
    month INT NOT NULL
);

-- ── 3. Fact Table ──

CREATE TABLE IF NOT EXISTS fact_registrations (
    fact_id INT PRIMARY KEY AUTO_INCREMENT,
    rto_id INT,
    metric_id INT,
    date_id INT,
    count INT,
    FOREIGN KEY (rto_id) REFERENCES dim_rto(rto_id),
    FOREIGN KEY (metric_id) REFERENCES dim_metric(metric_id),
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id)
);

-- ── 4. Data Loading (ETL) ──

INSERT INTO dim_rto (rto_code, rto_name, state)
SELECT DISTINCT rto, rto_name, state
FROM staging_raw
ORDER BY rto;

INSERT INTO dim_metric (metric, name)
SELECT DISTINCT metric, name
FROM staging_raw
ORDER BY metric, name;

INSERT INTO dim_date (year, month)
SELECT DISTINCT year, month
FROM staging_raw
ORDER BY year, month;

INSERT INTO fact_registrations (rto_id, metric_id, date_id, count)
SELECT 
    r.rto_id,
    m.metric_id,
    d.date_id,
    s.count
FROM staging_raw s
JOIN dim_rto r ON s.rto_name = r.rto_name
JOIN dim_metric m ON s.metric = m.metric AND s.name = m.name
JOIN dim_date d ON s.year = d.year AND s.month = d.month;

-- ── 5. Analytics & Insights ──

-- Query 1: Cumulative Registrations by Zone
-- Shows growth of vehicle base per RTO over time.
SELECT 
    d.year,
    r.rto_name,
    SUM(f.count) AS yearly_registrations,
    SUM(SUM(f.count)) OVER (
        PARTITION BY r.rto_name 
        ORDER BY d.year
    ) AS cumulative_registrations
FROM fact_registrations f
JOIN dim_rto r ON f.rto_id = r.rto_id
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_metric m ON f.metric_id = m.metric_id
WHERE m.metric = 'Registration Class'
GROUP BY d.year, r.rto_name
ORDER BY r.rto_name, d.year;

-- Query 2: Year-on-Year Change
SELECT 
    d.year,
    r.rto_name,
    SUM(f.count) AS total_registrations,
    LAG(SUM(f.count)) OVER (
        PARTITION BY r.rto_name 
        ORDER BY d.year
    ) AS previous_year,
    SUM(f.count) - LAG(SUM(f.count)) OVER (
        PARTITION BY r.rto_name 
        ORDER BY d.year
    ) AS absolute_change
FROM fact_registrations f
JOIN dim_rto r ON f.rto_id = r.rto_id
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_metric m ON f.metric_id = m.metric_id
WHERE m.metric = 'Registration Class'
GROUP BY d.year, r.rto_name
ORDER BY r.rto_name, d.year;

-- Query 3: EV & Fuel Market Share Trends (The corrected CTE)
WITH fuel_trends AS (
    SELECT 
        d.year,
        m.name AS fuel_type,
        SUM(f.count) AS registrations
    FROM fact_registrations f
    JOIN dim_metric m ON f.metric_id = m.metric_id
    JOIN dim_date d ON f.date_id = d.date_id
    WHERE m.metric = 'Registration Fuel'
    AND d.year BETWEEN 2021 AND 2024
    GROUP BY d.year, m.name
),
fuel_ranked AS (
    SELECT
        year,
        fuel_type,
        registrations,
        SUM(registrations) OVER (PARTITION BY year) AS yearly_total,
        ROUND(registrations * 100.0 / SUM(registrations) OVER (PARTITION BY year), 2) AS market_share_pct
    FROM fuel_trends
)
SELECT * FROM fuel_ranked
ORDER BY year, registrations DESC;

-- Query 4: Master Export for Power BI
SELECT 
    d.year,
    r.rto_name,
    m.metric,
    SUM(f.count) AS total_count
FROM fact_registrations f
JOIN dim_rto r ON f.rto_id = r.rto_id
JOIN dim_metric m ON f.metric_id = m.metric_id
JOIN dim_date d ON f.date_id = d.date_id
WHERE d.year BETWEEN 2021 AND 2024
GROUP BY d.year, r.rto_name, m.metric
ORDER BY d.year, r.rto_name;
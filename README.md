
## 📊 Key Insights (TL;DR)
- **Borivali dominates** vehicle registrations across all years
- **EV adoption** grew from ~2% → ~5% (2021–2024)
- **Honda leads** two-wheeler market across zones
- **2023 Decline:** Saw unexpected -5.5% decline likely supply chain issues

# 🚗 Mumbai Urban Mobility Analysis (2021–2025)

> Analyzing vehicle registration trends, EV adoption, and 
> manufacturer dominance across Mumbai's RTO zones using 
> real Maharashtra Government data.

![MySQL](https://img.shields.io/badge/MySQL-8.0-blue)
![PowerBI](https://img.shields.io/badge/PowerBI-Dashboard-yellow)
![Excel](https://img.shields.io/badge/Excel-Cleaned-green)
![Data](https://img.shields.io/badge/Records-63%2C628-orange)

---

## 📌 Problem Statement

Mumbai is one of India's fastest-growing urban centers with 
over 20 million residents. Understanding vehicle registration 
patterns across RTO zones is critical for:
- Urban infrastructure planning
- EV adoption policy monitoring  
- Logistics and transport business strategy

This project analyzes 63,628 real registration records from 
Mumbai's 4 RTO zones (2021–2025) to uncover trends in vehicle 
growth, fuel preferences, and manufacturer dominance.

---

## 📂 Dataset

| Detail | Info |
|--------|------|
| Source | OpenCity.in — Government of Maharashtra |
| Portal | data.opencity.in |
| Records | 63,628 rows across 5 years |
| Coverage | Mumbai Central, East, West, Borivali RTOs |
| Years | 2021–2025 (2025 partial — Jan to Jul) |
| License | Public Domain |

> **Note:** 2025 data excluded from year-on-year comparisons 
> due to partial year coverage (January–July only).

---

## 🛠️ Tools Used

| Tool | Purpose |
|------|---------|
| MySQL 8.0 | Database design, ETL pipeline, analysis queries |
| Excel | Data cleaning, inspection, documentation |
| Power BI Desktop | Interactive dashboard with DAX measures |
| GitHub | Version control and portfolio presentation |

---

## 🗄️ Database: `mumbai_mobility`

Single database with Star Schema architecture:
**Why Star Schema?**
Instead of one flat table, data is split into dimension 
and fact tables — the industry standard for analytics 
databases used at companies like Mahindra and Delhivery.

---

## 🧹 Data Cleaning Steps

| Issue | Cause | Fix |
|-------|-------|-----|
| #NAME? errors in name column | Values starting with '-' misread as Excel formulas | Find & Replace '=-' with '-' |
| Zero count rows (12,744) | Valid absence of RTO activity | Retained — zeros are meaningful |
| Inconsistent RTO naming | R.T.O.BORIVALI vs MUMBAI (CENTRAL) format | Documented, kept as-is |
| 2025 partial year | Data collected Jan–Jul only | Excluded from YoY comparisons |

**Replacements made per file:**

| File | Total Rows | #NAME? Fixed |
|------|------------|--------------|
| 2021 | 12,745 | 1,896 |
| 2022 | 14,125 | 2,064 |
| 2023 | 15,265 | 2,184 |
| 2024 | 14,689 | 2,016 |
| 2025 | 6,809 | 960 |
| **Total** | **63,628** | **10,120** |

---

## 🔍 SQL Analysis

### Techniques Used:
- Star Schema design with foreign key constraints
- Window Functions: `SUM() OVER`, `LAG()`, `RANK()`
- CTEs (Common Table Expressions)
- Market share calculation using partitioned window functions
- Multi-table JOINs across fact and dimension tables

### Query Summary:

| # | Query | SQL Technique |
|---|-------|---------------|
| 1 | Cumulative registrations by zone | `SUM() OVER PARTITION` |
| 2 | Year-on-year change per zone | `LAG()` window function |
| 3 | Top 10 manufacturers per zone | CTE + `RANK()` |
| 4 | EV & fuel market share trends | CTE + market share calc |
| 5 | Master summary for Power BI | Multi-table JOIN + GROUP BY |

---

## 📊 Power BI Dashboard

### 3 Interactive Pages:

**Page 1 — Overview**
- KPI Cards: Total Registrations, YoY Growth %, Top RTO Zone
- Clustered column chart: registrations by zone and year
- Line chart: growth trajectory by zone
- Slicers: year and metric category filter

**Page 2 — Fuel & EV Trends**
- 100% Stacked Area: fuel market share shift 2021–2024
- Donut chart: single year fuel mix snapshot
- Matrix: exact EV market share % by year
- Dynamic EV Market Share % DAX measure

**Page 3 — Manufacturer Analysis + Drill-Through**
- Bar chart: top manufacturers ranked by zone
- Rank slicer: filter top N manufacturers dynamically
- Drill-through: CTRL+Click any bar → zone detail page

### DAX Measures:

```dax
-- Year on year registration growth rate
YoY Growth % = 
VAR CurrentYear = MAX(master_summary[year])
VAR CurrentTotal = 
    CALCULATE(
        SUM(master_summary[total_count]),
        master_summary[year] = CurrentYear)
VAR PreviousTotal = 
    CALCULATE(
        SUM(master_summary[total_count]),
        master_summary[year] = CurrentYear - 1)
RETURN
    DIVIDE(CurrentTotal - PreviousTotal, PreviousTotal, 0) * 100

-- Combined EV fuel type market share
EV Market Share % = 
VAR EVRegistrations = 
    CALCULATE(
        SUM(ev_fuel_trends[registrations]),
        ev_fuel_trends[fuel_type] = "PURE EV" ||
        ev_fuel_trends[fuel_type] = "PLUG IN HYBRID" ||
        ev_fuel_trends[fuel_type] = "ELECTRIC(BOV)")
VAR TotalRegistrations = SUM(ev_fuel_trends[registrations])
RETURN
    DIVIDE(EVRegistrations, TotalRegistrations, 0) * 100

-- Dynamic top performing RTO zone
Top RTO Zone = 
MAXX(
    TOPN(1,
        SUMMARIZE(master_summary,
            master_summary[rto_name],
            "ZoneTotal", SUM(master_summary[total_count])),
        [ZoneTotal], DESC),
    master_summary[rto_name])
```

---

## 💡 Key Insights

**1. 🏆 Borivali Consistently Dominates**
Borivali RTO ranks #1 every year 2021–2024, reflecting 
North Mumbai's rapid suburban expansion across Kandivali, 
Dahisar and Mira Road corridor.

**2. ⚡ EV Revolution Just Beginning**
Pure EV category absent from records until 2024, reaching 
1.53% market share in its debut year. Combined EV share 
(Pure EV + Plug-in Hybrid + Electric BOV) grew from ~2% 
to ~5% between 2021–2024.

**3. 🏍️ Honda Rules Mumbai Roads**
Honda Two Wheelers ranks #1 in most RTO zones, driven by 
Activa dominance in Mumbai's two-wheeler commute culture.

**4. 🚗 KIA's Surprise Entry**
Despite being a newer brand, KIA cracks top 10 in Mumbai 
Central and West zones — suggesting premium car adoption 
concentrated in urban business districts.

**5. 📉 Mumbai West Softening**
Soft declining trend visible 2021–2023, suggesting possible 
market saturation in established western residential zones.

**6. 📊 Unexpected 2023 Dip**
YoY growth of -5.51% in 2023 despite expected post-COVID 
recovery — likely reflecting vehicle price inflation and 
global semiconductor shortage impact on supply.

**7. 🌿 Ethanol Policy Visible in Data**
Petrol/Ethanol fuel category appears from 2023 onwards, 
directly reflecting Maharashtra's ethanol blending policy 
implementation — real government policy visible in data.

---

## ▶️ How to Run This Project

### Step 1 — SQL Setup:
```sql
-- 1. Run schema creation file
source sql/01_create_schema.sql

-- 2. Import master CSV into staging_raw
-- Use MySQL Workbench Table Data Import Wizard
-- File: data/processed/mumbai_rto_master.csv

-- 3. Run analysis queries
source sql/02_analysis_queries.sql
```

### Step 2 — Power BI:
1. Install [Power BI Desktop](https://powerbi.microsoft.com/downloads/) (free)
2. Open `powerbi/mumbai_mobility_dashboard.pbix`
3. Update data source paths if prompted
4. Use **CTRL+Click** on manufacturer bars for drill-through

### Step 3 — Requirements:
- MySQL 8.0+
- Microsoft Excel
- Power BI Desktop (free)

---

## 👤 Author

**Sarim Shaikh** *Aspiring Data Analyst*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/sarim-shaikh-6312a7336)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Sksarim)

---

## 📄 License

Data sourced from [OpenCity.in](https://data.opencity.in) 
under Public Domain license.
Project code and analysis — MIT License.

# Telco Customer Churn Analytics

End-to-end churn analysis pipeline — from raw customer data through MySQL, SQL analysis, EDA, ML-based churn prediction, Plotly interactive visuals, to a Power BI business dashboard.

---

## 📁 Project Structure

```
telco-customer-churn-analytics/
│
├── data/
│   ├── raw/
│   │   └── telco_churn_raw.csv              # original Kaggle download, untouched
│   ├── cleaned/
│   │   └── telco_churn_cleaned.csv          # Phase 1 output → loaded into MySQL
│   └── model_output/
│       └── churn_predictions.csv            # Phase 5 output → imported into Power BI
│
├── scripts/
│   ├── data_cleaning.py                     # Phase 1: nulls, dtypes, duplicates
│   └── schema.sql                     # Phase 2: cleaned CSV → MySQL tables
│
├── sql/
│   └── analysis_queries.sql                 # Phase 3: 15-20 business queries
│
├── notebooks/
│   ├── 01_eda_matplotlib_seaborn.ipynb      # Phase 4
│   ├── 02_feature_engineering_ml.ipynb      # Phase 5: encoding, model, feature importance
│   └── 03_plotly_interactive_viz.ipynb      # Phase 6
│
├── models/
│   └── churn_model.pkl                      # Phase 5: saved trained model
│
├── powerbi/
│   └── telco_churn_dashboard.pbix           # Phase 7
│
├── images/
│   ├── chart_images/                        # Matplotlib/Seaborn/Plotly chart exports
│   └── dashboard_images/                    # Power BI dashboard page screenshots
│
└── README.md                                 # Phase 8: workflow + consolidated insights
```

---

## 🧩 Phase 1 — Data Acquisition & Cleaning

- Loaded the raw CSV and profiled it with `.info()`, `.isnull().sum()`, `.duplicated().sum()`
- Converted `TotalCharges` to numeric using `pd.to_numeric(errors='coerce')` — blanks became NaN
- Converted the `SeniorCitizen` column from 0/1 to Yes/No, for consistency with the other Yes/No columns
- Verified `customerID` uniqueness — no exact duplicate rows found

**Key Insight:** 11 customers (0.16%) had a blank `TotalCharges` value, and all of them had `tenure = 0`. This wasn't random missingness — it was logical (new customers who hadn't been billed yet). So instead of mean imputation, `TotalCharges` was set to 0 — a business-logic-driven decision that's more defensible than mean imputation.

---

## 🗄️ Phase 2 — MySQL Schema Design & Load

Built three normalized tables from the cleaned CSV and loaded them:
- `customers`
- `services`
- `billing`

---

## 🔍 Phase 3 — SQL Analysis

`sql/analysis_queries.sql` contains 15–20 business-focused SQL queries — CTEs, window functions, aggregations — covering things like contract-wise churn rate, revenue by tenure bucket, and payment-method-wise risk.

---

## 📊 Phase 4 — Python EDA (Matplotlib/Seaborn)

`notebooks/01_eda_matplotlib_seaborn.ipynb` covers the exploratory analysis:
- Examined distribution patterns across contract type, tenure, monthly charges, and internet service
- Identified correlation trends with churn (e.g., higher churn among month-to-month contracts and fiber optic users)
- These patterns formed the basis for feature selection in Phase 5 (ML)

---

## 🤖 Phase 5 — Feature Engineering + ML

In `notebooks/02_feature_engineering_ml.ipynb`:
- Encoded categorical features and trained the model
- Extracted feature importance
- Predicted **churn probability** for every customer (saved to `churn_predictions.csv`)
- This churn probability was reused in both Phase 6 (Plotly) and Phase 7 (Power BI) — the model's output flowed directly into the business dashboard

---

## 📈 Phase 6 — Plotly Interactive Visuals

`notebooks/03_plotly_interactive_viz.ipynb` uses the Phase 5 churn probability in interactive charts, for risk segmentation and customer-level drill-down.

---

## 📊 Phase 7 — Power BI Dashboard

A 4-page dashboard built on the `churn_predictions_full` table (the ML model's output):

**Page 1 — Overview**
![Dashboard Page 1](https://github.com/codebyavneesh/telco-customer-churn-analytics/blob/main/churn-prediction-retentional-analysis/images/dashboard_images/dashboard_image1.png)
- 7K Total Customers, 2K Churned, Churn Rate 0.27
- Total MRR ₹456.12K, MRR at Risk ₹137.01K
- Month-to-month contracts are the largest segment at 55.02% of customers
- The 0–12 month tenure group has the most customers (2.2K) — new customers carry the highest retention risk
- Churn split: 73.46% No vs 26.54% Yes

**Page 2 — Churn Rate Drivers**
![Dashboard Page 2](https://github.com/codebyavneesh/telco-customer-churn-analytics/blob/main/churn-prediction-retentional-analysis/images/dashboard_images/dashboard_image2.png)
- Month-to-month contract churn rate is 0.43, versus just 0.03 for two-year contracts — the strongest churn driver
- SeniorCitizen = Yes churns at 0.42, versus 0.24 for No — almost double
- Electronic check payment method has the highest churn rate (47%)
- Fiber optic internet service has the highest churn rate at 0.42

**Page 3 — Segmentation**
![Dashboard Page 3](https://github.com/codebyavneesh/telco-customer-churn-analytics/blob/main/churn-prediction-retentional-analysis/images/dashboard_images/dashboard_image3.png)
- The ₹81–100 MonthlyCharges bucket has the most customers (1764) — a high-charge zone where churn risk also runs higher
- Detailed breakdown of contract distribution and tenure-wise customer spread

**Page 4 — Risk & Financial Impact (ML-driven)**
![Dashboard Page 4](https://github.com/codebyavneesh/telco-customer-churn-analytics/blob/main/churn-prediction-retentional-analysis/images/dashboard_images/dashboard_image4.png)
- Converted the model's churn probability into business metrics: **₹137.01K MRR at Risk**, 2K High Risk Customers, 0.30 Revenue Loss %
- Fiber optic customers have the highest MRR at Risk (₹0.11M)
- The customer-level table also shows individual churn probability — actionable at the per-customer level, not just in aggregate

---

## 📝 Phase 8 — Consolidated Business Insights

- **Contract type is the strongest churn driver** — month-to-month customers churn (0.43) at ~14x the rate of two-year contract customers (0.03)
- **Senior citizens churn at almost double the rate** (0.42 vs 0.24) — this segment needs targeted retention
- **Fiber optic + Electronic check is the highest-risk combination** — both metrics individually top the list too
- **₹137K in MRR is currently at risk** due to high-probability churners
- **New customers (0–12 months tenure) are the largest at-risk pool** — retention efforts are needed right after onboarding

### Recommendations
- Incentivize month-to-month customers toward long-term contracts (discounts/loyalty offers)
- Run a targeted retention campaign for the Fiber optic + Electronic check segment
- Proactively reach out to the top-N customers by churn probability (from the Phase 5 ML output)
- Design an onboarding-phase retention program for new customers (0–12 months)

---

## ⚙️ How to Run

1. `pip install -r requirements.txt`
2. `python scripts/data_cleaning.py` — Phase 1
3. `python scripts/load_to_mysql.py` — Phase 2 (set MySQL credentials in `.env`)
4. Run `sql/analysis_queries.sql` in a MySQL client — Phase 3
5. Run `notebooks/01_eda_matplotlib_seaborn.ipynb` — Phase 4
6. Run `notebooks/02_feature_engineering_ml.ipynb` — Phase 5 (generates `churn_predictions.csv`)
7. Run `notebooks/03_plotly_interactive_viz.ipynb` — Phase 6
8. Open `powerbi/telco_churn_dashboard.pbix` and refresh `churn_predictions.csv` as the data source — Phase 7

---

## 🛠️ Skills Used

- **Python** — Pandas, NumPy (data cleaning, feature engineering)
- **Data Visualization** — Matplotlib, Seaborn (EDA), Plotly (interactive visuals)
- **SQL** — MySQL (schema design, CTEs, window functions, business queries)
- **Machine Learning** — scikit-learn (churn prediction model, feature importance)
- **Business Intelligence** — Power BI, DAX (multi-page dashboard, measures)
- **Version Control** — Git, GitHub

---

## 👤 Author

**Avneesh**
GitHub: [@codebyavneesh](https://github.com/codebyavneesh)
LinkedIn: [linkedin.com/in/codebyavneesh](https://linkedin.com/in/codebyavneesh)

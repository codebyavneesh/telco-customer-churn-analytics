# Telco Customer Churn Analytics

End-to-end churn analysis pipeline — raw customer data se lekar MySQL, SQL analysis, EDA, ML-based churn prediction, Plotly interactive visuals, aur ek Power BI business dashboard tak.

---

## 📁 Project Structure

```
telco-customer-churn-analytics/
│
├── data/
│   ├── raw/
│   │   └── telco_churn_raw.csv              # original Kaggle download, untouched
│   ├── cleaned/
│   │   └── telco_churn_cleaned.csv          # Phase 1 output → MySQL me load
│   └── model_output/
│       └── churn_predictions.csv            # Phase 5 output → Power BI me import
│
├── scripts/
│   ├── data_cleaning.py                     # Phase 1: nulls, dtypes, duplicates
│   └── load_to_mysql.py                     # Phase 2: cleaned CSV → MySQL tables
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

- Raw CSV load karke `.info()`, `.isnull().sum()`, `.duplicated().sum()` se profile kiya
- `TotalCharges` ko `pd.to_numeric(errors='coerce')` se numeric convert kiya — blanks NaN ban gaye
- `SeniorCitizen` column ko 0/1 se Yes/No mein convert kiya, taaki baaki Yes/No columns ke saath consistent rahe
- `customerID` unique verify kiya, exact duplicate rows nahi mile

**Key Insight:** 11 customers (0.16%) ka `TotalCharges` blank tha, aur un sabka `tenure = 0` tha. Ye random missingness nahi thi — logical thi (naye customers, abhi tak bill generate hi nahi hua). Isliye mean se impute karne ke bajaye, `TotalCharges = 0` set kiya — business-logic-driven decision, jo mean-imputation se zyada defensible hai.

---

## 🗄️ Phase 2 — MySQL Schema Design & Load

Cleaned CSV se teen normalized tables banayi aur load ki:
- `customers`
- `services`
- `billing`

---

## 🔍 Phase 3 — SQL Analysis

`sql/analysis_queries.sql` mein 15–20 business-focused SQL queries — CTEs, window functions, aggregations — jaise contract-wise churn rate, tenure buckets ke hisab se revenue, payment method-wise risk, etc.

---

## 📊 Phase 4 — Python EDA (Matplotlib/Seaborn)

`notebooks/01_eda_matplotlib_seaborn.ipynb` mein exploratory analysis:
- Contract type, tenure, monthly charges, aur internet service ke distribution patterns dekhe
- Churn ke saath correlation trends identify kiye (jaise month-to-month contracts aur fiber optic users mein churn zyada dikha)
- Ye patterns hi baad mein Phase 5 (ML) ke liye feature selection ka base bane

---

## 🤖 Phase 5 — Feature Engineering + ML

`notebooks/02_feature_engineering_ml.ipynb` mein:
- Categorical features encode kiye, model train kiya
- Feature importance nikali
- Model se har customer ke liye **churn probability** predict ki (`churn_predictions.csv` mein saved)
- Ye churn probability hi Phase 6 (Plotly) aur Phase 7 (Power BI) dono mein reuse hui — model output seedha business dashboard tak pahuncha

---

## 📈 Phase 6 — Plotly Interactive Visuals

`notebooks/03_plotly_interactive_viz.ipynb` mein Phase 5 ki churn probability ko interactive charts mein use kiya — risk segments aur customer-level drill-down ke liye.

---

## 📊 Phase 7 — Power BI Dashboard

4-page dark/light themed dashboard, `churn_predictions_full` table (ML model ka output) par based:

**Page 1 — Overview**
![Dashboard Page 1](https://github.com/codebyavneesh/telco-customer-churn-analytics/blob/main/churn-prediction-retentional-analysis/images/dashboard_images/dashboard_image1.png)
- 7K Total Customers, 2K Churned, Churn Rate 0.27
- Total MRR ₹456.12K, MRR at Risk ₹137.01K
- Month-to-month contract 55.02% customers ke saath sabse bada segment
- 0–12 months tenure group mein sabse zyada customers (2.2K) — naye customers ka retention risk sabse zyada
- Churn split: 73.46% No vs 26.54% Yes

**Page 2 — Churn Rate Drivers**
![Dashboard Page 2](https://github.com/codebyavneesh/telco-customer-churn-analytics/blob/main/churn-prediction-retentional-analysis/images/dashboard_images/dashboard_image2.png)
- Month-to-month contract churn rate 0.43, jabki Two-year sirf 0.03 — sabse strong churn driver
- SeniorCitizen = Yes churn rate 0.42, jabki No sirf 0.24 — almost double
- Electronic check payment method churn rate sabse zyada (47%)
- Fiber optic internet service churn rate 0.42 — sabse high internet-service segment

**Page 3 — Segmentation**
![Dashboard Page 3](https://github.com/codebyavneesh/telco-customer-churn-analytics/blob/main/churn-prediction-retentional-analysis/images/dashboard_images/dashboard_image3.png)
- MonthlyCharges ₹81–100 bucket mein sabse zyada customers (1764) — high-charge zone, jahan churn risk bhi zyada
- Contract distribution aur tenure-wise customer spread ka detailed breakdown

**Page 4 — Risk & Financial Impact (ML-driven)**
![Dashboard Page 4](https://github.com/codebyavneesh/telco-customer-churn-analytics/blob/main/churn-prediction-retentional-analysis/images/dashboard_images/dashboard_image4.png)
- Model se nikli churn probability ko business metrics mein convert kiya: **₹137.01K MRR at Risk**, 2K High Risk Customers, 0.30 Revenue Loss %
- Fiber optic customers ka MRR at Risk sabse zyada (₹0.11M)
- Customer-level table mein individual churn probability bhi visible — sirf aggregate nahi, per-customer actionable output

---

## 📝 Phase 8 — Consolidated Business Insights

- **Contract type sabse strong churn driver hai** — month-to-month customers ka churn rate (0.43) two-year contract customers (0.03) se ~14x zyada hai
- **Senior citizens almost double rate se churn karte hain** (0.42 vs 0.24) — is segment ke liye targeted retention zaroori
- **Fiber optic + Electronic check combination highest-risk segment hai** — dono metrics mein individually bhi top pe hai
- **₹137K MRR currently risk mein hai** high-probability churners ki wajah se
- **Naye customers (0–12 months tenure) sabse bada at-risk pool hain** — onboarding ke turant baad retention effort zaroori

### Recommendations
- Month-to-month customers ko long-term contract ki taraf incentivize karo (discount/loyalty offer)
- Fiber optic + Electronic check segment ke liye targeted retention campaign chalao
- Churn probability table (Phase 5 ML output) ke top-N customers ko proactively reach out karo
- Naye customers (0–12 months) ke liye onboarding-phase retention program design karo

---

## ⚙️ How to Run

1. `pip install -r requirements.txt`
2. `python scripts/data_cleaning.py` — Phase 1
3. `python scripts/load_to_mysql.py` — Phase 2 (MySQL credentials `.env` mein set karo)
4. `sql/analysis_queries.sql` ko MySQL client mein run karo — Phase 3
5. `notebooks/01_eda_matplotlib_seaborn.ipynb` run karo — Phase 4
6. `notebooks/02_feature_engineering_ml.ipynb` run karo — Phase 5 (`churn_predictions.csv` generate hoga)
7. `notebooks/03_plotly_interactive_viz.ipynb` run karo — Phase 6
8. `powerbi/telco_churn_dashboard.pbix` open karo, `churn_predictions.csv` ko data source ke roop mein refresh karo — Phase 7

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

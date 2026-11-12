# Consumer Complaints Analysis

## Project Overview

This project analyses 62,516 consumer complaint records covering May 2017 to August 2023. The objective is to identify complaint patterns, understand company response performance, examine complaint forwarding intervals and uncover insights that can support customer-service improvements and operational decision-making.

The analysis uses PostgreSQL for data preparation and investigation, and Power BI for interactive reporting and visualisation.

## Project Objectives

- Assess data quality and identify missing or inconsistent values.
- Identify financial products generating the highest complaint volumes.
- Investigate common consumer complaint issues.
- Analyse annual complaint trends.
- Evaluate company timely response performance.
- Examine complaint forwarding intervals.
- Explore submission channels and geographical complaint distribution.
- Develop evidence-based business recommendations.

## Tools and Technologies

| Tool | Purpose |
|---|---|
| PostgreSQL | Data validation, querying and analysis |
| DBeaver | SQL development and database management |
| Power BI Desktop | Interactive dashboards and visualisation |
| Microsoft Excel | Initial dataset inspection and preparation |

## Dataset Description

The dataset contains 62,516 complaint records and 12 original columns.

Key fields include:

- Complaint ID
- Submission channel
- Date submitted
- Date received
- State
- Product and sub-product
- Issue and sub-issue
- Company public response
- Company response to consumer
- Timely response status

**Reporting period:** 1 May 2017 – 28 August 2023.

## Data Preparation and Quality Assessment

The original dataset was preserved and imported into PostgreSQL. A clean SQL table and reusable analysis view were created.

The following checks were conducted:

| Quality check | Result |
|---|---:|
| Total records | 62,516 |
| Unique complaint IDs | 62,516 |
| Duplicate complaint IDs | 0 |
| Invalid date sequences | 0 |
| Negative forwarding intervals | 0 |
| Missing sub-product values | 7 |
| Missing sub-issue values | 10,858 |
| Missing public response values | 2,175 |
| Missing timely response values | 1,494 |

### Data quality decisions

- Missing values were investigated rather than automatically replaced.
- All 1,494 missing timely-response values belonged to complaints marked In progress.
- Missing public response values were retained because the field is optional.
- Missing sub-issue values were retained and investigated at product-and-issue level.
- No leading or trailing whitespace was detected in the key categorical fields.

## SQL Analysis

PostgreSQL was used to conduct the analysis, including:

- Aggregations using `COUNT()`, `SUM()` and `AVG()`.
- Filtering and grouping using `WHERE` and `GROUP BY`.
- Conditional classification using `CASE`.
- Common Table Expressions (CTEs).
- Window functions, including `LAG()`.
- Conditional aggregation using `FILTER`.
- Date calculations and percentage comparisons.
- Reusable analytical views.

The analysis view includes calculated forwarding intervals, complaint years and complaint months.

## Key Findings

### 1. Product distribution

Checking or savings accounts represented 39.69% of complaints, while credit cards or prepaid cards accounted for 25.91%.

Together, these categories represented **65.60% of all complaints**.

### 2. Leading complaint issue

Managing an account was the most frequently reported issue, accounting for 15,109 complaints (24.17%).

All 15,109 complaints classified under this issue belonged to checking or savings accounts.

### 3. Annual complaint trends

Complaint volumes increased from 5,394 in 2017 to 12,953 in 2022, representing approximately 140.1% growth.

2022 recorded the highest full-year complaint volume. The 2023 dataset is incomplete and ends on 28 August.

### 4. Company timely response performance

The recorded timely response rate was **96.06%**, based on 58,619 timely and 2,403 untimely responses.

Another 1,494 complaints were in progress and had no recorded timeliness status. These were excluded from the rate calculation.

### 5. Complaint forwarding intervals

- Average forwarding interval: 1.22 days.
- Same-day forwarding: 49,634 complaints (79.39%).
- Complaints forwarded after 30 days: 435.
- Longest recorded forwarding interval: 275 days.

The forwarding interval measures the difference between the complaint submission date and the date received by the company. It does not measure complaint resolution time.

### 6. Submission channels

Web submissions accounted for 72.66% of complaints, followed by referrals at 17.22%.

### 7. Geographical distribution

California recorded the highest complaint volume, with 13,709 complaints (21.93%).

California, Florida, Texas and New York together represented approximately 46.92% of all complaints.

These figures represent complaint counts, not population-adjusted complaint rates.

## Business Recommendations

1. **Prioritise product-level investigations:** Focus on checking and savings accounts and credit card or prepaid card complaints. Investigate recurring account servicing, transaction and customer communication issues.

2. **Strengthen response monitoring:** Monitor in-progress complaints, timely response performance and exceptional forwarding delays to improve operational oversight.

3. **Use trend analysis for service improvement:** Investigate the increase in complaints through 2022 and regularly monitor recurring issues to support resource allocation and customer-service improvements.

## Power BI Dashboard

The project includes four interactive reporting pages:

1. **Executive Overview:** Complaint volume, key performance indicators, monthly trends and product distribution.
2. **Product & Issue Analysis:** Product categories, common complaint issues and their relationships.
3. **Company Response Analysis:** Response status, timely versus untimely responses and public response patterns.
4. **Trends & Forwarding Analysis:** Annual trends, forwarding interval distribution and forwarding performance by product.

## Project Structure

The repository can be organised as follows:

```text
Bank-of-America-Complaints-Analysis/
│
├── data/
│   └── Consumer_Complaints.xlsx
│
├── sql/
│   └── Bank_of_America_Complaints_Analysis.sql
│
├── powerbi/
│   └── Bank_of_America_Complaints_Analysis.pbix
│
├── screenshots/
│   ├── executive_overview.png
│   ├── product_issue_analysis.png
│   ├── company_response_analysis.png
│   └── forwarding_trends.png
│
└── README.md
```

*Only include files that are actually available in the repository. If the dataset is not redistributed, document its source and access instructions instead.*

## Limitations

- The dataset ends on 28 August 2023; therefore, 2023 is a partial year.
- Complaint volumes do not establish complaint rates relative to customer populations.
- Missing values in optional and in-progress fields were retained.
- Timely response performance does not independently establish resolution quality or customer satisfaction.
- Forwarding intervals do not represent company resolution times.
- The analysis identifies patterns and associations but does not establish causation.

## Conclusion

This project demonstrates the use of SQL and Power BI to transform raw consumer complaint records into structured business insights.

It combines data quality assessment, SQL analysis, KPI development, trend investigation and interactive reporting to support evidence-based decision-making.


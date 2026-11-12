-- 1. CREATE PROJECT SCHEMA

CREATE SCHEMA IF NOT EXISTS complaints;


-- 2. SET ACTIVE SCHEMA

SET search_path TO complaints, public;


-- 3. VERIFY SOURCE DATA

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT complaint_id) AS unique_complaints,
    MIN(date_submitted) AS earliest_submission,
    MAX(date_submitted) AS latest_submission
FROM complaints.complaints_raw_fixed;

/*========================================================
  SECTION 2: DATA QUALITY ASSESSMENT
  2.1 Missing values by column
========================================================*/

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE submitted_via IS NULL OR BTRIM(submitted_via) = ''
    ) AS missing_submitted_via,

    COUNT(*) FILTER (
        WHERE date_submitted IS NULL
    ) AS missing_date_submitted,

    COUNT(*) FILTER (
        WHERE date_received IS NULL
    ) AS missing_date_received,

    COUNT(*) FILTER (
        WHERE state IS NULL OR BTRIM(state) = ''
    ) AS missing_state,

    COUNT(*) FILTER (
        WHERE product IS NULL OR BTRIM(product) = ''
    ) AS missing_product,

    COUNT(*) FILTER (
        WHERE sub_product IS NULL OR BTRIM(sub_product) = ''
    ) AS missing_sub_product,

    COUNT(*) FILTER (
        WHERE issue IS NULL OR BTRIM(issue) = ''
    ) AS missing_issue,

    COUNT(*) FILTER (
        WHERE sub_issue IS NULL OR BTRIM(sub_issue) = ''
    ) AS missing_sub_issue,

    COUNT(*) FILTER (
        WHERE company_public_response IS NULL
           OR BTRIM(company_public_response) = ''
    ) AS missing_public_response,

    COUNT(*) FILTER (
        WHERE company_response_to_consumer IS NULL
           OR BTRIM(company_response_to_consumer) = ''
    ) AS missing_company_response,

    COUNT(*) FILTER (
        WHERE timely_response IS NULL OR BTRIM(timely_response) = ''
    ) AS missing_timely_response

FROM complaints.complaints_raw_fixed;

/*========================================================
  2.2 DUPLICATE RECORDS
========================================================*/

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT complaint_id) AS unique_complaints,
    COUNT(*) - COUNT(DISTINCT complaint_id) AS duplicate_ids
FROM complaints.complaints_raw_fixed;


/*========================================================
  2.3 DATE VALIDATION
========================================================*/

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE date_received < date_submitted
    ) AS invalid_date_sequences,
    COUNT(*) FILTER (
        WHERE date_received = date_submitted
    ) AS same_day_forwarding,
    MIN(date_submitted) AS earliest_submission,
    MAX(date_submitted) AS latest_submission
FROM complaints.complaints_raw_fixed;

/*========================================================
  2.4 CATEGORICAL VALUE VALIDATION
========================================================*/

-- Check response status categories

SELECT
    company_response_to_consumer,
    COUNT(*) AS total_complaints
FROM complaints.complaints_raw_fixed
GROUP BY company_response_to_consumer
ORDER BY total_complaints DESC;


-- Check timely response categories

SELECT
    timely_response,
    COUNT(*) AS total_complaints
FROM complaints.complaints_raw_fixed
GROUP BY timely_response
ORDER BY total_complaints DESC;



-- Check leading/trailing spaces in key text fields

SELECT
    COUNT(*) FILTER (
        WHERE submitted_via <> BTRIM(submitted_via)
    ) AS channel_spaces,

    COUNT(*) FILTER (
        WHERE state <> BTRIM(state)
    ) AS state_spaces,

    COUNT(*) FILTER (
        WHERE product <> BTRIM(product)
    ) AS product_spaces,

    COUNT(*) FILTER (
        WHERE issue <> BTRIM(issue)
    ) AS issue_spaces

FROM complaints.complaints_raw_fixed;

/*========================================================
  SECTION 3: CREATE ANALYSIS VIEW
========================================================*/

CREATE OR REPLACE VIEW complaints.complaints_analysis AS

SELECT
    complaint_id,
    submitted_via,
    date_submitted,
    date_received,
    state,
    product,
    sub_product,
    issue,
    sub_issue,
    company_public_response,
    company_response_to_consumer,
    timely_response,

    -- Calculate CFPB forwarding interval
    (date_received - date_submitted)
        AS forwarding_interval_days,

    -- Extract complaint year
    EXTRACT(YEAR FROM date_submitted)::INT
        AS complaint_year,

    -- Extract complaint month
    DATE_TRUNC('month', date_submitted)::DATE
        AS complaint_month

FROM complaints.complaints_raw_fixed;


-- Verify the analysis view

SELECT COUNT(*) AS total_analysis_records
FROM complaints.complaints_analysis;

/*========================================================
  SECTION 4: BUSINESS ANALYSIS
  4.1 Complaint distribution by product
========================================================*/

SELECT
    product,
    COUNT(*) AS total_complaints,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*)
         FROM complaints.complaints_analysis),
        2
    ) AS complaint_percentage
FROM complaints.complaints_analysis
GROUP BY product
ORDER BY total_complaints DESC;

/*========================================================
  4.2 TOP 10 COMPLAINT ISSUES
========================================================*/

SELECT
    issue,
    COUNT(*) AS total_complaints,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*)
         FROM complaints.complaints_analysis),
        2
    ) AS complaint_percentage
FROM complaints.complaints_analysis
GROUP BY issue
ORDER BY COUNT(*) DESC
LIMIT 10;

/*========================================================
  4.3 PRODUCT BREAKDOWN OF MANAGING AN ACCOUNT
========================================================*/

SELECT
    product,
    COUNT(*) AS total_complaints,
    ROUND(
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM complaints.complaints_analysis
            WHERE issue = 'Managing an account'
        ),
        2
    ) AS percentage_of_account_issues
FROM complaints.complaints_analysis
WHERE issue = 'Managing an account'
GROUP BY product
ORDER BY total_complaints DESC;

/*========================================================
  4.4 ANNUAL COMPLAINT TRENDS
========================================================*/

SELECT
    complaint_year,
    COUNT(*) AS total_complaints
FROM complaints.complaints_analysis
GROUP BY complaint_year
ORDER BY complaint_year;

/*========================================================
  4.5 YEAR-ON-YEAR COMPLAINT GROWTH
========================================================*/

WITH annual_complaints AS (
    SELECT
        complaint_year,
        COUNT(*) AS total_complaints
    FROM complaints.complaints_analysis
    GROUP BY complaint_year
),
yearly_comparison AS (
    SELECT
        complaint_year,
        total_complaints,
        LAG(total_complaints) OVER (
            ORDER BY complaint_year
        ) AS previous_year
    FROM annual_complaints
)
SELECT
    complaint_year,
    total_complaints,
    previous_year,
    ROUND(
        (total_complaints - previous_year) * 100.0
        / NULLIF(previous_year, 0),
        2
    ) AS year_on_year_change_pct
FROM yearly_comparison
ORDER BY complaint_year;

/*========================================================
  4.6 COMPANY TIMELY RESPONSE PERFORMANCE
========================================================*/

SELECT
    COUNT(*) AS total_complaints,
    ROUND(AVG(forwarding_interval_days), 2) AS average_days,
    MIN(forwarding_interval_days) AS minimum_days,
    MAX(forwarding_interval_days) AS maximum_days
FROM complaints.complaints_analysis;

SELECT
    forwarding_category,
    COUNT(*) AS total_complaints
FROM (
    SELECT
        CASE
            WHEN forwarding_interval_days = 0 THEN 'Same day'
            WHEN forwarding_interval_days <= 3 THEN '1-3 days'
            WHEN forwarding_interval_days <= 7 THEN '4-7 days'
            WHEN forwarding_interval_days <= 30 THEN '8-30 days'
            ELSE 'Over 30 days'
        END AS forwarding_category
    FROM complaints.complaints_analysis
) AS forwarding_groups
GROUP BY forwarding_category;

--Section 4.9 — Forwarding intervals by product
SELECT
    product,
    COUNT(*) AS total_complaints,
    ROUND(AVG(forwarding_interval_days), 2) AS average_forwarding_days,
    MAX(forwarding_interval_days) AS maximum_forwarding_days
FROM complaints.complaints_analysis
GROUP BY product
ORDER BY average_forwarding_days DESC;

/*========================================================
  4.10 TOP 10 LONGEST FORWARDING INTERVALS
========================================================*/

SELECT
    complaint_id,
    product,
    issue,
    date_submitted,
    date_received,
    forwarding_interval_days
FROM complaints.complaints_analysis
ORDER BY forwarding_interval_days DESC
LIMIT 10;

/*========================================================
  4.11 COMPLAINTS BY SUBMISSION CHANNEL
========================================================*/

SELECT
    submitted_via,
    COUNT(*) AS total_complaints
FROM complaints.complaints_analysis
GROUP BY submitted_via
ORDER BY COUNT(*) DESC;

/*========================================================
  4.12 COMPLAINTS BY STATE
========================================================*/

SELECT
    state,
    COUNT(*) AS total_complaints
FROM complaints.complaints_analysis
GROUP BY state
ORDER BY COUNT(*) DESC
LIMIT 10;

/*========================================================
  SECTION 5: KEY BUSINESS FINDINGS
========================================================

1. PRODUCT CONCENTRATION
   Checking or savings accounts account for 39.69%
   of complaints, while credit cards/prepaid cards
   account for 25.91%.

   Combined share: 65.60%.


2. LEADING COMPLAINT ISSUE
   Managing an account is the most frequent issue,
   representing 15,109 complaints (24.17%).

   All 15,109 records belong to checking or savings
   accounts.


3. ANNUAL COMPLAINT TRENDS
   2022 recorded the highest full-year complaint
   volume at 12,953.

   Complaints increased by approximately 140.1%
   between 2017 and 2022.

   2023 is incomplete and should not be compared
   directly with full calendar years.


4. COMPANY TIMELY RESPONSE
   Timely response rate: 96.06%.
   Untimely responses: 2,403.
   In-progress cases without a timeliness status: 1,494.

   The rate uses only records with Yes/No statuses.


5. FORWARDING PERFORMANCE
   Average forwarding interval: 1.22 days.
   Same-day forwarding: 79.39%.
   Longest forwarding interval: 275 days.
   Complaints forwarded after 30 days: 435.


6. SUBMISSION CHANNELS
   Web submissions account for 72.66% of complaints.
   Referral submissions account for 17.22%.


7. GEOGRAPHICAL DISTRIBUTION
   California has the highest complaint volume:
   13,709 complaints (21.93%).

   The top four states account for 46.92%
   of all complaints.


========================================================
  SECTION 6: BUSINESS RECOMMENDATIONS
========================================================

1. PRODUCT-LEVEL INVESTIGATION
   Prioritise checking/savings and credit card/prepaid
   complaints. Investigate recurring account servicing,
   transaction and customer communication issues.

2. RESPONSE MONITORING
   Strengthen monitoring of in-progress complaints,
   response timeliness and exceptional forwarding delays.

3. TREND MONITORING
   Investigate the increase in complaint volumes
   through 2022 and monitor recurring issues to
   support service improvement and resource allocation.

========================================================
  END OF PROJECT ANALYSIS
========================================================
*/

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT complaint_id) AS unique_complaints,
    COUNT(*) FILTER (
        WHERE forwarding_interval_days < 0
    ) AS negative_forwarding_intervals
FROM complaints.complaints_analysis;
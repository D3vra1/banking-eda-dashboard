SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL
SELECT 'branches', COUNT(*) FROM branches
UNION ALL
SELECT 'cards', COUNT(*) FROM cards
UNION ALL
SELECT 'loans', COUNT(*) FROM loans
UNION ALL
SELECT 'merchants', COUNT(*) FROM merchants
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions;

-- Relationship map + orphan check
SELECT 
    (SELECT COUNT(*) FROM accounts a WHERE NOT EXISTS (SELECT 1 FROM customers c WHERE c.customer_id = a.customer_id)) AS accounts_without_customer,
    (SELECT COUNT(*) FROM cards cd WHERE NOT EXISTS (SELECT 1 FROM accounts a WHERE a.account_id = cd.account_id)) AS cards_without_account,
    (SELECT COUNT(*) FROM loans l WHERE NOT EXISTS (SELECT 1 FROM customers c WHERE c.customer_id = l.customer_id)) AS loans_without_customer,
    (SELECT COUNT(*) FROM transactions t WHERE NOT EXISTS (SELECT 1 FROM accounts a WHERE a.account_id = t.account_id)) AS txns_without_account,
    (SELECT COUNT(*) FROM transactions t WHERE NOT EXISTS (SELECT 1 FROM merchants m WHERE m.merchant_id = t.merchant_id)) AS txns_without_merchant;

    --A) NULL check across key columns
SELECT 
    SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) AS null_email,
    SUM(CASE WHEN credit_score IS NULL THEN 1 ELSE 0 END) AS null_credit_score,
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS null_city
FROM customers;

SELECT 
    SUM(CASE WHEN balance_usd IS NULL THEN 1 ELSE 0 END) AS null_balance,
    SUM(CASE WHEN account_type IS NULL THEN 1 ELSE 0 END) AS null_type
FROM accounts;

SELECT 
    SUM(CASE WHEN amount_usd IS NULL THEN 1 ELSE 0 END) AS null_amount,
    SUM(CASE WHEN transaction_date IS NULL THEN 1 ELSE 0 END) AS null_date
FROM transactions;

-----B) Duplicate check (real duplicates, not just repeated IDs)
-- Exact duplicate transactions (same account, merchant, amount, timestamp)
SELECT account_id, merchant_id, amount_usd, transaction_date, COUNT(*) AS occurrences
FROM transactions
GROUP BY account_id, merchant_id, amount_usd, transaction_date
HAVING COUNT(*) > 1;

-----C) Weird/impossible values
-- Negative or zero balances, negative transaction amounts, absurd credit scores
SELECT COUNT(*) AS negative_balances FROM accounts WHERE balance_usd < 0;
SELECT COUNT(*) AS zero_or_negative_txns FROM transactions WHERE amount_usd <= 0;
SELECT MIN(credit_score) AS min_score, MAX(credit_score) AS max_score FROM customers;

------D) Date range sanity
SELECT MIN(transaction_date) AS earliest, MAX(transaction_date) AS latest FROM transactions;
SELECT MIN(open_date) AS earliest_account, MAX(open_date) AS latest_account FROM accounts;

SELECT DISTINCT account_type FROM accounts;
SELECT DISTINCT card_type FROM cards;
SELECT DISTINCT city FROM branches;

----no nulls, no duplicates, no invalid values, no categorical inconsistencies.Data is genuinely clean across all 7 tables

-- Account balances
SELECT 
    account_type,
    COUNT(*) AS num_accounts,
    AVG(balance_usd) AS avg_balance,
    MIN(balance_usd) AS min_balance,
    MAX(balance_usd) AS max_balance,
    STDEV(balance_usd) AS stddev_balance
FROM accounts
GROUP BY account_type;

-- Transaction amounts
SELECT 
    COUNT(*) AS num_transactions,
    AVG(amount_usd) AS avg_txn,
    MIN(amount_usd) AS min_txn,
    MAX(amount_usd) AS max_txn,
    STDEV(amount_usd) AS stddev_txn
FROM transactions;

-- Loan amounts
SELECT 
    COUNT(*) AS num_loans,
    AVG(loan_amount) AS avg_loan,
    MIN(loan_amount) AS min_loan,
    MAX(loan_amount) AS max_loan,
    AVG(interest_rate) AS avg_interest_rate
FROM loans;

-- Credit score distribution snapshot
SELECT 
    AVG(credit_score) AS avg_score,
    MIN(credit_score) AS min_score,
    MAX(credit_score) AS max_score,
    STDEV(credit_score) AS stddev_score
FROM customers;

----- Transaction amount distribution in buckets
SELECT 
    CASE 
        WHEN amount_usd < 1000 THEN '0-1000'
        WHEN amount_usd < 2500 THEN '1000-2500'
        WHEN amount_usd < 5000 THEN '2500-5000'
        WHEN amount_usd < 7500 THEN '5000-7500'
        ELSE '7500-10000'
    END AS amount_bucket,
    COUNT(*) AS num_transactions
FROM transactions
GROUP BY 
    CASE 
        WHEN amount_usd < 1000 THEN '0-1000'
        WHEN amount_usd < 2500 THEN '1000-2500'
        WHEN amount_usd < 5000 THEN '2500-5000'
        WHEN amount_usd < 7500 THEN '5000-7500'
        ELSE '7500-10000'
    END
ORDER BY amount_bucket;

-- Credit score distribution in buckets
SELECT
    CASE 
        WHEN credit_score < 500 THEN '300-499 (Poor)'
        WHEN credit_score < 650 THEN '500-649 (Fair)'
        WHEN credit_score < 750 THEN '650-749 (Good)'
        ELSE '750-850 (Excellent)'
    END AS score_band,
    COUNT(*) AS num_customers
FROM customers
GROUP BY 
    CASE 
        WHEN credit_score < 500 THEN '300-499 (Poor)'
        WHEN credit_score < 650 THEN '500-649 (Fair)'
        WHEN credit_score < 750 THEN '650-749 (Good)'
        ELSE '750-850 (Excellent)'
    END
ORDER BY score_band;

-----Yearly trend (are transactions growing over time?)
SELECT 
    YEAR(transaction_date) AS txn_year,
    COUNT(*) AS num_transactions,
    SUM(amount_usd) AS total_volume,
    AVG(amount_usd) AS avg_txn_size
FROM transactions
GROUP BY YEAR(transaction_date)
ORDER BY txn_year;

------ Top 10 highest-activity accounts (window function: RANK)
SELECT TOP 10
    account_id,
    COUNT(*) AS num_transactions,
    SUM(amount_usd) AS total_spent,
    RANK() OVER (ORDER BY SUM(amount_usd) DESC) AS spend_rank
FROM transactions
GROUP BY account_id
ORDER BY total_spent DESC;

------ Customers with multiple accounts AND loans (cross-sell pattern)
SELECT 
    c.customer_id,
    COUNT(DISTINCT a.account_id) AS num_accounts,
    COUNT(DISTINCT l.loan_id) AS num_loans
FROM customers c
LEFT JOIN accounts a ON a.customer_id = c.customer_id
LEFT JOIN loans l ON l.customer_id = c.customer_id
GROUP BY c.customer_id
HAVING COUNT(DISTINCT a.account_id) > 1 AND COUNT(DISTINCT l.loan_id) > 0
ORDER BY num_accounts DESC;

------a proper month-over-month growth
SELECT 
    YEAR(transaction_date) AS yr,
    MONTH(transaction_date) AS mo,
    SUM(amount_usd) AS monthly_volume,
    LAG(SUM(amount_usd)) OVER (ORDER BY YEAR(transaction_date), MONTH(transaction_date)) AS prev_month_volume,
    SUM(amount_usd) - LAG(SUM(amount_usd)) OVER (ORDER BY YEAR(transaction_date), MONTH(transaction_date)) AS mom_change
FROM transactions
GROUP BY YEAR(transaction_date), MONTH(transaction_date)
ORDER BY yr, mo;



                                                                                --Monthly trend--


CREATE VIEW vw_monthly_trend AS
SELECT 
    YEAR(transaction_date) AS txn_year,
    MONTH(transaction_date) AS txn_month,
    COUNT(*) AS num_transactions,
    SUM(amount_usd) AS monthly_volume,
    AVG(amount_usd) AS avg_txn_size
FROM transactions
GROUP BY YEAR(transaction_date), MONTH(transaction_date);

                                                                                --Top accounts by spend--
CREATE VIEW vw_top_accounts AS
SELECT 
    account_id,
    COUNT(*) AS num_transactions,
    SUM(amount_usd) AS total_spent,
    RANK() OVER (ORDER BY SUM(amount_usd) DESC) AS spend_rank
FROM transactions
GROUP BY account_id;

                                                                ---Credit score bands---
CREATE VIEW vw_credit_score_bands AS
SELECT 
    CASE 
        WHEN credit_score < 500 THEN '300-499 (Poor)'
        WHEN credit_score < 650 THEN '500-649 (Fair)'
        WHEN credit_score < 750 THEN '650-749 (Good)'
        ELSE '750-850 (Excellent)'
    END AS score_band,
    COUNT(*) AS num_customers
FROM customers
GROUP BY 
    CASE 
        WHEN credit_score < 500 THEN '300-499 (Poor)'
        WHEN credit_score < 650 THEN '500-649 (Fair)'
        WHEN credit_score < 750 THEN '650-749 (Good)'
        ELSE '750-850 (Excellent)'
    END;

                                                                    ---Account type summary---
CREATE VIEW vw_account_summary AS
SELECT 
    account_type,
    COUNT(*) AS num_accounts,
    AVG(balance_usd) AS avg_balance,
    SUM(balance_usd) AS total_balance
FROM accounts
GROUP BY account_type;

SELECT * FROM vw_monthly_trend ORDER BY txn_year, txn_month;

                                                                            ----AVG Score------
CREATE VIEW vw_avg_credit_score AS
SELECT AVG(CAST(credit_score AS FLOAT)) AS avg_score FROM customers;

SELECT * FROM vw_avg_credit_score;
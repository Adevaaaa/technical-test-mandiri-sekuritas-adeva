# Technical Test Data Analyst Mandiri Sekuritas
Link Looker : https://lookerstudio.google.com/reporting/8af3d642-1038-4096-8c2a-7af41d25718b


### This technical test uses the following programs:
+ PostgreSQL
+ Looker Studio
+ Google Spreadsheet

  
### Data Model
The queries operate on a main table, transaksi_new, which is created by joining three source tables: transaksi, users, and cards.

+ transaksi: Contains transaction details such as amount, date, and location.
+ users: Stores user information including demographics and financial data like income and debt.
+ cards: Holds credit card details like brand, type, and credit limit.

### Input Data
When entering data, first create a table with each column and data type. Then upload the CSV file into that table.

### Merge Data
Merge data to obtain more useful data
```
[SQL]
CREATE TABLE transaksi_new AS
WITH transaksi_cte AS (
    SELECT 
        t.id AS transaksi_id,
	t.client_id,
	t.card_id,
        t.date,
        t.amount,
        t.merchant_city,
        u.id AS user_id,
        u.current_age,
        u.gender,
        u.per_capita_income,
        u.yearly_income,
        u.total_debt,
        u.credit_score,
        u.num_credit_cards,
        k.card_brand,
        k.card_type,
        k.credit_limit
    FROM transaksi t
    JOIN users u ON t.client_id = u.id
    JOIN cards k ON t.card_id = k.id
)
SELECT * FROM transaksi_cte;
```

### Data Preparation
To change the data type from Text to numeric and remove the $
```
[SQL]
UPDATE transaksi
SET amount = REPLACE(amount, '$', ''),
    per_capita_income = REPLACE(per_capita_income, '$', ''), 
    yearly_income = REPLACE(yearly_income, '$', ''), 
    total_debt = REPLACE(total_debt, '$', ''), 
    credit_limit = REPLACE(credit_limit,'$','');
ALTER TABLE transaksi
    ALTER COLUMN amount TYPE NUMERIC USING amount::NUMERIC
    ALTER COLUMN per_capita_income TYPE NUMERIC USING per_capita_income::NUMERIC,
    ALTER COLUMN yearly_income TYPE NUMERIC USING yearly_income::NUMERIC,
    ALTER COLUMN total_debt TYPE NUMERIC USING total_debt::NUMERIC,
    ALTER COLUMN credit_limit TYPE NUMERIC USING credit_limit::NUMERIC;
```


### Summary Data
Create several summaries to be used on the dashboard
```
[SQL]
WITH transaksi_summary AS (
    SELECT 
        COUNT(*) AS total_transaksi,
        COUNT(DISTINCT user_id) AS total_pengguna
    FROM transaksi_new
)
SELECT
    total_transaksi,
    total_pengguna,
    ROUND(total_transaksi * 1.0 / total_pengguna, 2) AS rata_rata_transaksi_per_pengguna
FROM transaksi_summary;
```

### Total Transaction Per Month
To create data on the number of transactions per month
```
[SQL]
WITH transaksi_per_bulan AS (
    SELECT 
        TO_CHAR(date, 'YYYY-MM') AS bulan,
        COUNT(*) AS jumlah_transaksi
    FROM transaksi_new
    GROUP BY TO_CHAR(date, 'YYYY-MM')
    ORDER BY bulan
)
SELECT 
    bulan,
    jumlah_transaksi
FROM transaksi_per_bulan;
```

### Top 5 Merchant State
Take the top 5 state merchant data
```
[SQL]
WITH merchat_top AS(
SELECT
    merchant_state,
    SUM(amount::numeric) AS total_amount
FROM transaksi
GROUP BY merchant_state
ORDER BY merchant_state
)
SELECT
	merchant_state,
	total_amount
FROM merchat_top
ORDER BY total_amount DESC
LIMIT 6;
```

### Users Card Type
to obtain user card type data
```
[SQL]
WITH cards_dist AS(
	SELECT 
		card_type,
		COUNT(id) AS sum_card
	FROM cards
	GROUP BY card_type
)
SELECT 
	card_type,
	sum_card
FROM cards_dist;
```

### Total Transaction Per Card Type
```
[SQL]
WITH transaksi_per_card AS (
    SELECT 
        EXTRACT(YEAR FROM date) AS tahun,
        card_type,
        COUNT(*) AS jumlah_transaksi
    FROM transaksi_new
    GROUP BY EXTRACT(YEAR FROM date), card_type
)
SELECT 
    tahun,
    card_type,
    jumlah_transaksi
FROM transaksi_per_card
ORDER BY tahun, card_type;
```

### Total Amount Per Users
```
[SQL]
WITH user_transaksi AS(
	SELECT 
    	EXTRACT(YEAR FROM date) AS tahun,
    	client_id,
    	SUM(amount) AS total_amount
	FROM transaksi_new
	GROUP BY EXTRACT(YEAR FROM date), client_id
	ORDER BY tahun, total_amount DESC
)
SELECT
	tahun,
	client_id,
	total_amount
FROM user_transaksi;
```

### Yearly Income VS Spending
```
[SQL]
WITH transaksi_client AS (
    SELECT 
        EXTRACT(YEAR FROM date) AS tahun,
        client_id,
        yearly_income,
		credit_score,
        SUM(amount) AS total_amount
    FROM transaksi_new
    GROUP BY EXTRACT(YEAR FROM date), client_id, yearly_income,credit_score
)
SELECT 
    tahun,
    client_id,
    yearly_income,
    total_amount,
	credit_score
FROM transaksi_client
ORDER BY tahun, client_id;
```

### Debt to Income Ratio
```
[SQL]
WITH client_dti AS (
    SELECT 
        client_id,
        total_debt,
        yearly_income,
        credit_score,
        ROUND(total_debt::numeric / NULLIF(yearly_income, 0), 2) AS dti
    FROM transaksi_new
    GROUP BY client_id, total_debt, yearly_income, credit_score
)
SELECT 
    client_id,
    dti,
    credit_score
FROM client_dti
ORDER BY client_id;
```

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

SELECT * FROM transaksi_new ORDER BY transaksi_id ASC;

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

WITH gmv_per_bulan AS (
    SELECT 
        TO_CHAR(date, 'YYYY-MM') AS bulan,
        SUM(amount) AS gmv
    FROM transaksi_new
    GROUP BY TO_CHAR(date, 'YYYY-MM')
    ORDER BY bulan
)
SELECT 
    bulan,
    gmv
FROM gmv_per_bulan;

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

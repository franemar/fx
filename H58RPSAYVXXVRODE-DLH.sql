CREATE USER "RAW_DATA" NO AUTHENTICATION;
CREATE USER "STANDARDIZED_DATA" NO AUTHENTICATION;
CREATE USER "DIMENSIONAL_MODEL" NO AUTHENTICATION;

-- 1. Currencies dimension
CREATE TABLE dimensional_model.dim_currencies (
    code CHAR(3) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    symbol VARCHAR(5),
    decimal_places NUMBER(2),
    is_active NUMBER(1) DEFAULT 1 NOT NULL
);

-- 2. Exchange Rates Table
CREATE TABLE dimensional_model.fact_exchange_rates (
    id RAW(16) DEFAULT SYS_GUID() PRIMARY KEY,
    base_currency CHAR(3) NOT NULL REFERENCES dimensional_model.dim_currencies(code),
    quote_currency CHAR(3) NOT NULL REFERENCES dimensional_model.dim_currencies(code),
    bid_rate DECIMAL(18, 8) NOT NULL,
    ask_rate DECIMAL(18, 8) NOT NULL,
    mid_rate DECIMAL(18, 8) NOT NULL,
    source VARCHAR(50),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL--,
    
    --CONSTRAINT uq_currency_pair_time UNIQUE (base_currency, quote_currency, timestamp)
);

-- Index for fast lookup of the latest exchange rates
CREATE INDEX idx_rates_pair_time ON dimensional_model.fact_exchange_rates (base_currency, quote_currency, timestamp DESC);

--RFC UUID query
SELECT regexp_replace(rawtohex(sys_guid()), 
       '([A-F0-9]{8})([A-F0-9]{4})([A-F0-9]{4})([A-F0-9]{4})([A-F0-9]{12})', 
       '\1-\2-\3-\4-\5') AS uuid_v4
FROM dual;



-- PENDING --

-- 3. FX Transactions Table
CREATE TABLE fx_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL,
    from_currency CHAR(3) NOT NULL REFERENCES currencies(code),
    to_currency CHAR(3) NOT NULL REFERENCES currencies(code),
    from_amount DECIMAL(18, 4) NOT NULL,
    to_amount DECIMAL(18, 4) NOT NULL,
    applied_rate DECIMAL(18, 8) NOT NULL,
    fee_amount DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tx_account ON fx_transactions (account_id, created_at DESC);

-- Rename price_per_m3 to price_buy_per_m3 and add price_sell_per_m3
ALTER TABLE materials 
RENAME COLUMN price_per_m3 TO price_buy_per_m3;

ALTER TABLE materials
ADD COLUMN price_sell_per_m3 DECIMAL(10,2) NOT NULL DEFAULT 0;

-- Add new columns to vehicle_discharge table
ALTER TABLE vehicle_discharge
ADD COLUMN price_buy DECIMAL(15,2) NOT NULL DEFAULT 0,
ADD COLUMN price_sell DECIMAL(15,2) NOT NULL DEFAULT 0,
ADD COLUMN profit DECIMAL(15,2) GENERATED ALWAYS AS (price_sell - price_buy) STORED;

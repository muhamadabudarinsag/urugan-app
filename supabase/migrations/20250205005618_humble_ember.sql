-- Add new columns to vehicles table
ALTER TABLE vehicles
ADD COLUMN provider VARCHAR(100),
ADD COLUMN price_per_day DECIMAL(10,2),
ADD COLUMN price_per_month DECIMAL(10,2),
ADD COLUMN price_per_hour DECIMAL(10,2);

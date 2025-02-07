/*
  # Update Driver Costs Date Handling

  1. Changes
    - Add start_date and end_date columns to driver_costs table
    - Add single_date column for daily entries
    - Add check constraint to ensure proper date handling

  2. Security
    - Maintain existing RLS policies
*/

ALTER TABLE driver_costs
ADD COLUMN start_date DATE,
ADD COLUMN end_date DATE,
ADD COLUMN single_date DATE,
ADD CONSTRAINT check_date_type CHECK (
  (cost_type = 'daily' AND single_date IS NOT NULL AND start_date IS NULL AND end_date IS NULL) OR
  (cost_type = 'monthly' AND single_date IS NULL AND start_date IS NULL AND end_date IS NULL) OR
  (cost_type = 'range' AND single_date IS NULL AND start_date IS NOT NULL AND end_date IS NOT NULL)
);

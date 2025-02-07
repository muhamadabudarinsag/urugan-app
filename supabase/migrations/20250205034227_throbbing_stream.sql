/*
  # Update Heavy Equipment Rentals Schema

  1. Changes
    - Add new columns for rental type and duration
    - Add columns for date ranges and monthly rentals
    - Add columns for hourly rentals

  2. New Columns
    - rental_type: Type of rental (range, month, day)
    - start_date: Start date for range rentals
    - end_date: End date for range rentals
    - rental_month: Month for monthly rentals
    - rental_year: Year for monthly rentals
    - is_full_day: Boolean for daily rentals
    - hours: Number of hours for hourly rentals
*/

ALTER TABLE heavy_equipment_rentals
ADD COLUMN rental_type ENUM('range', 'month', 'day') NOT NULL DEFAULT 'day',
ADD COLUMN start_date DATE,
ADD COLUMN end_date DATE,
ADD COLUMN rental_month INT,
ADD COLUMN rental_year INT,
ADD COLUMN is_full_day BOOLEAN DEFAULT TRUE,
ADD COLUMN hours INT;

/*
  # Add pricing fields to drivers table

  1. Changes
    - Add price_per_day column to drivers table
    - Add price_per_month column to drivers table
    
  2. Description
    This migration adds pricing fields to track driver costs on a daily and monthly basis
*/

ALTER TABLE drivers
ADD COLUMN price_per_day DECIMAL(10,2) DEFAULT 0.00,
ADD COLUMN price_per_month DECIMAL(10,2) DEFAULT 0.00;

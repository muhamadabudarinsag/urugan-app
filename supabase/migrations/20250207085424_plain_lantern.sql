/*
  # Add Supplier and Bank Account Tables

  1. New Tables
    - suppliers
      - id (Primary Key)
      - name (Supplier name)
      - owner_name (Owner name)
      - city (City)
      - project_location (Project location)
      - logo_url (Logo URL)
      - signature_url (Signature URL)
      - created_at (Timestamp)
    
    - bank_accounts
      - id (Primary Key)
      - bank_name (Bank name)
      - account_number (Account number)
      - account_name (Account holder name)
      - created_at (Timestamp)

  2. Security
    - Enable RLS on both tables
    - Add policies for authenticated users
*/

-- Create suppliers table
CREATE TABLE IF NOT EXISTS suppliers (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  owner_name VARCHAR(255) NOT NULL,
  city VARCHAR(100) NOT NULL,
  project_location TEXT NOT NULL,
  logo_url TEXT,
  signature_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create bank_accounts table
CREATE TABLE IF NOT EXISTS bank_accounts (
  id SERIAL PRIMARY KEY,
  bank_name VARCHAR(100) NOT NULL,
  account_number VARCHAR(50) NOT NULL UNIQUE,
  account_name VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow authenticated users to read suppliers"
  ON suppliers FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to read bank_accounts"
  ON bank_accounts FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert suppliers"
  ON suppliers FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to insert bank_accounts"
  ON bank_accounts FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update suppliers"
  ON suppliers FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to update bank_accounts"
  ON bank_accounts FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to delete suppliers"
  ON suppliers FOR DELETE
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to delete bank_accounts"
  ON bank_accounts FOR DELETE
  TO authenticated
  USING (true);

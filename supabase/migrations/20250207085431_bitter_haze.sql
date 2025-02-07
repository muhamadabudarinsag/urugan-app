/*
  # Add Invoices Table

  1. New Tables
    - invoices
      - id (Primary Key)
      - invoice_number (Unique invoice number)
      - supplier_id (Foreign key to suppliers)
      - invoice_date (Date)
      - due_date (Date)
      - start_period (Date)
      - end_period (Date)
      - total_amount (Decimal)
      - status (enum: draft, sent, paid, cancelled)
      - created_at (Timestamp)

  2. Security
    - Enable RLS
    - Add policies for authenticated users
*/

-- Create invoices table
CREATE TABLE IF NOT EXISTS invoices (
  id SERIAL PRIMARY KEY,
  invoice_number VARCHAR(50) UNIQUE NOT NULL,
  supplier_id INTEGER REFERENCES suppliers(id) ON DELETE RESTRICT,
  invoice_date DATE NOT NULL,
  due_date DATE NOT NULL,
  start_period DATE NOT NULL,
  end_period DATE NOT NULL,
  total_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
  status VARCHAR(20) CHECK (status IN ('draft', 'sent', 'paid', 'cancelled')) DEFAULT 'draft',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create invoice_items table to store details
CREATE TABLE IF NOT EXISTS invoice_items (
  id SERIAL PRIMARY KEY,
  invoice_id INTEGER REFERENCES invoices(id) ON DELETE CASCADE,
  material_name VARCHAR(255) NOT NULL,
  total_volume DECIMAL(15,2) NOT NULL,
  unit_price DECIMAL(15,2) NOT NULL,
  total_price DECIMAL(15,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow authenticated users to read invoices"
  ON invoices FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to read invoice_items"
  ON invoice_items FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert invoices"
  ON invoices FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to insert invoice_items"
  ON invoice_items FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update invoices"
  ON invoices FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to update invoice_items"
  ON invoice_items FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to delete invoices"
  ON invoices FOR DELETE
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to delete invoice_items"
  ON invoice_items FOR DELETE
  TO authenticated
  USING (true);

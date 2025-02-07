/*
  # Add Heavy Equipment Fuel Costs Table

  1. New Tables
    - `heavy_equipment_fuel_costs`
      - `id` (int, primary key)
      - `equipment_id` (int, foreign key)
      - `fuel_amount` (decimal)
      - `price_per_liter` (decimal) 
      - `total_cost` (decimal)
      - `date` (date)
      - `created_at` (timestamp)

  2. Security
    - Add foreign key constraint to heavy_equipment table
*/

CREATE TABLE IF NOT EXISTS `heavy_equipment_fuel_costs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `equipment_id` int(11) NOT NULL,
  `fuel_amount` decimal(10,2) NOT NULL,
  `price_per_liter` decimal(10,2) NOT NULL,
  `total_cost` decimal(15,2) NOT NULL,
  `date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  FOREIGN KEY (`equipment_id`) REFERENCES `heavy_equipment` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

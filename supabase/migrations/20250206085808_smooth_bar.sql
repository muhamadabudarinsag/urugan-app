-- Add this table definition after your existing tables
CREATE TABLE IF NOT EXISTS `fuel_prices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `price_per_liter` decimal(10,2) NOT NULL,
  `effective_date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

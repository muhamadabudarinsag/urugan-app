-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3307
-- Generation Time: Feb 07, 2025 at 01:08 PM
-- Server version: 11.4.0-MariaDB
-- PHP Version: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `urugan`
--

-- --------------------------------------------------------

--
-- Table structure for table `activity_logs`
--

CREATE TABLE `activity_logs` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `username` varchar(255) NOT NULL,
  `action` enum('add','edit','delete','login','logout') NOT NULL,
  `description` text NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `activity_logs`
--

INSERT INTO `activity_logs` (`id`, `user_id`, `username`, `action`, `description`, `created_at`) VALUES
(1, 5, 'admin', 'login', 'User logged in', '2025-01-20 08:32:19'),
(2, 5, 'admin', 'login', 'User logged in', '2025-01-20 09:36:56'),
(3, 5, 'admin', 'login', 'User logged in', '2025-01-20 09:41:17'),

-- --------------------------------------------------------

--
-- Table structure for table `bank_accounts`
--

CREATE TABLE `bank_accounts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `bank_name` varchar(100) NOT NULL,
  `account_number` varchar(50) NOT NULL,
  `account_name` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `bank_accounts`
--

INSERT INTO `bank_accounts` (`id`, `bank_name`, `account_number`, `account_name`, `created_at`) VALUES
(1, 'br', '32', '32', '2025-02-07 09:34:02');

-- --------------------------------------------------------

--
-- Table structure for table `drivers`
--

CREATE TABLE `drivers` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `license_number` varchar(50) NOT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `price_per_day` decimal(10,0) DEFAULT 0,
  `price_per_month` decimal(10,0) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `drivers`
--

INSERT INTO `drivers` (`id`, `name`, `license_number`, `phone_number`, `created_at`, `price_per_day`, `price_per_month`) VALUES
(16, 'AHMAD SAYFUL', '2314123123', '34213123', '2024-10-12 19:35:06', 42323, 32323),
(17, 'HARTONO EDWIN', '5888787', '2324123', '2024-10-13 07:28:01', 32323, 32323),
(18, 'SAMSUL ARIF', '494581823', '485812313', '2024-10-17 22:17:24', 32323, 32323),
(30, 'SUMAN', '3233', '32323', '2025-02-05 01:30:13', 3232323, 232323);

-- --------------------------------------------------------

--
-- Table structure for table `driver_costs`
--

CREATE TABLE `driver_costs` (
  `id` int(11) NOT NULL,
  `driver_id` int(11) NOT NULL,
  `cost_type` varchar(255) DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `driver_costs`
--

INSERT INTO `driver_costs` (`id`, `driver_id`, `cost_type`, `amount`, `date`, `created_at`) VALUES
(172, 16, 'daily', 42323.00, '2025-02-04', '2025-02-05 11:00:42'),
(173, 16, 'daily', 423.00, '2025-02-05', '2025-02-05 11:09:29'),
(174, 16, 'daily', 42323.00, '2025-02-06', '2025-02-06 11:33:55'),
(175, 16, 'daily', 42323.00, '2025-02-07', '2025-02-07 06:43:02');

-- --------------------------------------------------------

--
-- Table structure for table `driver_fuel_costs`
--

CREATE TABLE `driver_fuel_costs` (
  `id` int(11) NOT NULL,
  `fuel_cost` decimal(10,0) NOT NULL,
  `driver_cost` decimal(10,0) NOT NULL,
  `date` date NOT NULL,
  `vehicle_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `driver_fuel_costs`
--

INSERT INTO `driver_fuel_costs` (`id`, `fuel_cost`, `driver_cost`, `date`, `vehicle_id`) VALUES
(5, 23423, 32323, '2024-10-13', 16),
(7, 232, 32, '2024-10-13', 16),
(9, 2313, 2323, '2024-10-18', 16),
(10, 2314213, 3213123, '2024-10-18', 17),
(11, 255555, 255555, '2024-10-22', 16),
(12, 23, 23, '2024-12-23', 16);

-- --------------------------------------------------------

--
-- Table structure for table `fuel_prices`
--

CREATE TABLE `fuel_prices` (
  `id` int(11) NOT NULL,
  `price_per_liter` decimal(10,0) NOT NULL,
  `effective_date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `fuel_prices`
--

INSERT INTO `fuel_prices` (`id`, `price_per_liter`, `effective_date`, `created_at`) VALUES
(5, 8500, '2025-02-06', '2025-02-06 09:04:58');

-- --------------------------------------------------------

--
-- Table structure for table `heavy_equipment`
--

CREATE TABLE `heavy_equipment` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `license_plate` varchar(50) NOT NULL,
  `driver_id` int(11) DEFAULT NULL,
  `fuel_capacity` int(11) NOT NULL,
  `hourly_rate` decimal(10,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `price_per_day` decimal(10,2) DEFAULT 0.00,
  `price_per_month` decimal(10,2) DEFAULT 0.00,
  `notes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `heavy_equipment`
--

INSERT INTO `heavy_equipment` (`id`, `name`, `license_plate`, `driver_id`, `fuel_capacity`, `hourly_rate`, `created_at`, `price_per_day`, `price_per_month`, `notes`) VALUES
(1, 'Truk Banda', 'D 23 CC', 17, 2000, 3000000.00, '2025-02-04 10:06:33', 32.00, 323.00, 'aa');

-- --------------------------------------------------------

--
-- Table structure for table `heavy_equipment_fuel_costs`
--

CREATE TABLE `heavy_equipment_fuel_costs` (
  `id` int(11) NOT NULL,
  `equipment_id` int(11) NOT NULL,
  `fuel_amount` decimal(10,0) NOT NULL,
  `price_per_liter` decimal(10,0) NOT NULL,
  `total_cost` decimal(15,0) NOT NULL,
  `date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `heavy_equipment_fuel_costs`
--

INSERT INTO `heavy_equipment_fuel_costs` (`id`, `equipment_id`, `fuel_amount`, `price_per_liter`, `total_cost`, `date`, `created_at`) VALUES
(9, 1, 333, 8500, 2830500, '2025-02-06', '2025-02-06 10:25:26'),
(10, 1, 5, 8500, 42500, '2025-02-07', '2025-02-07 06:42:22'),
(11, 1, 5, 8500, 42500, '2025-02-07', '2025-02-07 06:42:30');

-- --------------------------------------------------------

--
-- Table structure for table `heavy_equipment_rentals`
--

CREATE TABLE `heavy_equipment_rentals` (
  `id` int(11) NOT NULL,
  `equipment_id` int(11) NOT NULL,
  `cost` decimal(10,2) NOT NULL,
  `rental_date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `heavy_equipment_rentals`
--

INSERT INTO `heavy_equipment_rentals` (`id`, `equipment_id`, `cost`, `rental_date`, `created_at`) VALUES
(84, 1, 3232.00, '2025-02-05', '2025-02-05 05:05:27'),
(85, 1, 64.00, '2025-02-06', '2025-02-05 05:05:46'),
(86, 1, 32.00, '2025-02-07', '2025-02-07 06:42:03');

-- --------------------------------------------------------

--
-- Table structure for table `invoices`
--

CREATE TABLE `invoices` (
  `id` int(11) NOT NULL,
  `invoice_number` varchar(50) NOT NULL,
  `supplier_id` int(11) NOT NULL,
  `invoice_date` date NOT NULL,
  `due_date` date NOT NULL,
  `start_period` date NOT NULL,
  `end_period` date NOT NULL,
  `total_amount` decimal(15,0) NOT NULL DEFAULT 0,
  `status` enum('draft','sent','paid','cancelled') DEFAULT 'draft',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `invoices`
--

INSERT INTO `invoices` (`id`, `invoice_number`, `supplier_id`, `invoice_date`, `due_date`, `start_period`, `end_period`, `total_amount`, `status`, `created_at`) VALUES
(1, 'INV/20250207/0001', 2, '2025-02-07', '2025-03-09', '2025-02-05', '2025-02-07', 20000, 'cancelled', '2025-02-07 10:34:40');

-- --------------------------------------------------------

--
-- Table structure for table `invoice_items`
--

CREATE TABLE `invoice_items` (
  `id` int(11) NOT NULL,
  `invoice_id` int(11) NOT NULL,
  `material_name` varchar(255) NOT NULL,
  `total_volume` decimal(15,2) NOT NULL,
  `unit_price` decimal(15,2) NOT NULL,
  `total_price` decimal(15,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `materials`
--

CREATE TABLE `materials` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `price_buy_per_m3` decimal(10,0) NOT NULL,
  `price_sell_per_m3` decimal(10,0) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `materials`
--

INSERT INTO `materials` (`id`, `name`, `price_buy_per_m3`, `price_sell_per_m3`) VALUES
(1, 'Tanah Merah', 100000, 200000),
(2, 'Berangkal', 150000, 250000),
(3, 'Nahtu', 120000, 150000),
(4, 'Limestone', 200000, 250000),
(8, 'Andesit', 30000, 50000);

-- --------------------------------------------------------

--
-- Table structure for table `office_operational_costs`
--

CREATE TABLE `office_operational_costs` (
  `id` int(11) NOT NULL,
  `cost_name` varchar(255) NOT NULL,
  `cost_amount` decimal(10,0) NOT NULL,
  `date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `office_operational_costs`
--

INSERT INTO `office_operational_costs` (`id`, `cost_name`, `cost_amount`, `date`) VALUES
(12, 'Beli Buku Sekolah', 4433323, '2024-10-18'),
(13, 'Beli Makan', 3244423, '2024-10-18'),
(14, 'ADA SAJA', 405211, '2024-10-22'),
(15, 'ALAT', 51333, '2024-10-22'),
(16, 'awas', 232, '2024-12-15'),
(17, 'awas', 23, '2024-12-23'),
(19, 'ajar', 323, '2025-02-05'),
(21, 'Tes', 333, '2025-02-06'),
(22, 'ca', 33333, '2025-02-07');

-- --------------------------------------------------------

--
-- Table structure for table `rentals`
--

CREATE TABLE `rentals` (
  `id` int(11) NOT NULL,
  `vehicle_id` int(11) DEFAULT NULL,
  `cost` decimal(10,0) DEFAULT NULL,
  `rental_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `rentals`
--

INSERT INTO `rentals` (`id`, `vehicle_id`, `cost`, `rental_date`) VALUES
(59, 16, 357143, '2025-02-01'),
(60, 16, 357143, '2025-02-02'),
(61, 16, 357143, '2025-02-03'),
(62, 16, 357143, '2025-02-04'),
(63, 16, 35714, '2025-02-05'),
(64, 16, 357143, '2025-02-06'),
(65, 16, 357143, '2025-02-07'),
(66, 16, 357143, '2025-02-08'),
(67, 16, 357143, '2025-02-09'),
(68, 16, 357143, '2025-02-10'),
(69, 16, 357143, '2025-02-11'),
(70, 16, 357143, '2025-02-12'),
(71, 16, 357143, '2025-02-13'),
(72, 16, 357143, '2025-02-14'),
(73, 16, 357143, '2025-02-15'),
(74, 16, 357143, '2025-02-16'),
(75, 16, 357143, '2025-02-17'),
(76, 16, 357143, '2025-02-18'),
(77, 16, 357143, '2025-02-19'),
(78, 16, 357143, '2025-02-20'),
(79, 16, 357143, '2025-02-21'),
(80, 16, 357143, '2025-02-22'),
(81, 16, 357143, '2025-02-23'),
(82, 16, 357143, '2025-02-24'),
(83, 16, 357143, '2025-02-25'),
(84, 16, 357143, '2025-02-26'),
(85, 16, 357143, '2025-02-27'),
(86, 16, 357143, '2025-02-28');

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--

CREATE TABLE `roles` (
  `id` int(11) NOT NULL,
  `role_name` enum('admin','finance','ground','director','investor') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `roles`
--

INSERT INTO `roles` (`id`, `role_name`) VALUES
(1, 'admin'),
(2, 'finance'),
(3, 'ground'),
(4, 'director'),
(5, 'investor');

-- --------------------------------------------------------

--
-- Table structure for table `suppliers`
--

CREATE TABLE `suppliers` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `owner_name` varchar(255) NOT NULL,
  `city` varchar(100) NOT NULL,
  `project_location` text NOT NULL,
  `logo_url` text DEFAULT NULL,
  `signature_url` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `suppliers`
--

INSERT INTO `suppliers` (`id`, `name`, `owner_name`, `city`, `project_location`, `logo_url`, `signature_url`, `created_at`) VALUES
(2, 'ca', 'ca', 'c', 'caa', NULL, NULL, '2025-02-07 09:39:07');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `role_id`) VALUES
(5, 'admin', '$2b$10$kTEG1jcIPpuBMnRbXjOBvOMN02kaZRAXPNxdpv4kcjrrAWF5hPxWG', 1),
(7, 'keu', '$2b$10$qz/qooAD3oNv5iyzAwWJse7MJ7FB4N5UQcU/j8FY4trj2li3ZDbHS', 2),
(8, 'lapangan', '$2b$10$OITZ9IoYI.xmRlcBBHwXtOrryQD7zGQ5c0uGZeQG45n3.frE5W2Tq', 3),
(9, 'awan', '$2b$10$E6kL2kGoxpbhlxDOzu9Nnu3VmbE/v0hpCbnJnDP8F41PtpYKQQWgS', 1);

-- --------------------------------------------------------

--
-- Table structure for table `vehicles`
--

CREATE TABLE `vehicles` (
  `id` int(11) NOT NULL,
  `vehicle_name` varchar(100) NOT NULL,
  `license_plate` varchar(50) NOT NULL,
  `driver_id` int(11) DEFAULT NULL,
  `length` decimal(10,0) NOT NULL,
  `width` decimal(10,0) NOT NULL,
  `height` decimal(10,0) NOT NULL,
  `barcode` varchar(255) NOT NULL,
  `provider` varchar(100) DEFAULT NULL,
  `price_per_day` decimal(10,2) DEFAULT NULL,
  `price_per_month` decimal(10,2) DEFAULT NULL,
  `price_per_hour` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `vehicles`
--

INSERT INTO `vehicles` (`id`, `vehicle_name`, `license_plate`, `driver_id`, `length`, `width`, `height`, `barcode`, `provider`, `price_per_day`, `price_per_month`, `price_per_hour`) VALUES
(16, 'DT INDEX 8', 'D 2910 DR', 16, 605, 235, 170, 'BC123456789', '', 1000000.00, 10000000.00, 100000.00),
(17, 'DT INDEX 10', 'D 1523 AE', 17, 600, 200, 150, 'BC987654321', '', 5555.00, 5555.00, 5555.00),
(18, 'DT INDEX 22', 'D 1982 CAD', 18, 8, 2, 3, 'BC456789123', '', 666.00, 666.00, 666.00),
(34, 'DT INDEX 24', 'DA 3123 TA', 16, 23, 23, 23, 'bc99d20a-585d-4839-8b51-5143b0d54f47', '', 7777.00, 7777.00, 7777.00),
(35, 'DT INDEX 26', 'D 421 CA', 17, 42, 42, 42, '34febd28-6558-499c-9007-673e9b1760fa', '', 5555.00, 5555.00, 5555.00),
(36, 'DT INDEX 30', 'D 323 ES', 16, 333, 333, 333, '1f296a99-2a51-4934-8966-6f823eb091cb', '', 33300.00, 33300.00, 33300.00);

-- --------------------------------------------------------

--
-- Table structure for table `vehicle_discharge`
--

CREATE TABLE `vehicle_discharge` (
  `id` int(11) NOT NULL,
  `vehicle_id` int(11) NOT NULL,
  `discharge_length` decimal(10,0) NOT NULL,
  `discharge_width` decimal(10,0) NOT NULL,
  `discharge_height` decimal(10,0) NOT NULL,
  `volume` decimal(10,2) NOT NULL,
  `discharge_date` datetime NOT NULL,
  `height_overload` decimal(10,2) DEFAULT 0.00,
  `entry_time` time DEFAULT NULL,
  `exit_time` time DEFAULT NULL,
  `unloading_time` time DEFAULT NULL,
  `material_id` int(11) DEFAULT NULL,
  `total_price` decimal(15,0) DEFAULT 0,
  `price_buy` decimal(15,2) NOT NULL DEFAULT 0.00,
  `price_sell` decimal(15,2) NOT NULL DEFAULT 0.00,
  `profit` decimal(15,2) GENERATED ALWAYS AS (`price_sell` - `price_buy`) STORED
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `vehicle_discharge`
--

INSERT INTO `vehicle_discharge` (`id`, `vehicle_id`, `discharge_length`, `discharge_width`, `discharge_height`, `volume`, `discharge_date`, `height_overload`, `entry_time`, `exit_time`, `unloading_time`, `material_id`, `total_price`, `price_buy`, `price_sell`) VALUES
(16, 16, 605, 235, 170, 24454100.00, '2025-01-20 21:52:23', 2.00, '21:52:00', '21:52:00', '21:52:00', 2, 0, 0.00, 0.00),
(17, 16, 605, 235, 170, 28719350.00, '2025-01-20 22:07:36', 32.00, '22:07:00', '22:07:00', '22:07:00', 2, 0, 0.00, 0.00),
(18, 16, 605, 235, 170, 24880625.00, '2025-01-20 22:15:20', 5.00, '22:15:00', '22:15:00', '22:15:00', 3, 0, 0.00, 0.00),
(19, 16, 605, 235, 170, 24880625.00, '2025-01-20 22:30:52', 5.00, '22:15:00', '22:15:00', '22:15:00', 3, 0, 0.00, 0.00),
(20, 16, 605, 235, 170, 28719350.00, '2025-01-20 22:30:52', 32.00, '22:07:00', '22:07:00', '22:07:00', 2, 0, 0.00, 0.00),
(21, 16, 605, 235, 170, 24454100.00, '2025-01-20 22:30:52', 2.00, '21:52:00', '21:52:00', '21:52:00', 2, 0, 0.00, 0.00),
(22, 16, 605, 235, 170, 24596275.00, '2025-01-20 23:05:51', 3.00, '23:05:00', '23:05:00', '23:05:00', 2, 0, 0.00, 0.00),
(23, 17, 9, 3, 4, 972.00, '2025-01-20 23:06:34', 32.00, '23:06:00', '23:06:00', '23:06:00', 3, 0, 0.00, 0.00),
(24, 17, 9, 3, 4, 972.00, '2025-01-21 23:06:34', 32.00, '23:06:00', '23:06:00', '23:06:00', 3, 0, 0.00, 0.00),
(25, 17, 9, 3, 4, 972.00, '2025-01-11 23:06:34', 32.00, '23:06:00', '23:06:00', '23:06:00', 3, 0, 0.00, 0.00),
(26, 17, 600, 200, 150, 18360000.00, '2025-01-20 23:20:35', 3.00, '23:20:00', '23:20:00', '23:20:00', 1, 0, 0.00, 0.00),
(27, 17, 600, 200, 150, 23280000.00, '2025-01-20 23:25:04', 44.00, '23:24:00', '23:24:00', '23:25:00', 3, 0, 0.00, 0.00),
(28, 17, 600, 200, 150, 21840000.00, '2025-01-20 23:29:54', 32.00, '23:29:00', '23:29:00', '23:29:00', 4, 0, 0.00, 0.00),
(29, 17, 600, 200, 150, 18360000.00, '2025-01-20 23:31:28', 3.00, '23:31:00', '23:31:00', '23:31:00', 4, 3672000, 0.00, 0.00),
(30, 17, 600, 200, 150, 18360000.00, '2025-01-20 23:32:59', 3.00, '23:32:00', '23:32:00', '23:32:00', 3, 2203200, 0.00, 0.00),
(31, 16, 605, 235, 170, 24738450.00, '2025-01-21 13:33:10', 4.00, '13:32:00', '13:32:00', '13:33:00', 1, 2473845, 0.00, 0.00),
(32, 17, 600, 200, 150, 18360000.00, '2025-02-04 18:07:59', 3.00, '18:07:00', '18:07:00', '18:07:00', 1, 1836000, 0.00, 0.00),
(33, 16, 605, 235, 170, 24738450.00, '2025-02-05 06:30:26', 4.00, '06:30:00', '06:30:00', '06:30:00', 1, 2473845, 0.00, 0.00),
(34, 16, 605, 235, 170, 27724125.00, '2025-02-06 14:22:28', 25.00, '14:22:00', '14:22:00', '14:22:00', 1, 2772413, 0.00, 0.00),
(35, 16, 605, 235, 170, 24596275.00, '2025-02-06 14:40:55', 3.00, '14:40:00', '14:40:00', '14:40:00', 2, 3689441, 0.00, 0.00),
(36, 17, 600, 200, 150, 18480000.00, '2025-02-06 14:50:09', 4.00, '14:49:00', '14:50:00', '14:50:00', 1, 1848000, 0.00, 0.00),
(37, 16, 605, 235, 170, 24738450.00, '2025-02-07 13:05:04', 4.00, '13:04:00', '13:04:00', '13:04:00', 1, 4947690, 2473845.00, 4947690.00),
(38, 16, 605, 235, 170, 24738450.00, '2025-02-07 13:14:40', 4.00, '13:14:00', '13:14:00', '13:14:00', 1, 4947690, 2473845.00, 4947690.00),
(39, 16, 605, 235, 170, 24880625.00, '2025-02-07 13:18:56', 5.00, '13:18:00', '13:18:00', '13:18:00', 1, 4976125, 2488062.50, 4976125.00);

-- --------------------------------------------------------

--
-- Table structure for table `vehicle_operations`
--

CREATE TABLE `vehicle_operations` (
  `id` int(11) NOT NULL,
  `vehicle_id` int(11) NOT NULL,
  `status` enum('Beroperasi','Tidak Beroperasi') NOT NULL,
  `operation_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `vehicle_operations`
--

INSERT INTO `vehicle_operations` (`id`, `vehicle_id`, `status`, `operation_date`) VALUES
(6, 34, 'Beroperasi', '2024-11-14'),
(10, 16, 'Beroperasi', '2024-11-14'),
(11, 17, 'Beroperasi', '2024-11-14'),
(12, 18, 'Beroperasi', '2024-11-14'),
(16, 35, 'Beroperasi', '2024-12-14'),
(17, 34, 'Beroperasi', '2024-12-14'),
(18, 16, 'Beroperasi', '2024-12-15'),
(19, 17, 'Beroperasi', '2024-12-15'),
(22, 35, 'Beroperasi', '2024-12-22'),
(23, 16, 'Beroperasi', '2024-12-23'),
(24, 16, 'Beroperasi', '2025-01-20'),
(25, 16, 'Beroperasi', '2025-01-19'),
(26, 17, 'Beroperasi', '2025-01-20'),
(27, 16, 'Beroperasi', '2025-01-21'),
(28, 17, 'Beroperasi', '2025-02-04'),
(29, 16, 'Beroperasi', '2025-02-05'),
(30, 16, 'Beroperasi', '2025-02-06'),
(31, 17, 'Beroperasi', '2025-02-06'),
(32, 16, 'Beroperasi', '2025-02-07');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `bank_accounts`
--
ALTER TABLE `bank_accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `account_number` (`account_number`);

--
-- Indexes for table `drivers`
--
ALTER TABLE `drivers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `driver_costs`
--
ALTER TABLE `driver_costs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `driver_id` (`driver_id`);

--
-- Indexes for table `driver_fuel_costs`
--
ALTER TABLE `driver_fuel_costs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `vehicle_id` (`vehicle_id`);

--
-- Indexes for table `fuel_prices`
--
ALTER TABLE `fuel_prices`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `heavy_equipment`
--
ALTER TABLE `heavy_equipment`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `license_plate` (`license_plate`),
  ADD KEY `driver_id` (`driver_id`);

--
-- Indexes for table `heavy_equipment_fuel_costs`
--
ALTER TABLE `heavy_equipment_fuel_costs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `equipment_id` (`equipment_id`);

--
-- Indexes for table `heavy_equipment_rentals`
--
ALTER TABLE `heavy_equipment_rentals`
  ADD PRIMARY KEY (`id`),
  ADD KEY `equipment_id` (`equipment_id`);

--
-- Indexes for table `invoices`
--
ALTER TABLE `invoices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `invoice_number` (`invoice_number`),
  ADD KEY `supplier_id` (`supplier_id`);

--
-- Indexes for table `invoice_items`
--
ALTER TABLE `invoice_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `invoice_id` (`invoice_id`);

--
-- Indexes for table `materials`
--
ALTER TABLE `materials`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `office_operational_costs`
--
ALTER TABLE `office_operational_costs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `rentals`
--
ALTER TABLE `rentals`
  ADD PRIMARY KEY (`id`),
  ADD KEY `vehicle_id` (`vehicle_id`);

--
-- Indexes for table `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `suppliers`
--
ALTER TABLE `suppliers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_role` (`role_id`);

--
-- Indexes for table `vehicles`
--
ALTER TABLE `vehicles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `license_plate` (`license_plate`),
  ADD KEY `driver_id` (`driver_id`);

--
-- Indexes for table `vehicle_discharge`
--
ALTER TABLE `vehicle_discharge`
  ADD PRIMARY KEY (`id`),
  ADD KEY `vehicle_id` (`vehicle_id`),
  ADD KEY `material_id` (`material_id`);

--
-- Indexes for table `vehicle_operations`
--
ALTER TABLE `vehicle_operations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `vehicle_id` (`vehicle_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `activity_logs`
--
ALTER TABLE `activity_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=62;

--
-- AUTO_INCREMENT for table `bank_accounts`
--
ALTER TABLE `bank_accounts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `drivers`
--
ALTER TABLE `drivers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `driver_costs`
--
ALTER TABLE `driver_costs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=176;

--
-- AUTO_INCREMENT for table `driver_fuel_costs`
--
ALTER TABLE `driver_fuel_costs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `fuel_prices`
--
ALTER TABLE `fuel_prices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `heavy_equipment`
--
ALTER TABLE `heavy_equipment`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `heavy_equipment_fuel_costs`
--
ALTER TABLE `heavy_equipment_fuel_costs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `heavy_equipment_rentals`
--
ALTER TABLE `heavy_equipment_rentals`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=87;

--
-- AUTO_INCREMENT for table `invoices`
--
ALTER TABLE `invoices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `invoice_items`
--
ALTER TABLE `invoice_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `materials`
--
ALTER TABLE `materials`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `office_operational_costs`
--
ALTER TABLE `office_operational_costs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `rentals`
--
ALTER TABLE `rentals`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=87;

--
-- AUTO_INCREMENT for table `roles`
--
ALTER TABLE `roles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `suppliers`
--
ALTER TABLE `suppliers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `vehicles`
--
ALTER TABLE `vehicles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT for table `vehicle_discharge`
--
ALTER TABLE `vehicle_discharge`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT for table `vehicle_operations`
--
ALTER TABLE `vehicle_operations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD CONSTRAINT `activity_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `driver_costs`
--
ALTER TABLE `driver_costs`
  ADD CONSTRAINT `driver_costs_ibfk_1` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `driver_fuel_costs`
--
ALTER TABLE `driver_fuel_costs`
  ADD CONSTRAINT `driver_fuel_costs_ibfk_1` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `heavy_equipment`
--
ALTER TABLE `heavy_equipment`
  ADD CONSTRAINT `heavy_equipment_ibfk_1` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `heavy_equipment_fuel_costs`
--
ALTER TABLE `heavy_equipment_fuel_costs`
  ADD CONSTRAINT `heavy_equipment_fuel_costs_ibfk_1` FOREIGN KEY (`equipment_id`) REFERENCES `heavy_equipment` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `heavy_equipment_rentals`
--
ALTER TABLE `heavy_equipment_rentals`
  ADD CONSTRAINT `heavy_equipment_rentals_ibfk_1` FOREIGN KEY (`equipment_id`) REFERENCES `heavy_equipment` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `invoices`
--
ALTER TABLE `invoices`
  ADD CONSTRAINT `invoices_ibfk_1` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`);

--
-- Constraints for table `invoice_items`
--
ALTER TABLE `invoice_items`
  ADD CONSTRAINT `invoice_items_ibfk_1` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `rentals`
--
ALTER TABLE `rentals`
  ADD CONSTRAINT `rentals_ibfk_1` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`);

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`);

--
-- Constraints for table `vehicles`
--
ALTER TABLE `vehicles`
  ADD CONSTRAINT `vehicles_ibfk_1` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `vehicle_discharge`
--
ALTER TABLE `vehicle_discharge`
  ADD CONSTRAINT `vehicle_discharge_ibfk_1` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `vehicle_discharge_ibfk_2` FOREIGN KEY (`material_id`) REFERENCES `materials` (`id`);

--
-- Constraints for table `vehicle_operations`
--
ALTER TABLE `vehicle_operations`
  ADD CONSTRAINT `vehicle_operations_ibfk_1` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

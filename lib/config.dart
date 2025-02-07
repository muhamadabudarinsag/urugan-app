// lib/config.dart
class Config {
  static const String baseUrl = 'http://40.254.44.254:3333';

  static String get getLoginEndpoint => '$baseUrl/login';

  static String get getBarcodeEndpoint => '$baseUrl/qrcode';

  // Driver endpoints
  static String get addDriverEndpoint => '$baseUrl/add-driver';
  static const String getDriversEndpoint = '$baseUrl/drivers';
  
  // Vehicle endpoints
  static String get addVehicleEndpoint => '$baseUrl/add-vehicle';
  static const String getVehiclesEndpoint = '$baseUrl/vehicles';
  static String getVehicleByIdEndpoint = '$baseUrl/vehicles';

  // Rental endpoints
  static String get addRentalEndpoint => '$baseUrl/rentals';
  static const String getRentalsEndpoint = '$baseUrl/rentals';
  static String get updateRentalEndpoint => '$baseUrl/rentals/';
  static String get deleteRentalEndpoint => '$baseUrl/rentals';

  // Fuel Cost endpoints
  static String get getFuelCostsEndpoint => '$baseUrl/fuel-costs'; 
  static String get addFuelCostEndpoint => '$baseUrl/add-fuel-cost'; 
  static String get editFuelCostEndpoint => '$baseUrl/edit-fuel-cost'; 
  static String get deleteFuelCostEndpoint => '$baseUrl/delete-fuel-cost'; 

  // Operational Cost endpoints
  static String get getOperationalCostsEndpoint => '$baseUrl/operational-costs'; 
  static String get addOperationalCostEndpoint => '$baseUrl/operational-costs'; 
  static String get updateOperationalCostEndpoint => '$baseUrl/operational-costs'; 
  static String get deleteOperationalCostEndpoint => '$baseUrl/operational-costs'; 

  // Heavy Equipment Fuel Cost endpoints
  static String get getHeavyEquipmentFuelCostsEndpoint => '$baseUrl/heavy-equipment-fuel-costs';
  static String get addHeavyEquipmentFuelCostEndpoint => '$baseUrl/heavy-equipment-fuel-costs';
  static String get updateHeavyEquipmentFuelCostEndpoint => '$baseUrl/heavy-equipment-fuel-costs';
  static String get deleteHeavyEquipmentFuelCostEndpoint => '$baseUrl/heavy-equipment-fuel-costs';

  static String get getVehicleStatusesEndpoint => '$baseUrl/vehicle-operations'; 
  static String get saveVehicleStatusEndpoint => '$baseUrl/vehicle-operations'; 
  static String get deleteVehicleStatusEndpoint => '$baseUrl/vehicle-operations'; 
  static String get getMostRecentVehicleOperationEndpoint => '$baseUrl/vehicle-operations'; 
  static String get addVehicleOperationEndpoint => '$baseUrl/add-vehicle-operation'; 

  static String get getVehicleOperationsEndpoint => '$baseUrl/vehicle-operations'; 
  static String get deleteVehicleOperationEndpoint => '$baseUrl/vehicle-operations'; 
  static String get updateVehicleOperationStatusEndpoint => '$baseUrl/vehicle-operations'; 
  
  static String get getVehicleBarcodeEndpoint => '$baseUrl/vehicle-by-barcode';
}

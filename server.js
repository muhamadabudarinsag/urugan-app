const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const path = require('path');

const moment = require('moment');


const QRCode = require('qrcode');
const { v4: uuidv4 } = require('uuid'); // Make sure to install this package for unique IDs
const fs = require('fs'); // Required for file system operations if needed for barcode generation

const app = express();
const PORT = process.env.PORT || 3333;

// Configuration
const JWT_SECRET = 'bhqA2lnx9m'; // Replace with your JWT secret

app.use(cors());
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

const db = mysql.createPool({
    host: 'localhost',
    port: 3307,
    user: 'root', // replace with your MySQL username
    password: 'Qcxqxs123', // replace with your MySQL password
    database: 'urugan', // replace with your database name
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Middleware for JWT authentication
function authenticateToken(req, res, next) {
    const token = req.headers['authorization']?.split(' ')[1];
    if (!token) return res.sendStatus(401); // Unauthorized

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.sendStatus(403); // Forbidden
        req.user = user; // Store user info in request
        //console.log('Authenticated user:', req.user); // Debugging line
        next();
    });
}

function logActivity(userId, username, action, description) {
    const query = `
      INSERT INTO activity_logs (user_id, username, action, description)
      VALUES (?, ?, ?, ?)
    `;
    
    db.query(query, [userId, username, action, description], (err) => {
      if (err) {
        console.error('Error logging activity:', err);
      }
    });
}


 // Add this new endpoint to get activity logs
app.get('/activity-logs', authenticateToken, (req, res) => {
    const { start_date, end_date } = req.query;
    const userId = req.user.userId;
  
    let query = `
      SELECT * FROM activity_logs 
      WHERE user_id = ?
    `;
  
    const queryParams = [userId];
  
    if (start_date && end_date) {
      query += ` AND DATE(created_at) BETWEEN ? AND ?`;
      queryParams.push(start_date, end_date);
    }
  
    query += ` ORDER BY created_at DESC`;
  
    db.query(query, queryParams, (err, results) => {
      if (err) {
        console.error('Error fetching activity logs:', err);
        return res.status(500).json({ message: 'Database query error' });
      }
      res.status(200).json(results);
    });
});

// Login endpoint
app.post('/login', async (req, res) => {
    const { username, password } = req.body;

    const query = `
        SELECT u.id, u.username, u.password, r.role_name 
        FROM users u 
        JOIN roles r ON u.role_id = r.id 
        WHERE u.username = ?`;

    db.query(query, [username], async (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        if (results.length > 0) {
            const user = results[0];
            const isPasswordValid = await bcrypt.compare(password, user.password);
            if (isPasswordValid) {
                const token = jwt.sign({ userId: user.id, username: user.username, role: user.role_name }, JWT_SECRET);
                logActivity(user.id, username, 'login', 'User logged in');
                res.status(200).json({
                    message: 'Login successful!',
                    token,
                    role: user.role_name,
                    userId: user.id,
                });
            } else {
                res.status(401).json({ message: 'Invalid credentials' });
            }
        } else {
            res.status(401).json({ message: 'Invalid credentials' });
        }
    });
});

// Registration endpoint
app.post('/register', async (req, res) => {
    const { username, password, role_id } = req.body;

    const hashedPassword = await bcrypt.hash(password, 10);

    const query = 'INSERT INTO users (username, password, role_id) VALUES (?, ?, ?)';
    db.query(query, [username, hashedPassword, role_id], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        res.status(201).json({ message: 'User created successfully!' });
    });
});

// Get all users
app.get('/users', authenticateToken, (req, res) => {
    const query = `
      SELECT u.id, u.username, r.role_name 
      FROM users u 
      JOIN roles r ON u.role_id = r.id
    `;
    
    db.query(query, (err, results) => {
      if (err) {
        return res.status(500).json({ message: 'Database query error' });
      }
      res.status(200).json(results);
    });
  });
  
  // Get roles for dropdown
  app.get('/roles', authenticateToken, (req, res) => {
    const query = 'SELECT * FROM roles';
    
    db.query(query, (err, results) => {
      if (err) {
        return res.status(500).json({ message: 'Database query error' });
      }
      res.status(200).json(results);
    });
  });
  
  // Create new user
  app.post('/users', authenticateToken, async (req, res) => {
    const { username, password, role_id } = req.body;
    
    // Check if username already exists
    const checkQuery = 'SELECT id FROM users WHERE username = ?';
    
    try {
      const [existingUsers] = await db.promise().query(checkQuery, [username]);
      
      if (existingUsers.length > 0) {
        return res.status(400).json({ message: 'Username already exists' });
      }
      
      const hashedPassword = await bcrypt.hash(password, 10);
      const insertQuery = 'INSERT INTO users (username, password, role_id) VALUES (?, ?, ?)';
      
      await db.promise().query(insertQuery, [username, hashedPassword, role_id]);
      res.status(201).json({ message: 'User created successfully' });
      
    } catch (error) {
      console.error('Error creating user:', error);
      res.status(500).json({ message: 'Error creating user' });
    }
  });
  
  // Update user
  app.put('/users/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const { username, password, role_id } = req.body;
    
    try {
      // Check if username exists for other users
      const checkQuery = 'SELECT id FROM users WHERE username = ? AND id != ?';
      const [existingUsers] = await db.promise().query(checkQuery, [username, id]);
      
      if (existingUsers.length > 0) {
        return res.status(400).json({ message: 'Username already exists' });
      }
      
      let updateQuery = 'UPDATE users SET username = ?, role_id = ?';
      let params = [username, role_id];
      
      // Only update password if provided
      if (password) {
        const hashedPassword = await bcrypt.hash(password, 10);
        updateQuery += ', password = ?';
        params.push(hashedPassword);
      }
      
      updateQuery += ' WHERE id = ?';
      params.push(id);
      
      await db.promise().query(updateQuery, params);
      res.status(200).json({ message: 'User updated successfully' });
      
    } catch (error) {
      console.error('Error updating user:', error);
      res.status(500).json({ message: 'Error updating user' });
    }
  });
  
  // Delete user
  app.delete('/users/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    
    try {
      const query = 'DELETE FROM users WHERE id = ?';
      await db.promise().query(query, [id]);
      res.status(200).json({ message: 'User deleted successfully' });
    } catch (error) {
      console.error('Error deleting user:', error);
      res.status(500).json({ message: 'Error deleting user' });
    }
  });

app.get('/profile', authenticateToken, (req, res) => {
    const userId = req.user.userId;
  
    const query = 'SELECT username FROM users WHERE id = ?';
    
    db.query(query, [userId], (err, results) => {
      if (err) {
        console.error('Error fetching profile:', err);
        return res.status(500).json({ message: 'Database error' });
      }
  
      if (results.length === 0) {
        return res.status(404).json({ message: 'User not found' });
      }
  
      const user = results[0];
      res.status(200).json({ username: user.username });
    });
  });

app.put('/update-profile', authenticateToken, async (req, res) => {
    const { username, password } = req.body;
    const userId = req.user.userId;
  
    try {
      // First check if username already exists (excluding current user)
      const checkUsername = 'SELECT id FROM users WHERE username = ? AND id != ?';
      db.query(checkUsername, [username, userId], async (err, results) => {
        if (err) {
          console.error('Error checking username:', err);
          return res.status(500).json({ message: 'Database error' });
        }
  
        if (results.length > 0) {
          return res.status(400).json({ message: 'Username already exists' });
        }
  
        // If username is unique, proceed with update
        let query = 'UPDATE users SET username = ?';
        let params = [username];
  
        // If password is provided, hash it
        if (password) {
          const hashedPassword = await bcrypt.hash(password, 10);
          query += ', password = ?';
          params.push(hashedPassword);
        }
  
        query += ' WHERE id = ?';
        params.push(userId);
  
        db.query(query, params, (err, results) => {
          if (err) {
            console.error('Error updating profile:', err);
            return res.status(500).json({ message: 'Database error' });
          }
  
          // Get the username for activity logging
          db.query('SELECT username FROM users WHERE id = ?', [userId], (err, userResults) => {
            if (!err && userResults.length > 0) {
              logActivity(
                userId,
                userResults[0].username,
                'edit',
                'Updated profile information'
              );
            }
          });
  
          res.status(200).json({ message: 'Profile updated successfully' });
        });
      });
    } catch (error) {
      console.error('Error in profile update:', error);
      res.status(500).json({ message: 'Server error' });
    }
  });

// Endpoint to generate QR code for a given barcode
app.get('/qrcode/:barcode', async (req, res) => {
    const { barcode } = req.params;

    try {
        const qrImageUrl = await QRCode.toDataURL(barcode);
        res.status(200).json({ qrImageUrl });
    } catch (error) {
        console.error('Error generating QR code:', error);
        res.status(500).json({ message: 'Error generating QR code' });
    }
});

// Example endpoint to get data based on role
app.get('/dashboard', authenticateToken, (req, res) => {
    const { role } = req.user;

    let query;
    switch (role) {
        case 'admin':
            query = 'SELECT * FROM admin_dashboard_data'; 
            break;
        case 'finance':
            query = 'SELECT * FROM manager_dashboard_data'; 
            break;
        case 'ground':
            query = 'SELECT * FROM employee_dashboard_data'; 
            break;
        case 'director':
            query = 'SELECT * FROM guest_dashboard_data'; 
            break;
        case 'investor':
            query = 'SELECT * FROM guest_dashboard_data'; 
            break;   
        default:
            return res.status(400).json({ message: 'Invalid role' });
    }

    db.query(query, (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        res.status(200).json(results);
    });
});

// Update the Add Driver endpoint
app.post('/add-driver', authenticateToken, (req, res) => {
    const { name, license_number, phone_number, price_per_day, price_per_month } = req.body;
    const userId = req.user.userId;
  
    // First get the username
    db.query('SELECT username FROM users WHERE id = ?', [userId], (err, results) => {
      if (err) {
        console.error('Error fetching username:', err);
        return res.status(500).json({ message: 'Database query error' });
      }
  
      if (results.length === 0) {
        return res.status(404).json({ message: 'User not found' });
      }
  
      const username = results[0].username;
  
      // Then add the driver with pricing information
      const query = 'INSERT INTO drivers (name, license_number, phone_number, price_per_day, price_per_month) VALUES (?, ?, ?, ?, ?)';
      db.query(query, [name, license_number, phone_number, price_per_day, price_per_month], (err, results) => {
        if (err) {
          console.error('Error adding driver:', err);
          return res.status(500).json({ message: 'Database query error' });
        }
        
        // Log the activity with the username
        logActivity(
          userId,
          username,
          'add',
          `Added new driver: ${name}`
        );
        
        res.status(201).json({ message: 'Driver added successfully!' });
      });
    });
});

// Get all drivers endpoint
app.get('/drivers', authenticateToken, (req, res) => {
    const query = 'SELECT * FROM drivers';

    db.query(query, (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        res.status(200).json(results);
    });
});

// Get driver count endpoint
app.get('/drivers/count', authenticateToken, (req, res) => {
    const query = 'SELECT COUNT(*) AS count FROM drivers';

    db.query(query, (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        res.status(200).json({ count: results[0].count });
    });
});

// Update the Edit Driver endpoint
app.put('/drivers/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    const { name, license_number, phone_number, price_per_day, price_per_month } = req.body;

    const query = `
        UPDATE drivers 
        SET name = ?, license_number = ?, phone_number = ?, 
            price_per_day = ?, price_per_month = ?
        WHERE id = ?`;
    
    db.query(query, [name, license_number, phone_number, price_per_day, price_per_month, id], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        if (results.affectedRows === 0) {
            return res.status(404).json({ message: 'Driver not found' });
        }
        res.status(200).json({ message: 'Driver updated successfully!' });
    });
});

// Delete Driver endpoint
app.delete('/drivers/:id', authenticateToken, (req, res) => {
    const { id } = req.params;

    const query = 'DELETE FROM drivers WHERE id = ?';
    
    db.query(query, [id], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        if (results.affectedRows === 0) {
            return res.status(404).json({ message: 'Driver not found' });
        }
        res.status(200).json({ message: 'Driver deleted successfully!' });
    });
});

// Add Vehicle endpoint
app.post('/add-vehicle', authenticateToken, async (req, res) => {
    const { vehicle_name, license_plate, driver_id, length, width, height, provider, price_per_day, price_per_month, price_per_hour } = req.body;
    const barcode = uuidv4();
  
    try {
      const [existingVehicle] = await db.promise().query(
        'SELECT id FROM vehicles WHERE license_plate = ?',
        [license_plate]
      );
  
      if (existingVehicle.length > 0) {
        return res.status(400).json({ message: 'Vehicle with this license plate already exists' });
      }
  
      const [result] = await db.promise().query(
        'INSERT INTO vehicles (vehicle_name, license_plate, driver_id, length, width, height, barcode, provider, price_per_day, price_per_month, price_per_hour) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [vehicle_name, license_plate, driver_id, length, width, height, barcode, provider, price_per_day, price_per_month, price_per_hour]
      );
  
      // Log the activity
      const userId = req.user.userId;
      const username = req.user.username;
      await logActivity(userId, username, 'add', `Added vehicle ${vehicle_name}`);
  
      res.status(201).json({ id: result.insertId });
    } catch (error) {
      console.error('Error adding vehicle:', error);
      res.status(500).json({ message: 'Error adding vehicle' });
    }
  });
  
  // Update the edit vehicle endpoint
  app.put('/vehicles/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const { vehicle_name, license_plate, driver_id, length, width, height, provider, price_per_day, price_per_month, price_per_hour } = req.body;
  
    try {
      const [existingVehicle] = await db.promise().query(
        'SELECT id FROM vehicles WHERE license_plate = ? AND id != ?',
        [license_plate, id]
      );
  
      if (existingVehicle.length > 0) {
        return res.status(400).json({ message: 'Vehicle with this license plate already exists' });
      }
  
      await db.promise().query(
        'UPDATE vehicles SET vehicle_name = ?, license_plate = ?, driver_id = ?, length = ?, width = ?, height = ?, provider = ?, price_per_day = ?, price_per_month = ?, price_per_hour = ? WHERE id = ?',
        [vehicle_name, license_plate, driver_id, length, width, height, provider, price_per_day, price_per_month, price_per_hour, id]
      );
  
      // Log the activity
      const userId = req.user.userId;
      const username = req.user.username;
      await logActivity(userId, username, 'edit', `Updated vehicle ${vehicle_name}`);
  
      res.status(200).json({ message: 'Vehicle updated successfully' });
    } catch (error) {
      console.error('Error updating vehicle:', error);
      res.status(500).json({ message: 'Error updating vehicle' });
    }
  });
  
  // Update the get vehicles endpoint to include new fields
  app.get('/vehicles', authenticateToken, async (req, res) => {
    try {
      const [vehicles] = await db.promise().query(
        `SELECT v.*, d.name as driver_name 
         FROM vehicles v 
         LEFT JOIN drivers d ON v.driver_id = d.id`
      );
      res.status(200).json(vehicles);
    } catch (error) {
      console.error('Error fetching vehicles:', error);
      res.status(500).json({ message: 'Error fetching vehicles' });
    }
  });

//THIS CALLED AT DISCHARGE VOLUME
app.get('/vehicles/:vehicleId', authenticateToken, (req, res) => {
    const vehicleId = req.params.vehicleId;
    const query = `
        SELECT v.*, d.name AS driver_name 
        FROM vehicles v 
        LEFT JOIN drivers d ON v.driver_id = d.id
        WHERE v.id = ?;
    `;

    db.query(query, [vehicleId], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        if (results.length === 0) {
            return res.status(404).json({ message: 'Vehicle not found' });
        }
        res.status(200).json(results[0]); // Return the specific vehicle
    });
});

// Get vehicle by barcode
app.get('/vehicle-by-barcode/:barcode', authenticateToken, (req, res) => {
    const barcode = req.params.barcode;
    const query = `
        SELECT v.*, d.name AS driver_name 
        FROM vehicles v 
        LEFT JOIN drivers d ON v.driver_id = d.id
        WHERE v.barcode = ?
    `;

    db.query(query, [barcode], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }

        if (results.length === 0) {
            return res.status(404).json({ message: 'Vehicle not found' });
        }

        res.status(200).json(results[0]); // Return the vehicle object
    });
});


// Update Vehicle endpoint
app.put('/vehicles/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    const { vehicle_name, license_plate, driver_id, length, width, height } = req.body;

    // Update vehicle details without modifying the barcode
    const query = `
        UPDATE vehicles
        SET vehicle_name = ?, license_plate = ?, driver_id = ?, length = ?, width = ?, height = ?
        WHERE id = ?`;

    const queryParams = [
        vehicle_name,
        license_plate,
        driver_id,
        length,
        width,
        height,
        id
    ];

    db.query(query, queryParams, (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error', error: err });
        }
        if (results.affectedRows === 0) {
            return res.status(404).json({ message: 'Vehicle not found' });
        }
        res.status(200).json({ message: 'Vehicle updated successfully!' });
    });
});


// Delete Vehicle endpoint
app.delete('/vehicles/:id', authenticateToken, (req, res) => {
    const { id } = req.params;

    const query = 'DELETE FROM vehicles WHERE id = ?';

    db.query(query, [id], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        if (results.affectedRows === 0) {
            return res.status(404).json({ message: 'Vehicle not found' });
        }
        res.status(200).json({ message: 'Vehicle deleted successfully!' });
    });
});

// Get vehicle count endpoint
app.get('/vehicles/count', authenticateToken, (req, res) => {
    const query = 'SELECT COUNT(*) AS count FROM vehicles';

    db.query(query, (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        res.status(200).json({ count: results[0].count });
    });
});

app.post('/rentals', authenticateToken, (req, res) => {
    const { vehicle_id, cost, rental_date } = req.body;

    // Query to check for duplicate rentals
    const checkQuery = 'SELECT * FROM rentals WHERE vehicle_id = ? AND rental_date = ?';
    
    db.query(checkQuery, [vehicle_id, rental_date], (checkErr, checkResults) => {
        if (checkErr) {
            return res.status(500).json({ message: 'Database query error' });
        }
        
        if (checkResults.length > 0) {
            // Duplicate found
            return res.status(409).json({ message: 'Duplicate rental entry for this vehicle on the selected date.' });
        }

        // No duplicates, proceed with insert
        const insertQuery = 'INSERT INTO rentals (vehicle_id, cost, rental_date) VALUES (?, ?, ?)';
        
        db.query(insertQuery, [vehicle_id, cost, rental_date], (err, results) => {
            if (err) {
                return res.status(500).json({ message: 'Database query error' });
            }
            res.status(201).json({ message: 'Rental created successfully', id: results.insertId });
        });
    });
});


app.get('/rentals', authenticateToken, (req, res) => {
    const { start_date, end_date } = req.query; // Get query parameters

    let query = `
        SELECT r.*, v.vehicle_name, v.license_plate 
        FROM rentals r 
        JOIN vehicles v ON r.vehicle_id = v.id
    `;

    // Initialize conditions and parameters
    const conditions = [];
    const queryParams = []; // Initialize queryParams

    if (start_date) {
        conditions.push('r.rental_date >= ?'); // Use the correct column name
        queryParams.push(start_date + ' 00:00:00'); // Start of the day
    }
    if (end_date) {
        conditions.push('r.rental_date <= ?'); // Use the correct column name
        queryParams.push(end_date + ' 23:59:59'); // End of the day
    }    

    // Add conditions to the query if any exist
    if (conditions.length > 0) {
        query += ' WHERE ' + conditions.join(' AND ');
    }

    db.query(query, queryParams, (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        res.status(200).json(results);
    });
});

app.put('/rentals/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    const { vehicle_id, cost, rental_date } = req.body;
    const query = 'UPDATE rentals SET vehicle_id = ?, cost = ?, rental_date = ? WHERE id = ?';

    db.query(query, [vehicle_id, cost, rental_date, id], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        res.status(200).json({ message: 'Rental updated successfully' });
    });
});

app.delete('/rentals/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    const query = 'DELETE FROM rentals WHERE id = ?';

    db.query(query, [id], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        res.status(200).json({ message: 'Rental deleted successfully' });
    });
});

// Get driver costs
app.get('/driver-costs', authenticateToken, (req, res) => {
    const { start_date, end_date } = req.query;
    
    let query = `
        SELECT dc.*, d.name as driver_name
        FROM driver_costs dc
        JOIN drivers d ON dc.driver_id = d.id
        WHERE 1=1
    `;
    
    const queryParams = [];
    if (start_date) {
        query += ' AND dc.date >= ?';
        queryParams.push(start_date);
    }
    if (end_date) {
        query += ' AND dc.date <= ?';
        queryParams.push(end_date);
    }

    query += ' ORDER BY dc.date DESC';

    db.query(query, queryParams, (err, results) => {
        if (err) {
            console.error('Error fetching driver costs:', err);
            return res.status(500).json({ message: 'Database error' });
        }
        res.status(200).json(results);
    });
});

// Add this new endpoint after the existing driver costs endpoints
app.get('/driver-costs/check-date', authenticateToken, (req, res) => {
    const { driver_id, date } = req.query;
    
    const query = `
        SELECT COUNT(*) as count
        FROM driver_costs
        WHERE driver_id = ? AND DATE(date) = ?
    `;
    
    db.query(query, [driver_id, date], (err, results) => {
        if (err) {
            console.error('Error checking driver cost date:', err);
            return res.status(500).json({ message: 'Database error' });
        }
        res.status(200).json({ exists: results[0].count > 0 });
    });
});

// Update the existing POST endpoint to include duplicate check
app.post('/driver-costs', authenticateToken, (req, res) => {
    const { driver_id, cost_type, amount, date } = req.body;

    // First check if an entry already exists for the same driver and date
    const checkQuery = `
        SELECT COUNT(*) as count
        FROM driver_costs
        WHERE driver_id = ? AND DATE(date) = ?
    `;
    
    db.query(checkQuery, [driver_id, date], (err, results) => {
        if (err) {
            console.error('Error checking for existing entry:', err);
            return res.status(500).json({ message: 'Database error' });
        }
        
        // If a record already exists for the same driver and date, return error
        if (results[0].count > 0) {
            return res.status(409).json({
                message: 'An entry already exists for this date',
                duplicate: true
            });
        }

        // If no duplicate found, proceed with adding the new entry
        const insertQuery = `
            INSERT INTO driver_costs (driver_id, cost_type, amount, date)
            VALUES (?, ?, ?, ?)
        `;
        
        db.query(insertQuery, [driver_id, cost_type, amount, date], (err, results) => {
            if (err) {
                console.error('Error adding driver cost:', err);
                return res.status(500).json({ message: 'Database error' });
            }
            res.status(201).json({ message: 'Driver cost added successfully' });
        });
    });
});

// Update driver cost
app.put('/driver-costs/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    const { amount } = req.body;
    
    const query = `
        UPDATE driver_costs
        SET amount = ?
        WHERE id = ?
    `;
    
    db.query(query, [amount, id], (err, results) => {
        if (err) {
            console.error('Error updating driver cost:', err);
            return res.status(500).json({ message: 'Database error' });
        }
        if (results.affectedRows === 0) {
            return res.status(404).json({ message: 'Driver cost not found' });
        }
        res.status(200).json({ message: 'Driver cost updated successfully' });
    });
});


// Delete driver cost
app.delete('/driver-costs/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    
    const query = 'DELETE FROM driver_costs WHERE id = ?';
    
    db.query(query, [id], (err, results) => {
        if (err) {
            console.error('Error deleting driver cost:', err);
            return res.status(500).json({ message: 'Database error' });
        }
        res.status(200).json({ message: 'Driver cost deleted successfully' });
    });
});

// Add Office Operational Cost
app.post('/operational-costs', authenticateToken, (req, res) => {
    const { cost_name, cost_amount, date } = req.body; // Destructure date from req.body
    const query = 'INSERT INTO office_operational_costs (cost_name, cost_amount, date) VALUES (?, ?, ?)'; // Include date in the query
    db.query(query, [cost_name, cost_amount, date], (err, results) => {
        if (err) return res.status(500).json({ message: 'Database query error' });
        res.status(201).json({ message: 'Operational cost added successfully!', id: results.insertId });
    });
});

// Get All Operational Costs
app.get('/operational-costs', authenticateToken, (req, res) => {
    const { start_date, end_date } = req.query;
    
    let query = 'SELECT * FROM office_operational_costs';
    let queryParams = [];

    if (start_date && end_date) {
        query += ' WHERE date >= ? AND date <= ?';
        queryParams.push(start_date, end_date);
    }

    db.query(query, queryParams, (err, results) => {
        if (err) return res.status(500).json({ message: 'Database query error' });
        res.status(200).json(results);
    });
});


// Update Operational Cost
app.put('/operational-costs/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    const { cost_name, cost_amount } = req.body; // Exclude date

    // Update query now only modifies cost_name and cost_amount
    const query = 'UPDATE office_operational_costs SET cost_name = ?, cost_amount = ? WHERE id = ?';
    db.query(query, [cost_name, cost_amount, id], (err, results) => {
        if (err) return res.status(500).json({ message: 'Database query error' });
        if (results.affectedRows === 0) {
            return res.status(404).json({ message: 'Operational cost not found' });
        }
        res.status(200).json({ message: 'Operational cost updated successfully!' });
    });
});

// Delete Operational Cost
app.delete('/operational-costs/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    const query = 'DELETE FROM office_operational_costs WHERE id = ?';
    db.query(query, [id], (err, results) => {
        if (err) return res.status(500).json({ message: 'Database query error' });
        res.status(200).json({ message: 'Operational cost deleted successfully!' });
    });
});


// Get all vehicle operations (with vehicle details) and optionally filter by date and status
app.get('/vehicle-operations', authenticateToken, (req, res) => {
    const dateFilter = req.query.date;   // Get the date filter if provided
    const statusFilter = req.query.status; // Get the status filter if provided

    // Start building the query with the default 'WHERE' clause for the status
    let query = `
        SELECT vo.*, v.vehicle_name, v.license_plate
        FROM vehicle_operations vo
        LEFT JOIN vehicles v ON vo.vehicle_id = v.id
        WHERE 1 = 1`;  // Always start with '1 = 1' for easy AND concatenation

    // If a status filter is provided, add it to the WHERE clause
    if (statusFilter) {
        query += ` AND vo.status = ?`;
    }

    // If a date filter is provided, add it to the WHERE clause
    if (dateFilter) {
        query += ` AND DATE(vo.operation_date) = ?`;
    }

    query += ` ORDER BY vo.operation_date DESC`; // Optional: Sort by date, descending

    // Prepare the query parameters based on the filters provided
    const queryParams = [];
    if (statusFilter) queryParams.push(statusFilter);  // Add status filter parameter
    if (dateFilter) queryParams.push(dateFilter);    // Add date filter parameter

    // Execute the query with the appropriate parameters
    db.query(query, queryParams, (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        res.status(200).json(results); // Send the results back as JSON
    });
});



// Add new vehicle operation
// Add new vehicle operation with duplicate check
app.post('/add-vehicle-operation', authenticateToken, (req, res) => {
    const { vehicle_id, status, operation_date } = req.body;

    // Convert the operation_date to match the format in the database (if necessary)
    // For example, assuming operation_date is in YYYY-MM-DD format, you can use:
    const formattedDate = new Date(operation_date).toISOString().split('T')[0]; // Format to YYYY-MM-DD

    // Check if there's an existing operation for the same vehicle and date
    const checkQuery = `
        SELECT COUNT(*) AS count 
        FROM vehicle_operations 
        WHERE vehicle_id = ? AND DATE(operation_date) = ?
    `;
    
    db.query(checkQuery, [vehicle_id, formattedDate], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error', error: err });
        }

        if (results[0].count > 0) {
            // If count > 0, it means the vehicle already has an operation on this date
            return res.status(400).json({ message: 'Vehicle operation for this vehicle on this date already exists.' });
        }

        // Proceed with inserting the new operation if no duplicates are found
        const query = `
            INSERT INTO vehicle_operations (vehicle_id, status, operation_date)
            VALUES (?, ?, ?)
        `;
        
        db.query(query, [vehicle_id, status, operation_date], (err, results) => {
            if (err) {
                return res.status(500).json({ message: 'Database query error', error: err });
            }
            res.status(201).json({ message: 'Vehicle operation added successfully!' });
        });
    });
});

// Delete a vehicle operation by ID
app.delete('/vehicle-operations/:id', authenticateToken, (req, res) => {
    const { id } = req.params; // Get the vehicle operation ID from the URL parameter

    // Ensure that the ID is a valid number
    if (isNaN(id)) {
        return res.status(400).json({ message: 'Invalid operation ID.' });
    }

    // Query to delete the vehicle operation by ID
    const query = `
        DELETE FROM vehicle_operations 
        WHERE id = ?
    `;

    db.query(query, [id], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error', error: err });
        }

        if (results.affectedRows === 0) {
            return res.status(404).json({ message: 'Vehicle operation not found.' });
        }

        res.status(200).json({ message: 'Vehicle operation deleted successfully!' });
    });
});
  
// Example of handling a PUT request to update vehicle operation
app.put('/vehicle-operations/:id', authenticateToken, (req, res) => {
    console.log("PUT request received for /vehicle-operations/:id/status");
    const { id } = req.params;
    const { status } = req.body;
  
    const query = `
      UPDATE vehicle_operations 
      SET status = ? 
      WHERE id = ?
    `;
  
    db.query(query, [status, id], (err, results) => {
      if (err) {
        return res.status(500).json({ message: 'Database query error', error: err });
      }
  
      if (results.affectedRows === 0) {
        return res.status(404).json({ message: 'Vehicle operation not found.' });
      }
  
      res.status(200).json({ message: 'Vehicle operation status updated successfully!' });
    });
  });
  
// Update the vehicle discharge POST endpoint to handle buy/sell prices
app.post('/vehicle-discharge', authenticateToken, (req, res) => {
    const { 
        vehicle_id, 
        discharge_length, 
        discharge_width, 
        discharge_height,
        height_overload,
        volume,
        entry_time,
        exit_time,
        unloading_time,
        material_id,
        total_price
    } = req.body;

    // First, get the material prices
    const getMaterialPrices = 'SELECT price_buy_per_m3, price_sell_per_m3 FROM materials WHERE id = ?';
    
    db.query(getMaterialPrices, [material_id], (err, materialResults) => {
        if (err) {
            return res.status(500).json({ message: 'Error getting material prices' });
        }

        if (materialResults.length === 0) {
            return res.status(404).json({ message: 'Material not found' });
        }

        const material = materialResults[0];
        const volumeInM3 = volume / 1000000; // Convert to cubic meters
        const price_buy = volumeInM3 * material.price_buy_per_m3;
        const price_sell = volumeInM3 * material.price_sell_per_m3;

        const query = `
            INSERT INTO vehicle_discharge (
                vehicle_id, discharge_length, discharge_width, discharge_height,
                height_overload, volume, entry_time, exit_time, unloading_time,
                material_id, discharge_date, total_price, price_buy, price_sell
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?, ?, ?)
        `;

        db.query(query, [
            vehicle_id, discharge_length, discharge_width, discharge_height,
            height_overload, volume, entry_time, exit_time, unloading_time,
            material_id, total_price, price_buy, price_sell
        ], (insertErr, result) => {
            if (insertErr) {
                return res.status(500).json({ message: 'Error inserting discharge data' });
            }
            res.status(201).json({ 
                message: 'Vehicle discharge recorded successfully',
                price_buy,
                price_sell,
                profit: price_sell - price_buy
            });
        });
    });
});


// GET route to fetch vehicle discharge data
// Update the GET endpoint in server.js
// Update the GET endpoint to include pricing information
app.get('/vehicle-discharge/:vehicle_id', authenticateToken, (req, res) => {
    const vehicle_id = req.params.vehicle_id;
    const date = req.query.date;

    const query = `
        SELECT 
            vd.*,
            m.name as material_name,
            m.price_buy_per_m3,
            m.price_sell_per_m3,
            (vd.price_sell - vd.price_buy) as profit
        FROM vehicle_discharge vd
        LEFT JOIN materials m ON vd.material_id = m.id
        WHERE vd.vehicle_id = ? 
        AND DATE(vd.discharge_date) = ?
        ORDER BY vd.discharge_date DESC
    `;
    
    db.query(query, [vehicle_id, date], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        if (results.length === 0) {
            return res.status(404).json({ message: 'No discharge data found for this vehicle on the selected date' });
        }

        // Calculate totals
        const totals = results.reduce((acc, curr) => {
            return {
                total_volume: acc.total_volume + parseFloat(curr.volume || 0),
                total_price_buy: acc.total_price_buy + parseFloat(curr.price_buy || 0),
                total_price_sell: acc.total_price_sell + parseFloat(curr.price_sell || 0),
                total_profit: acc.total_profit + parseFloat(curr.profit || 0)
            };
        }, { total_volume: 0, total_price_buy: 0, total_price_sell: 0, total_profit: 0 });

        res.status(200).json({
            discharges: results,
            summary: totals
        });
    });
});


  
  // PUT route to update vehicle discharge data
app.put('/vehicle-discharge/:vehicle_id', authenticateToken, (req, res) => {
    const vehicle_id = req.params.vehicle_id;
    const { discharge_length, discharge_width, discharge_height, volume } = req.body;
  
    // Update discharge data in the vehicle_discharge table
    const query = 'UPDATE vehicle_discharge SET discharge_length = ?, discharge_width = ?, discharge_height = ?, volume = ? WHERE vehicle_id = ?';
    db.query(query, [discharge_length, discharge_width, discharge_height, volume, vehicle_id], (err, result) => {
      if (err) {
        return res.status(500).json({ message: 'Error updating discharge data' });
      }
      if (result.affectedRows === 0) {
        return res.status(404).json({ message: 'Discharge data not found for this vehicle' });
      }
      res.status(200).json({ message: 'Vehicle discharge updated successfully' });
    });
  });
  
// Add Material endpoint
app.post('/materials', authenticateToken, (req, res) => {
    const { name, price_buy_per_m3, price_sell_per_m3 } = req.body;
    const query = 'INSERT INTO materials (name, price_buy_per_m3, price_sell_per_m3) VALUES (?, ?, ?)';
    
    db.query(query, [name, price_buy_per_m3, price_sell_per_m3], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error', error: err });
        }
        res.status(201).json({ message: 'Material added successfully!' });
    });
});

// Update Material endpoint
app.put('/materials/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    const { name, price_buy_per_m3, price_sell_per_m3 } = req.body;
    const query = 'UPDATE materials SET name = ?, price_buy_per_m3 = ?, price_sell_per_m3 = ? WHERE id = ?';
    
    db.query(query, [name, price_buy_per_m3, price_sell_per_m3, id], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error', error: err });
        }
        res.status(200).json({ message: 'Material updated successfully!' });
    });
});

// Delete Material endpoint
app.delete('/materials/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    const query = 'DELETE FROM materials WHERE id = ?';
    
    db.query(query, [id], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error', error: err });
        }
        res.status(200).json({ message: 'Material deleted successfully!' });
    });
});

// Get all materials endpoint
app.get('/materials', authenticateToken, (req, res) => {
    const query = 'SELECT id, name, price_buy_per_m3, price_sell_per_m3 FROM materials';
    
    db.query(query, (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error', error: err });
        }
        res.status(200).json(results);
    });
});

// Get all fuel prices
app.get('/fuel-prices', authenticateToken, (req, res) => {
    const query = 'SELECT * FROM fuel_prices ORDER BY effective_date DESC LIMIT 1';
    
    db.query(query, (err, results) => {
      if (err) {
        return res.status(500).json({ message: 'Database query error' });
      }
      res.status(200).json(results);
    });
  });
  
  // Add new fuel price with check
  app.post('/fuel-prices', authenticateToken, (req, res) => {
    const { price_per_liter, effective_date } = req.body;
    
    // First check if any record exists
    db.query('SELECT COUNT(*) as count FROM fuel_prices', (err, results) => {
      if (err) {
        return res.status(500).json({ message: 'Database query error' });
      }
      
      if (results[0].count > 0) {
        return res.status(400).json({ 
          message: 'A fuel price record already exists. Please delete it before adding a new one.' 
        });
      }
      
      // If no record exists, proceed with insert
      const insertQuery = 'INSERT INTO fuel_prices (price_per_liter, effective_date) VALUES (?, ?)';
      db.query(insertQuery, [price_per_liter, effective_date], (err, results) => {
        if (err) {
          return res.status(500).json({ message: 'Database query error' });
        }
        res.status(201).json({ message: 'Fuel price added successfully!' });
      });
    });
  });
  
  // Delete fuel price
  app.delete('/fuel-prices/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    const query = 'DELETE FROM fuel_prices WHERE id = ?';
    
    db.query(query, [id], (err, results) => {
      if (err) {
        return res.status(500).json({ message: 'Database query error' });
      }
      res.status(200).json({ message: 'Fuel price deleted successfully!' });
    });
  });


// Add Heavy Equipment endpoint
app.post('/add-heavy-equipment', authenticateToken, (req, res) => {
    const { name, license_plate, driver_id, fuel_capacity, hourly_rate, price_per_day, price_per_month, notes } = req.body;
    const query = 'INSERT INTO heavy_equipment (name, license_plate, driver_id, fuel_capacity, hourly_rate, price_per_day, price_per_month, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?)';
    
    db.query(query, [name, license_plate, driver_id, fuel_capacity, hourly_rate, price_per_day, price_per_month, notes], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error', error: err });
        }
        res.status(201).json({ message: 'Heavy equipment added successfully!' });
    });
});

// Get all heavy equipment with driver names
app.get('/heavy-equipment', authenticateToken, (req, res) => {
    const query = `
        SELECT he.*, d.name AS driver_name 
        FROM heavy_equipment he 
        LEFT JOIN drivers d ON he.driver_id = d.id
    `;

    db.query(query, (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        res.status(200).json(results);
    });
});

// Update Heavy Equipment endpoint
app.put('/heavy-equipment/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    const { name, license_plate, driver_id, fuel_capacity, hourly_rate, price_per_day, price_per_month, notes } = req.body;

    const query = `
        UPDATE heavy_equipment 
        SET name = ?, license_plate = ?, driver_id = ?, fuel_capacity = ?, 
            hourly_rate = ?, price_per_day = ?, price_per_month = ?, notes = ?
        WHERE id = ?`;

    db.query(query, [name, license_plate, driver_id, fuel_capacity, hourly_rate, price_per_day, price_per_month, notes, id], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        res.status(200).json({ message: 'Heavy equipment updated successfully!' });
    });
});

// Delete Heavy Equipment endpoint
app.delete('/heavy-equipment/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    const query = 'DELETE FROM heavy_equipment WHERE id = ?';
    
    db.query(query, [id], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        res.status(200).json({ message: 'Heavy equipment deleted successfully!' });
    });
});


// Add Heavy Equipment Rental
// Add Heavy Equipment Rental
app.post('/heavy-equipment-rentals', authenticateToken, (req, res) => {
    const { equipment_id, cost, rental_type, rental_dates, rental_date, start_date, end_date, rental_month, rental_year } = req.body;

    // Validate rental_date presence for daily rentals
    if (!rental_date && !rental_dates) {
        return res.status(400).json({ message: 'Rental date is required' });
    }

    const insertRental = (date, equipmentId, rentalCost) => {
        return new Promise((resolve, reject) => {
            // Check for duplicate first
            db.query(
                'SELECT id FROM heavy_equipment_rentals WHERE equipment_id = ? AND rental_date = ?',
                [equipmentId, date],
                (checkErr, checkResults) => {
                    if (checkErr) {
                        reject(checkErr);
                        return;
                    }
    
                    if (checkResults.length > 0) {
                        console.log(`Skipping duplicate entry for date ${date}`); // Log skipped date
                        resolve();  // Resolve without inserting the duplicate
                        return;
                    }
    
                    // No duplicate found, proceed with insert
                    db.query(
                        'INSERT INTO heavy_equipment_rentals (equipment_id, cost, rental_date) VALUES (?, ?, ?)',
                        [equipmentId, rentalCost, date],
                        (err, results) => {
                            if (err) {
                                reject(err);
                            } else {
                                resolve(results);
                            }
                        }
                    );
                }
            );
        });
    };
    
    const insertRentals = async () => {
        try {
            switch (rental_type) {
                case 'day':
                    // Single day rental
                    await insertRental(rental_date, equipment_id, cost);
                    break;
    
                case 'range':
                    // Create rentals for each day in the range
                    for (let date of rental_dates) {
                        await insertRental(date, equipment_id, cost);
                    }
                    break;
    
                case 'month':
                    // Create rentals for each day in the month
                    for (let date of rental_dates) {
                        await insertRental(date, equipment_id, cost);
                    }
                    break;
    
                default:
                    throw new Error('Invalid rental type');
            }
    
            res.status(201).json({
                message: 'Heavy equipment rental created successfully'
            });
        } catch (error) {
            console.error('Error creating rental:', error);
            if (error.message.includes('Duplicate entry')) {
                res.status(409).json({ message: error.message });
            } else {
                res.status(500).json({ message: 'Database query error' });
            }
        }
    };
    

    insertRentals();
});



// Get Heavy Equipment Rentals
app.get('/heavy-equipment-rentals', authenticateToken, (req, res) => {
    const { start_date, end_date } = req.query;

    let query = `
        SELECT r.*, he.name as equipment_name
        FROM heavy_equipment_rentals r 
        JOIN heavy_equipment he ON r.equipment_id = he.id
    `;

    const conditions = [];
    const queryParams = [];

    if (start_date) {
        conditions.push('r.rental_date >= ?');
        queryParams.push(start_date + ' 00:00:00');
    }
    if (end_date) {
        conditions.push('r.rental_date <= ?');
        queryParams.push(end_date + ' 23:59:59');
    }    

    if (conditions.length > 0) {
        query += ' WHERE ' + conditions.join(' AND ');
    }

    db.query(query, queryParams, (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        res.status(200).json(results);
    });
});

// Update Heavy Equipment Rental
app.put('/heavy-equipment-rentals/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    const { cost } = req.body;  // Only expect cost from the front-end

    // If cost is not provided, return a 400 error
    if (cost === undefined) {
        return res.status(400).json({ message: 'Cost is required' });
    }

    // Prepare the query to update only the cost
    const query = 'UPDATE heavy_equipment_rentals SET cost = ? WHERE id = ?';

    db.query(query, [cost, id], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }

        // Check if any rows were updated
        if (results.affectedRows === 0) {
            return res.status(404).json({ message: 'Rental not found' });
        }

        res.status(200).json({ message: 'Heavy equipment rental updated successfully' });
    });
});


// Delete Heavy Equipment Rental
app.delete('/heavy-equipment-rentals/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    const query = 'DELETE FROM heavy_equipment_rentals WHERE id = ?';

    db.query(query, [id], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }
        res.status(200).json({ message: 'Heavy equipment rental deleted successfully' });
    });
});

// Heavy Equipment Fuel Cost Routes
// Ensure you call `promise()` before using await on the query
app.get('/heavy-equipment-fuel-costs', authenticateToken, async (req, res) => {
    try {
        const { start_date, end_date } = req.query;
        let query = 
            `SELECT hefc.*, he.name as equipment_name, he.license_plate
            FROM heavy_equipment_fuel_costs hefc
            JOIN heavy_equipment he ON hefc.equipment_id = he.id`;

        let params = [];
        if (start_date && end_date) {
            query += ` WHERE hefc.date BETWEEN ? AND ?`;
            params = [start_date, end_date];
        } else {
            const today = new Date().toISOString().split('T')[0];
            query += ` WHERE hefc.date = ?`;
            params = [today];
        }

        query += ` ORDER BY hefc.date DESC`;

        // Use `.promise()` for promise support
        const [results] = await db.promise().query(query, params);
        res.json(results);
    } catch (error) {
        console.error('Error fetching fuel costs:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
  
app.post('/heavy-equipment-fuel-costs', authenticateToken, async (req, res) => {
    
    try {
        const { equipment_id, fuel_amount, price_per_liter, total_cost, date } = req.body;
        
        // Insert fuel cost record (promise-based query)
        const [result] = await db.promise().query(
            'INSERT INTO heavy_equipment_fuel_costs (equipment_id, fuel_amount, price_per_liter, total_cost, date) VALUES (?, ?, ?, ?, ?)',
            [equipment_id, fuel_amount, price_per_liter, total_cost, date]
        );
        
        // Log activity
        const userId = req.user.userId;
        const username = req.user.username;
        await db.promise().query(
            'INSERT INTO activity_logs (user_id, username, action, description) VALUES (?, ?, ?, ?)',
            [userId, username, 'add', `Added fuel cost for equipment ID ${equipment_id}`]
        );
        
        res.status(201).json({ id: result.insertId });
    } catch (error) {
        console.error('Error adding fuel cost:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

  
app.put('/heavy-equipment-fuel-costs/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { fuel_amount, price_per_liter, total_cost, date } = req.body;

        // Update fuel cost record (promise-based query)
        await db.promise().query(
            'UPDATE heavy_equipment_fuel_costs SET fuel_amount = ?, price_per_liter = ?, total_cost = ?, date = ? WHERE id = ?',
            [fuel_amount, price_per_liter, total_cost, date, id]
        );

        // Log activity
        const userId = req.user.userId;
        const username = req.user.username;
        await db.promise().query(
            'INSERT INTO activity_logs (user_id, username, action, description) VALUES (?, ?, ?, ?)',
            [userId, username, 'edit', `Updated fuel cost ID ${id}`]
        );

        res.json({ message: 'Fuel cost updated successfully' });
    } catch (error) {
        console.error('Error updating fuel cost:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

  
app.delete('/heavy-equipment-fuel-costs/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;

        // Delete fuel cost record (promise-based query)
        await db.promise().query('DELETE FROM heavy_equipment_fuel_costs WHERE id = ?', [id]);

        // Log activity
        const userId = req.user.userId;
        const username = req.user.username;
        await db.promise().query(
            'INSERT INTO activity_logs (user_id, username, action, description) VALUES (?, ?, ?, ?)',
            [userId, username, 'delete', `Deleted fuel cost ID ${id}`]
        );

        res.json({ message: 'Fuel cost deleted successfully' });
    } catch (error) {
        console.error('Error deleting fuel cost:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

  
  // Get current fuel price
  app.get('/fuel-prices/current', authenticateToken, async (req, res) => {
    try {
        // Manually wrap the query in a Promise
        const result = await new Promise((resolve, reject) => {
            db.query(
                'SELECT price_per_liter FROM fuel_prices ORDER BY effective_date DESC LIMIT 1',
                (err, results) => {
                    if (err) {
                        reject(err); // Reject the promise if there's an error
                    } else {
                        resolve(results); // Resolve the promise with the query results
                    }
                }
            );
        });

        if (result.length > 0) {
            res.json(result[0]);
        } else {
            res.status(404).json({ error: 'No fuel price found' });
        }
    } catch (error) {
        console.error('Error fetching current fuel price:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

  
// Supplier Management Routes
app.post('/suppliers', authenticateToken, async (req, res) => {
    const { name, owner_name, city, project_location } = req.body;
    const query = `
        INSERT INTO suppliers (name, owner_name, city, project_location)
        VALUES (?, ?, ?, ?)
    `;
    
    try {
        const [result] = await db.promise().query(query, [name, owner_name, city, project_location]);
        res.status(201).json({ 
            message: 'Supplier added successfully',
            id: result.insertId 
        });
    } catch (err) {
        console.error('Error adding supplier:', err);
        res.status(500).json({ message: 'Failed to add supplier' });
    }
});

app.get('/suppliers', authenticateToken, async (req, res) => {
    const query = `
        SELECT * FROM suppliers 
        ORDER BY created_at DESC
    `;
    
    try {
        const [suppliers] = await db.promise().query(query);
        res.status(200).json(suppliers);
    } catch (err) {
        console.error('Error fetching suppliers:', err);
        res.status(500).json({ message: 'Failed to fetch suppliers' });
    }
});

app.put('/suppliers/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const { name, owner_name, city, project_location } = req.body;
    const query = `
        UPDATE suppliers 
        SET name = ?, owner_name = ?, city = ?, project_location = ?
        WHERE id = ?
    `;
    
    try {
        await db.promise().query(query, [name, owner_name, city, project_location, id]);
        res.status(200).json({ message: 'Supplier updated successfully' });
    } catch (err) {
        console.error('Error updating supplier:', err);
        res.status(500).json({ message: 'Failed to update supplier' });
    }
});

app.delete('/suppliers/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const query = 'DELETE FROM suppliers WHERE id = ?';
    
    try {
        await db.promise().query(query, [id]);
        res.status(200).json({ message: 'Supplier deleted successfully' });
    } catch (err) {
        console.error('Error deleting supplier:', err);
        res.status(500).json({ message: 'Failed to delete supplier' });
    }
});

// Bank Account Management Routes
app.post('/bank-accounts', authenticateToken, async (req, res) => {
    const { bank_name, account_number, account_name } = req.body;
    const query = `
        INSERT INTO bank_accounts (bank_name, account_number, account_name)
        VALUES (?, ?, ?)
    `;
    
    try {
        const [result] = await db.promise().query(query, [bank_name, account_number, account_name]);
        res.status(201).json({ 
            message: 'Bank account added successfully',
            id: result.insertId 
        });
    } catch (err) {
        console.error('Error adding bank account:', err);
        res.status(500).json({ message: 'Failed to add bank account' });
    }
});

app.get('/bank-accounts', authenticateToken, async (req, res) => {
    const query = `
        SELECT * FROM bank_accounts 
        ORDER BY created_at DESC
    `;
    
    try {
        const [accounts] = await db.promise().query(query);
        res.status(200).json(accounts);
    } catch (err) {
        console.error('Error fetching bank accounts:', err);
        res.status(500).json({ message: 'Failed to fetch bank accounts' });
    }
});

app.put('/bank-accounts/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const { bank_name, account_number, account_name } = req.body;
    const query = `
        UPDATE bank_accounts 
        SET bank_name = ?, account_number = ?, account_name = ?
        WHERE id = ?
    `;
    
    try {
        await db.promise().query(query, [bank_name, account_number, account_name, id]);
        res.status(200).json({ message: 'Bank account updated successfully' });
    } catch (err) {
        console.error('Error updating bank account:', err);
        res.status(500).json({ message: 'Failed to update bank account' });
    }
});

app.delete('/bank-accounts/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const query = 'DELETE FROM bank_accounts WHERE id = ?';
    
    try {
        await db.promise().query(query, [id]);
        res.status(200).json({ message: 'Bank account deleted successfully' });
    } catch (err) {
        console.error('Error deleting bank account:', err);
        res.status(500).json({ message: 'Failed to delete bank account' });
    }
});

// Get all invoices
app.get('/invoices', authenticateToken, async (req, res) => {
    const query = `
        SELECT i.*, s.name as supplier_name
        FROM invoices i
        JOIN suppliers s ON i.supplier_id = s.id
        ORDER BY i.created_at DESC
    `;
    
    try {
        const [invoices] = await db.promise().query(query);
        res.status(200).json(invoices);
    } catch (err) {
        console.error('Error fetching invoices:', err);
        res.status(500).json({ message: 'Failed to fetch invoices' });
    }
});

app.post('/invoices', authenticateToken, async (req, res) => {
    const {
        supplier_id,
        due_date,
        start_period,
        end_period,
        items
    } = req.body;

    const connection = await db.promise().getConnection();
    
    try {
        // Start transaction
        await connection.beginTransaction();

        // Generate invoice number (format: INV/YYYYMMDD/XXXX)
        const date = new Date();
        const dateStr = date.toISOString().slice(0, 10).replace(/-/g, '');
        const [lastInvoice] = await connection.query(
            'SELECT invoice_number FROM invoices WHERE DATE(created_at) = CURDATE() ORDER BY id DESC LIMIT 1'
        );
        
        let sequence = 1;
        if (lastInvoice.length > 0) {
            const lastNumber = parseInt(lastInvoice[0].invoice_number.split('/')[2]);
            sequence = lastNumber + 1;
        }
        const invoiceNumber = `INV/${dateStr}/${sequence.toString().padStart(4, '0')}`;

        // Calculate total amount
        const totalAmount = items.reduce((sum, item) => sum + parseFloat(item.total_price), 0);

        // Insert invoice
        const [result] = await connection.query(
            `INSERT INTO invoices (
                invoice_number, supplier_id, invoice_date, due_date,
                start_period, end_period, total_amount, status
            ) VALUES (?, ?, CURDATE(), ?, ?, ?, ?, 'draft')`,
            [invoiceNumber, supplier_id, due_date, start_period, end_period, totalAmount]
        );

        // Insert invoice items
        const invoice_id = result.insertId;
        for (const item of items) {
            await connection.query(
                `INSERT INTO invoice_items (
                    invoice_id, material_name, total_volume,
                    unit_price, total_price
                ) VALUES (?, ?, ?, ?, ?)`,
                [
                    invoice_id,
                    item.material_name,
                    item.total_volume,
                    item.unit_price,
                    item.total_price
                ]
            );
        }

        // Commit transaction
        await connection.commit();

        res.status(201).json({
            message: 'Invoice created successfully',
            invoice_id: invoice_id,
            invoice_number: invoiceNumber
        });
    } catch (err) {
        // Rollback on error
        await connection.rollback();
        console.error('Error creating invoice:', err);
        res.status(500).json({ message: 'Failed to create invoice' });
    } finally {
        // Release the connection
        connection.release();
    }
});


// Get vehicle discharge summary for invoice
app.get('/vehicle-discharge/summary', authenticateToken, async (req, res) => {
    const { start_date, end_date } = req.query;

    const query = `
        SELECT 
            m.name as material_name,
            m.price_buy_per_m3,
            m.price_sell_per_m3,
            SUM(vd.volume) as total_volume,
            SUM(vd.volume * m.price_sell_per_m3) as total_price
        FROM vehicle_discharge vd
        JOIN materials m ON vd.material_id = m.id
        WHERE DATE(vd.discharge_date) BETWEEN ? AND ?
        GROUP BY m.id, m.name, m.price_buy_per_m3, m.price_sell_per_m3
    `;

    try {
        const [results] = await db.promise().query(query, [start_date, end_date]);
        res.status(200).json(results);
    } catch (err) {
        console.error('Error fetching discharge summary:', err);
        res.status(500).json({ message: 'Failed to fetch discharge summary' });
    }
});

// Update invoice status
app.put('/invoices/:id/status', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;

    if (!['draft', 'sent', 'paid', 'cancelled'].includes(status)) {
        return res.status(400).json({ message: 'Invalid status' });
    }

    try {
        await db.promise().query(
            'UPDATE invoices SET status = ? WHERE id = ?',
            [status, id]
        );
        res.status(200).json({ message: 'Invoice status updated successfully' });
    } catch (err) {
        console.error('Error updating invoice status:', err);
        res.status(500).json({ message: 'Failed to update invoice status' });
    }
});

// Get invoice details with items
app.get('/invoices/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;

    try {
        // Get invoice details
        const [invoices] = await db.promise().query(
            `SELECT i.*, s.name as supplier_name, s.owner_name, s.city, 
                    s.project_location, s.logo_url, s.signature_url
             FROM invoices i
             JOIN suppliers s ON i.supplier_id = s.id
             WHERE i.id = ?`,
            [id]
        );

        if (invoices.length === 0) {
            return res.status(404).json({ message: 'Invoice not found' });
        }

        const invoice = invoices[0];

        // Get invoice items
        const [items] = await db.promise().query(
            'SELECT * FROM invoice_items WHERE invoice_id = ?',
            [id]
        );

        invoice.items = items;
        res.status(200).json(invoice);
    } catch (err) {
        console.error('Error fetching invoice details:', err);
        res.status(500).json({ message: 'Failed to fetch invoice details' });
    }
});

// Start the server
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});

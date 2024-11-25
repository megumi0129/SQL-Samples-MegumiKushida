drop database compass;
 
-- Create the database
CREATE DATABASE compass;
 
-- Use the database
USE compass;
 
 
-- Create the 'user' table
CREATE TABLE user (
   user_id INT PRIMARY KEY,
   phone VARCHAR(15),
   email VARCHAR(255),
   address VARCHAR(255),
   username VARCHAR(50)
);
 
-- Create the 'compass_card' table
CREATE TABLE compass_card (
   card_id INT PRIMARY KEY,
   user_id INT,
   card_type VARCHAR(50),
   balance INT,
   status BOOLEAN,
   FOREIGN KEY (user_id) REFERENCES user(user_id)
);
 
-- Create the 'translink_station' table
CREATE TABLE translink_station (
   station_id INT PRIMARY KEY,
   type ENUM('Bus', 'Train', 'Ferry'),
   location VARCHAR(255),
   station_name VARCHAR(255),
   zone INT
);
 
-- Create the 'fare_rule' table
CREATE TABLE fare_rule (
   fare_id INT PRIMARY KEY,
   card_type ENUM('Adult', 'Youth', 'Senior'),
   zone_start INT,
   zone_end INT,
   amount INT
);
 
-- Create the 'payment' table
CREATE TABLE payment (
   payment_id INT PRIMARY KEY,
   card_id INT,
   amount INT,
   payment_date DATETIME,
   payment_method ENUM('Credit Card', 'Debit Card', 'Cash'),
   FOREIGN KEY (card_id) REFERENCES compass_card(card_id)
);
 
-- Create the 'subscription_type' table
CREATE TABLE subscription_type (
  subscription_type_id INT PRIMARY KEY,
   name VARCHAR(50),
   zone_start INT,
   zone_end INT,
   duration_days INT,
   price INT
);
 
 
-- Create the 'subscription' table
CREATE TABLE subscription (
   subscription_id INT PRIMARY KEY,
   card_id INT,
  subscription_type_id INT,
   start_date DATETIME,
   end_date DATETIME,
   is_active BOOLEAN,
   FOREIGN KEY (card_id) REFERENCES compass_card(card_id),
   FOREIGN KEY (subscription_type_id) REFERENCES subscription_type(subscription_type_id)
);
 
 
-- Create the 'trip' table
CREATE TABLE trip (
   trip_id INT PRIMARY KEY,
   card_id INT,
   entry_station_id INT,
   exit_station_id INT,
   entry_time DATETIME,
   exit_time DATETIME,
   fare_amount INT,
   subscription_id INT NULL,
   FOREIGN KEY (card_id) REFERENCES compass_card(card_id),
   FOREIGN KEY (entry_station_id) REFERENCES translink_station(station_id),
   FOREIGN KEY (exit_station_id) REFERENCES translink_station(station_id),
   FOREIGN KEY (subscription_id) REFERENCES subscription(subscription_id)
);
 
CREATE TABLE additional_charge (
   charge_id INTEGER PRIMARY KEY,
  subscription_type_id INTEGER,
   zone_start INTEGER,
   zone_end INTEGER,
   additional_fare INTEGER,
   FOREIGN KEY (subscription_type_id) REFERENCES subscription_type(subscription_type_id)
);
 
--  ADD SQL :
 
INSERT INTO user (user_id, phone, email, address, username)
VALUES
   (1, '1234567890', 'user1@example.com', '123 Main St, Vancouver', 'user1');
 
INSERT INTO compass_card (card_id, user_id, card_type, balance, status)
VALUES
   (1, 1, 'Adult', 50, TRUE);
  
INSERT INTO subscription_type (subscription_type_id, name, zone_start, zone_end, duration_days, price)
VALUES (1,'Monthly Adult Pass 1zone' ,1, 1,31, 100);
 
INSERT INTO subscription (subscription_id, card_id, subscription_type_id, start_date, end_date, is_active)
VALUES(1, 1,1,'2024-11-01', '2024-11-30', TRUE);
 
INSERT INTO additional_charge (charge_id, subscription_type_id, zone_start, zone_end, additional_fare)
VALUE(1, 1, 1, 3, 2.3);
 
INSERT INTO fare_rule (fare_id, card_type, zone_start, zone_end, amount)
VALUE( 1, 'Adult', 1, 1, 3.8);
 
 
 
 
 
SELECT
   CASE 
       WHEN EXISTS ( 
           SELECT
               1 
           FROM
              subscription 
               INNER JOIN subscription_type 
                   ON subscription.subscription_type_id = subscription_type.subscription_type_id 
           WHERE
              subscription.card_id = 1  -- card_id
               AND subscription_type.zone_start = 1 -- zone_start
               AND subscription_type.zone_end = 3 -- zone_end
       ) THEN 0  -- Full coverage by subscription
       WHEN EXISTS ( 
           SELECT
               1 
           FROM
              subscription 
           WHERE
              subscription.card_id = 1  -- card_id
       ) THEN (
           SELECT 
              additional_charge.additional_fare 
           FROM
              additional_charge 
               INNER JOIN subscription_type 
                   ON subscription_type.subscription_type_id = additional_charge.subscription_type_id
               INNER JOIN subscription 
                   ON subscription.subscription_type_id = subscription_type.subscription_type_id 
           WHERE
              subscription.card_id = 1 -- card_id
               AND additional_charge.zone_start = 1 -- zone_start
               AND additional_charge.zone_end = 3 -- zone_end
           LIMIT 1  -- Ensures the subquery returns a single value
       )
       ELSE (
           SELECT 
              fare_rule.amount 
           FROM
              fare_rule 
           WHERE
              fare_rule.zone_start = 1  -- zone_start
               AND fare_rule.zone_end = 3 -- zone_end
           LIMIT 1
       )
   END AS cost;

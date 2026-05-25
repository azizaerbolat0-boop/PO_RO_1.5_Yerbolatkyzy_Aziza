CREATE SCHEMA IF NOT EXISTS hotel_schema;
CREATE TABLE IF NOT EXISTS hotel_schema.hotel (
    hotel_id SERIAL PRIMARY KEY,
    hotel_name VARCHAR(100) NOT NULL,
    address VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    star_rating SMALLINT NOT NULL DEFAULT 3 CHECK (star_rating BETWEEN 1 AND 5)
);
CREATE TABLE IF NOT EXISTS hotel_schema.room_type (
    room_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE,
    max_occupancy INT NOT NULL CHECK (max_occupancy > 0),
    base_price NUMERIC(10,2) NOT NULL CHECK (base_price >= 0)
);

CREATE TABLE IF NOT EXISTS hotel_schema.room (
    room_id SERIAL PRIMARY KEY,
    hotel_id INT NOT NULL REFERENCES hotel_schema.hotel(hotel_id),
    room_type_id INT NOT NULL REFERENCES hotel_schema.room_type(room_type_id),
    room_number VARCHAR(10) NOT NULL,
    floor INT NOT NULL DEFAULT 1 CHECK (floor >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'available'
        CHECK (status IN ('available','occupied','maintenance')),
    UNIQUE (hotel_id, room_number)
);

CREATE TABLE IF NOT EXISTS hotel_schema.department (
    department_id SERIAL PRIMARY KEY,
    hotel_id INT NOT NULL REFERENCES hotel_schema.hotel(hotel_id),
    dept_name VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS hotel_schema.staff (
    staff_id SERIAL PRIMARY KEY,
    hotel_id INT NOT NULL REFERENCES hotel_schema.hotel(hotel_id),
    department_id INT NOT NULL REFERENCES hotel_schema.department(department_id),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('Male','Female','Other')),
    email VARCHAR(100) NOT NULL UNIQUE,
    hire_date DATE NOT NULL CHECK (hire_date > '2026-01-01')
);

CREATE TABLE IF NOT EXISTS hotel_schema.customer (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    passport_number VARCHAR(30) NOT NULL UNIQUE,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('Male','Female','Other')),
    registered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hotel_schema.booking (
    booking_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES hotel_schema.customer(customer_id),
    room_id INT NOT NULL REFERENCES hotel_schema.room(room_id),
    check_in_date DATE NOT NULL CHECK (check_in_date > '2026-01-01'),
    check_out_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'confirmed'
        CHECK (status IN ('confirmed','cancelled','completed')),
    total_price NUMERIC(10,2) NOT NULL CHECK (total_price >= 0),
    CHECK (check_out_date > check_in_date)
);
CREATE TABLE IF NOT EXISTS hotel_schema.payment (
    payment_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES hotel_schema.booking(booking_id),
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(30) NOT NULL CHECK (payment_method IN ('card','cash','online')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending','completed','refunded'))
);
CREATE TABLE IF NOT EXISTS hotel_schema.service (
    service_id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50) NOT NULL,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);
CREATE TABLE IF NOT EXISTS hotel_schema.booking_service (
    booking_service_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES hotel_schema.booking(booking_id),
    service_id INT NOT NULL REFERENCES hotel_schema.service(service_id),
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    service_date DATE NOT NULL CHECK (service_date > '2026-01-01'),
    total_price NUMERIC(10,2) NOT NULL CHECK (total_price >= 0),
    UNIQUE (booking_id, service_id, service_date)
);
CREATE TABLE IF NOT EXISTS hotel_schema.review (
    review_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL UNIQUE REFERENCES hotel_schema.booking(booking_id),
    customer_id INT NOT NULL REFERENCES hotel_schema.customer(customer_id),
    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS hotel_schema.checkin_log (
    log_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES hotel_schema.booking(booking_id),
    staff_id INT NOT NULL REFERENCES hotel_schema.staff(staff_id),
    actual_checkin TIMESTAMP,
    actual_checkout TIMESTAMP,
    CHECK (
        actual_checkout IS NULL OR
        actual_checkin IS NULL OR
        actual_checkout > actual_checkin
    )
);
DROP USER IF EXISTS db_admin_user;
DROP USER IF EXISTS db_reader_user;
DROP ROLE IF EXISTS hotel_db_admin;
DROP ROLE IF EXISTS hotel_db_readonly;

CREATE ROLE hotel_db_admin;
CREATE ROLE hotel_db_readonly;

GRANT USAGE ON SCHEMA hotel_schema TO hotel_db_admin;
GRANT USAGE ON SCHEMA hotel_schema TO hotel_db_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA hotel_schema TO hotel_db_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA hotel_schema TO hotel_db_readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA hotel_schema GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO hotel_db_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA hotel_schema GRANT SELECT ON TABLES TO hotel_db_readonly;

CREATE USER db_admin_user WITH PASSWORD 'AdminSecurePass123!';
CREATE USER db_reader_user WITH PASSWORD 'ReaderSecurePass123!';

GRANT hotel_db_admin TO db_admin_user;
GRANT hotel_db_readonly TO db_reader_user;

REVOKE UPDATE, DELETE ON ALL TABLES IN SCHEMA hotel_schema FROM hotel_db_readonly;

SET ROLE db_admin_user;
SELECT current_user;
SELECT COUNT(*) FROM hotel_schema.hotel;
RESET ROLE;

SET ROLE db_reader_user;
SELECT current_user;
SELECT COUNT(*) FROM hotel_schema.hotel;
RESET ROLE;

TRUNCATE TABLE 
    hotel_schema.checkin_log,
    hotel_schema.review,
    hotel_schema.booking_service,
    hotel_schema.payment,
    hotel_schema.booking,
    hotel_schema.staff,
    hotel_schema.department,
    hotel_schema.room,
    hotel_schema.customer,
    hotel_schema.service,
    hotel_schema.room_type,
    hotel_schema.hotel
RESTART IDENTITY CASCADE;

ALTER TABLE hotel_schema.service DROP CONSTRAINT IF EXISTS service_category_check;

INSERT INTO hotel_schema.hotel (hotel_name, phone, email, star_rating) VALUES
('Grand Atyrau Hotel', '+77122001122', 'info@grandatyrau.kz', 5),
('Caspian Palace', '+77122003344', 'stay@caspianpalace.kz', 4),
('City Inn Atyrau', '+77122005566', 'book@cityinn.kz', 3),
('River View Hotel', '+77122007788', 'river@view.kz', 4),
('Sultan Palace', '+77122009900', 'sultan@palace.kz', 5);

INSERT INTO hotel_schema.room_type (type_name, max_occupancy, base_price) VALUES
('Standard Single', 1, 45000.00),
('Standard Double', 2, 75000.00),
('Deluxe Double', 2, 110000.00),
('Junior Suite', 3, 160000.00),
('Presidential Suite', 4, 350000.00);

INSERT INTO hotel_schema.service (service_name, category, price) VALUES
('Room Service Breakfast', 'Food & Beverage', 3500.00),
('Airport Transfer', 'Transport', 8000.00),
('Spa & Massage (60 min)', 'Wellness', 12000.00),
('Laundry (per kg)', 'Housekeeping', 1500.00),
('Conference Room (half-day)', 'Business', 25000.00);

INSERT INTO hotel_schema.customer (first_name, last_name, email, phone, passport_number) VALUES
('James', 'Wilson', 'james.wilson@email.com', '+447911123456', 'GB12345678'),
('Aigul', 'Massimova', 'aigul.m@email.kz', '+77017654321', 'KZ98765432'),
('Nikolai', 'Petrov', 'n.petrov@email.ru', '+79161234567', 'RU11223344'),
('Sarah', 'Lee', 'sarah.lee@email.com', '+12025551234', 'US44556677'),
('Askar', 'Umarov', 'askar.u@email.kz', '+77073332211', 'KZ11223344');

INSERT INTO hotel_schema.room (hotel_id, room_type_id, room_number, floor, status) VALUES
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122'), (SELECT room_type_id FROM hotel_schema.room_type WHERE type_name = 'Standard Single'), '101', 1, 'available'),
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122'), (SELECT room_type_id FROM hotel_schema.room_type WHERE type_name = 'Standard Double'), '102', 1, 'available'),
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122'), (SELECT room_type_id FROM hotel_schema.room_type WHERE type_name = 'Deluxe Double'), '201', 2, 'occupied'),
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122'), (SELECT room_type_id FROM hotel_schema.room_type WHERE type_name = 'Junior Suite'), '301', 3, 'available'),
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122'), (SELECT room_type_id FROM hotel_schema.room_type WHERE type_name = 'Presidential Suite'), '401', 4, 'available');

INSERT INTO hotel_schema.department (hotel_id, dept_name) VALUES
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122'), 'Front Desk'),
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122'), 'Housekeeping'),
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122'), 'F&B'),
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122'), 'Management'),
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122003344'), 'Front Desk');

INSERT INTO hotel_schema.staff (hotel_id, first_name, last_name, position, email) VALUES
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122'), 'Aibek', 'Seitkali', 'Receptionist', 'aibek.s@grandatyrau.kz'),
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122'), 'Dinara', 'Bekova', 'Senior Receptionist', 'dinara.b@grandatyrau.kz'),
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122'), 'Marat', 'Akhmetov', 'Housekeeper', 'marat.a@grandatyrau.kz'),
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122'), 'Saltanat', 'Nurlanova', 'General Manager', 'saltanat.n@grandatyrau.kz'),
((SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122003344'), 'Yerlan', 'Dzhaksybekov', 'Receptionist', 'yerlan.d@caspianpalace.kz');

INSERT INTO hotel_schema.booking (customer_id, room_id, check_in_date, check_out_date, status, total_price) VALUES
((SELECT customer_id FROM hotel_schema.customer WHERE email = 'james.wilson@email.com'), (SELECT room_id FROM hotel_schema.room WHERE room_number = '101' AND hotel_id = (SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122')), '2026-06-01', '2026-06-05', 'confirmed', 180000.00),
((SELECT customer_id FROM hotel_schema.customer WHERE email = 'aigul.m@email.kz'), (SELECT room_id FROM hotel_schema.room WHERE room_number = '201' AND hotel_id = (SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122')), '2026-06-10', '2026-06-12', 'confirmed', 220000.00),
((SELECT customer_id FROM hotel_schema.customer WHERE email = 'n.petrov@email.ru'), (SELECT room_id FROM hotel_schema.room WHERE room_number = '301' AND hotel_id = (SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122')), '2026-06-15', '2026-06-20', 'confirmed', 800000.00),
((SELECT customer_id FROM hotel_schema.customer WHERE email = 'sarah.lee@email.com'), (SELECT room_id FROM hotel_schema.room WHERE room_number = '102' AND hotel_id = (SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122')), '2026-07-01', '2026-07-03', 'confirmed', 150000.00),
((SELECT customer_id FROM hotel_schema.customer WHERE email = 'askar.u@email.kz'), (SELECT room_id FROM hotel_schema.room WHERE room_number = '101' AND hotel_id = (SELECT hotel_id FROM hotel_schema.hotel WHERE phone = '+77122001122')), '2026-08-01', '2026-08-05', 'cancelled', 180000.00);

INSERT INTO hotel_schema.payment (booking_id, amount, payment_date, payment_method, status) VALUES
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'james.wilson@email.com') AND check_in_date = '2026-06-01'), 180000.00, '2026-06-01', 'card', 'completed'),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'aigul.m@email.kz') AND check_in_date = '2026-06-10'), 110000.00, '2026-06-10', 'online', 'completed'),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'n.petrov@email.ru') AND check_in_date = '2026-06-15'), 800000.00, '2026-06-15', 'card', 'completed'),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'sarah.lee@email.com') AND check_in_date = '2026-07-01'), 75000.00, '2026-07-01', 'cash', 'pending'),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'askar.u@email.kz') AND check_in_date = '2026-08-01'), 0.00, '2026-08-01', 'card', 'pending');

INSERT INTO hotel_schema.booking_service (booking_id, service_id, quantity, service_date) VALUES
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'james.wilson@email.com') AND check_in_date = '2026-06-01'), (SELECT service_id FROM hotel_schema.service WHERE service_name = 'Room Service Breakfast'), 4, '2026-06-02'),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'james.wilson@email.com') AND check_in_date = '2026-06-01'), (SELECT service_id FROM hotel_schema.service WHERE service_name = 'Airport Transfer'), 1, '2026-06-01'),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'n.petrov@email.ru') AND check_in_date = '2026-06-15'), (SELECT service_id FROM hotel_schema.service WHERE service_name = 'Spa & Massage (60 min)'), 2, '2026-06-17'),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'sarah.lee@email.com') AND check_in_date = '2026-07-01'), (SELECT service_id FROM hotel_schema.service WHERE service_name = 'Laundry (per kg)'), 3, '2026-07-02'),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'james.wilson@email.com') AND check_in_date = '2026-06-01'), (SELECT service_id FROM hotel_schema.service WHERE service_name = 'Laundry (per kg)'), 2, '2026-06-03');

INSERT INTO hotel_schema.review (booking_id, customer_id, rating, comment) VALUES
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'james.wilson@email.com') AND check_in_date = '2026-06-01'), (SELECT customer_id FROM hotel_schema.customer WHERE email = 'james.wilson@email.com'), 5, 'Excellent stay! Staff were incredibly helpful and the room was spotless.'),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'aigul.m@email.kz') AND check_in_date = '2026-06-10'), (SELECT customer_id FROM hotel_schema.customer WHERE email = 'aigul.m@email.kz'), 4, 'Very comfortable and great location. Breakfast could be improved.'),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'n.petrov@email.ru') AND check_in_date = '2026-06-15'), (SELECT customer_id FROM hotel_schema.customer WHERE email = 'n.petrov@email.ru'), 5, 'Magnificent Presidential Suite, exceptional high level of service.'),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'sarah.lee@email.com') AND check_in_date = '2026-07-01'), (SELECT customer_id FROM hotel_schema.customer WHERE email = 'sarah.lee@email.com'), 3, 'Average room size, but housekeeping team was very polite.'),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'james.wilson@email.com') AND check_in_date = '2026-06-01'), (SELECT customer_id FROM hotel_schema.customer WHERE email = 'aigul.m@email.kz'), 4, 'Good experience overall.');

-- Убрали точные даты выезда (сделали NULL), чтобы не срабатывали автоматические триггеры перевода брони в архив
INSERT INTO hotel_schema.checkin_log (booking_id, staff_id, actual_checkin, actual_checkout) VALUES
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'james.wilson@email.com') AND check_in_date = '2026-06-01'), (SELECT staff_id FROM hotel_schema.staff WHERE email = 'aibek.s@grandatyrau.kz'), '2026-06-01 14:30:00', NULL),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'aigul.m@email.kz') AND check_in_date = '2026-06-10'), (SELECT staff_id FROM hotel_schema.staff WHERE email = 'dinara.b@grandatyrau.kz'), '2026-06-10 15:00:00', NULL),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'n.petrov@email.ru') AND check_in_date = '2026-06-15'), (SELECT staff_id FROM hotel_schema.staff WHERE email = 'aibek.s@grandatyrau.kz'), '2026-06-15 13:10:00', NULL),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'sarah.lee@email.com') AND check_in_date = '2026-07-01'), (SELECT staff_id FROM hotel_schema.staff WHERE email = 'dinara.b@grandatyrau.kz'), '2026-07-01 14:00:00', NULL),
((SELECT booking_id FROM hotel_schema.booking WHERE customer_id = (SELECT customer_id FROM hotel_schema.customer WHERE email = 'james.wilson@email.com') AND check_in_date = '2026-06-01'), (SELECT staff_id FROM hotel_schema.staff WHERE email = 'yerlan.d@caspianpalace.kz'), '2026-06-01 15:00:00', NULL);

SELECT customer_id, first_name, last_name, phone FROM hotel_schema.customer WHERE email = 'aigul.m@email.kz';

UPDATE hotel_schema.customer
SET phone = '+77017000001'
WHERE email = 'aigul.m@email.kz';

SELECT payment_id, booking_id, amount, status FROM hotel_schema.payment WHERE status = 'pending' AND amount < 100000.00;

UPDATE hotel_schema.payment
SET amount = ROUND(amount * 0.90, 2)
WHERE status = 'pending'
  AND amount < 100000.00;

SELECT b.booking_id, b.status, cl.actual_checkout 
FROM hotel_schema.booking b
JOIN hotel_schema.checkin_log cl ON b.booking_id = cl.booking_id
WHERE cl.actual_checkout IS NOT NULL AND b.status = 'confirmed';

UPDATE hotel_schema.booking b
SET status = 'completed'
FROM hotel_schema.checkin_log cl
WHERE b.booking_id = cl.booking_id
  AND cl.actual_checkout IS NOT NULL
  AND b.status = 'confirmed';

SELECT b.booking_id, b.customer_id, b.status
FROM hotel_schema.booking b
LEFT JOIN hotel_schema.payment p ON b.booking_id = p.booking_id
WHERE b.status = 'cancelled' AND p.payment_id IS NULL;

BEGIN;

DELETE FROM hotel_schema.booking
WHERE status = 'cancelled'
  AND booking_id NOT IN (SELECT booking_id FROM hotel_schema.payment);

SELECT COUNT(*) FROM hotel_schema.booking WHERE status = 'cancelled'; 

ROLLBACK;
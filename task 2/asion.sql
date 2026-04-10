CREATE TABLE Hotel
(
    hotel_id    SERIAL PRIMARY KEY,
    hotel_name  VARCHAR(100) NOT NULL,
    address     VARCHAR(200) NOT NULL,
    phone       VARCHAR(20) NOT NULL UNIQUE,
    email       VARCHAR(100) NOT NULL UNIQUE,
    star_rating SMALLINT NOT NULL DEFAULT 3,
    CHECK (star_rating BETWEEN 1 AND 5)
);

CREATE TABLE Room_Type
(
    room_type_id  SERIAL PRIMARY KEY,
    type_name     VARCHAR(50) NOT NULL UNIQUE,
    max_occupancy INT NOT NULL CHECK (max_occupancy > 0),
    base_price    DECIMAL(10,2) NOT NULL CHECK (base_price >= 0)
);

CREATE TABLE Room
(
    room_id      SERIAL PRIMARY KEY,
    hotel_id     INT NOT NULL REFERENCES Hotel(hotel_id),
    room_type_id INT NOT NULL REFERENCES Room_Type(room_type_id),
    room_number  VARCHAR(10) NOT NULL,
    floor        INT NOT NULL DEFAULT 1 CHECK (floor >= 0),
    status       VARCHAR(20) NOT NULL DEFAULT 'available'
                 CHECK (status IN ('available', 'occupied', 'maintenance')),
    UNIQUE (hotel_id, room_number)
);

CREATE TABLE Department
(
    department_id SERIAL PRIMARY KEY,
    hotel_id      INT NOT NULL REFERENCES Hotel(hotel_id),
    dept_name     VARCHAR(50) NOT NULL
);

CREATE TABLE Staff
(
    staff_id      SERIAL PRIMARY KEY,
    hotel_id      INT NOT NULL REFERENCES Hotel(hotel_id),
    department_id INT NOT NULL REFERENCES Department(department_id),
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    position      VARCHAR(50) NOT NULL,
    gender        VARCHAR(10) NOT NULL CHECK (gender IN ('Male', 'Female', 'Other')),
    email         VARCHAR(100) NOT NULL UNIQUE,
    hire_date     DATE NOT NULL
);

CREATE TABLE Customer
(
    customer_id     SERIAL PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    phone           VARCHAR(20) NOT NULL,
    passport_number VARCHAR(30) NOT NULL UNIQUE,
    gender          VARCHAR(10) NOT NULL CHECK (gender IN ('Male', 'Female', 'Other')),
    registered_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE Booking
(
    booking_id     SERIAL PRIMARY KEY,
    customer_id    INT NOT NULL REFERENCES Customer(customer_id),
    room_id        INT NOT NULL REFERENCES Room(room_id),
    check_in_date  DATE NOT NULL,
    check_out_date DATE NOT NULL,
    status         VARCHAR(20) NOT NULL DEFAULT 'confirmed'
                  CHECK (status IN ('confirmed', 'cancelled', 'completed')),
    total_price    DECIMAL(10,2) NOT NULL CHECK (total_price >= 0),
    notes          TEXT,
    CHECK (check_out_date > check_in_date)
);

CREATE TABLE Payment
(
    payment_id     SERIAL PRIMARY KEY,
    booking_id     INT NOT NULL REFERENCES Booking(booking_id),
    amount         DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    payment_date   TIMESTAMP NOT NULL DEFAULT NOW(),
    payment_method VARCHAR(30) NOT NULL CHECK (payment_method IN ('card', 'cash', 'online')),
    status         VARCHAR(20) NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'completed', 'refunded'))
);

CREATE TABLE Service
(
    service_id   SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL UNIQUE,
    category     VARCHAR(50) NOT NULL,
    price        DECIMAL(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE Booking_Service
(
    booking_service_id SERIAL PRIMARY KEY,
    booking_id         INT NOT NULL REFERENCES Booking(booking_id),
    service_id         INT NOT NULL REFERENCES Service(service_id),
    quantity           INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    service_date       DATE NOT NULL,
    total_price        DECIMAL(10,2) NOT NULL CHECK (total_price >= 0),
    UNIQUE (booking_id, service_id, service_date)
);

CREATE TABLE Review
(
    review_id   SERIAL PRIMARY KEY,
    booking_id  INT NOT NULL UNIQUE REFERENCES Booking(booking_id),
    customer_id INT NOT NULL REFERENCES Customer(customer_id),
    rating      SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE Checkin_Log
(
    log_id          SERIAL PRIMARY KEY,
    booking_id      INT NOT NULL REFERENCES Booking(booking_id),
    staff_id        INT NOT NULL REFERENCES Staff(staff_id),
    actual_checkin  TIMESTAMP,
    actual_checkout TIMESTAMP,
    CHECK (actual_checkout IS NULL OR actual_checkin IS NULL OR actual_checkout > actual_checkin)
);

INSERT INTO Hotel (hotel_name, address, phone, email, star_rating)
VALUES ('Grand Palace Hotel', '12 Alatau Ave, Almaty', '+77000000001', 'info@grandpalace.kz', 5);

INSERT INTO Room_Type (type_name, max_occupancy, base_price)
VALUES ('Standard Single', 1, 80.00);

INSERT INTO Room_Type (type_name, max_occupancy, base_price)
VALUES ('Deluxe Double', 2, 150.00);

INSERT INTO Room_Type (type_name, max_occupancy, base_price)
VALUES ('Suite', 4, 350.00);

INSERT INTO Room (hotel_id, room_type_id, room_number, floor, status)
VALUES (1, 1, '101', 1, 'available');

INSERT INTO Room (hotel_id, room_type_id, room_number, floor, status)
VALUES (1, 2, '102', 1, 'available');

INSERT INTO Department (hotel_id, dept_name)
VALUES (1, 'Front Desk');

INSERT INTO Department (hotel_id, dept_name)
VALUES (1, 'Housekeeping');

INSERT INTO Staff (hotel_id, department_id, first_name, last_name, position, gender, email, hire_date)
VALUES (1, 1, 'Aibek', 'Dzhaksybekov', 'Receptionist', 'Male', 'aibek@grandpalace.kz', '2024-02-01');

INSERT INTO Staff (hotel_id, department_id, first_name, last_name, position, gender, email, hire_date)
VALUES (1, 2, 'Madina', 'Seitkali', 'Housekeeper', 'Female', 'madina@grandpalace.kz', '2024-03-15');

INSERT INTO Customer (first_name, last_name, email, phone, passport_number, gender)
VALUES ('Saida', 'Aziza', 'saida@example.com', '+77770000001', 'AB1234567', 'Female');

INSERT INTO Customer (first_name, last_name, email, phone, passport_number, gender)
VALUES ('Ivan', 'Petrov', 'ivan@example.com', '+77770000002', 'CD7654321', 'Male');

INSERT INTO Booking (customer_id, room_id, check_in_date, check_out_date, status, total_price)
VALUES (1, 1, '2026-06-01', '2026-06-05', 'confirmed', 600.00);

INSERT INTO Booking (customer_id, room_id, check_in_date, check_out_date, status, total_price)
VALUES (2, 2, '2026-07-10', '2026-07-12', 'confirmed', 160.00);

INSERT INTO Payment (booking_id, amount, payment_method, status)
VALUES (1, 600.00, 'card', 'completed');

INSERT INTO Payment (booking_id, amount, payment_method, status)
VALUES (2, 160.00, 'cash', 'pending');

INSERT INTO Service (service_name, category, price)
VALUES ('Breakfast Buffet', 'Food', 25.00);

INSERT INTO Service (service_name, category, price)
VALUES ('Spa Treatment', 'Wellness', 75.00);

INSERT INTO Service (service_name, category, price)
VALUES ('Room Service', 'Food', 15.00);

INSERT INTO Booking_Service (booking_id, service_id, quantity, service_date, total_price)
VALUES (1, 1, 2, '2026-06-02', 50.00);

INSERT INTO Review (booking_id, customer_id, rating, comment)
VALUES (1, 1, 5, 'Excellent stay!');

UPDATE Room
SET status = 'occupied'
WHERE room_number = '101';

DELETE FROM Booking
WHERE status = 'cancelled';

SELECT * FROM Hotel;
SELECT * FROM Room;
SELECT * FROM Customer;
SELECT * FROM Booking;
SELECT * FROM Payment;
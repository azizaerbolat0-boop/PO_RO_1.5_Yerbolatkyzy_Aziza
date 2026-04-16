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
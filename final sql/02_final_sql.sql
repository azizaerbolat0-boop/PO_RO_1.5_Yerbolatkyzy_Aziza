-- ============================================================================
-- DATABASE: vet_clinic_db | SCHEMA: clinic
-- Domain: Veterinary Clinic Management System — pets, owners, vets, visits, treatments, vaccinations
-- Run instructions: Execute in psql or pgAdmin in a clean vet_clinic_db database
-- ============================================================================

create schema if not exists clinic;

-- ============================================================================
-- PART 2: CREATE TABLES + CONSTRAINTS
-- ============================================================================

create table if not exists clinic.owners (
    owner_id   serial       primary key,
    full_name  varchar(100) not null,
    email      varchar(120) not null,
    created_at timestamp    default now()
);

create table if not exists clinic.species (
    species_id   serial      primary key,
    species_name varchar(50) not null unique
);

create table if not exists clinic.vets (
    vet_id         serial       primary key,
    full_name      varchar(100) not null,
    license_number varchar(50)  not null,
    specialization varchar(50)  default 'General Medicine',
    constraint check_vet_specialization
        check (specialization in ('General Medicine', 'Surgery', 'Dermatology', 'Cardiology'))
);

create table if not exists clinic.pets (
    pet_id         serial       primary key,
    owner_id       int          not null references clinic.owners(owner_id) on delete cascade,
    species_id     int          not null references clinic.species(species_id) on delete restrict,
    pet_name       varchar(50)  not null,
    birth_date     date,
    gender         varchar(10),
    constraint check_pet_gender check (gender in ('Male', 'Female', 'Unknown'))
);

create table if not exists clinic.visits (
    visit_id     serial    primary key,
    pet_id       int       references clinic.pets(pet_id) on delete cascade,
    vet_id       int       not null references clinic.vets(vet_id) on delete restrict,
    visit_date   timestamp default now(),
    visit_reason text      not null
);

create table if not exists clinic.treatments (
    treatment_id   serial        primary key,
    treatment_name varchar(100)  not null,
    base_cost      numeric(10,2) not null,
    -- Computed column: total cost including 12% VAT
    cost_with_vat  numeric(10,2) generated always as (base_cost * 1.12) stored,
    is_surgical    boolean       default false
);

create table if not exists clinic.visit_treatments (
    visit_treatment_id serial        primary key,
    visit_id           int           not null references clinic.visits(visit_id) on delete cascade,
    treatment_id       int           not null references clinic.treatments(treatment_id) on delete restrict,
    quantity           int           not null,
    charged_price      numeric(10,2) not null
);

create table if not exists clinic.vaccinations (
    vaccination_id   serial primary key,
    pet_id           int    not null references clinic.pets(pet_id) on delete cascade,
    vaccine_name     varchar(100) not null,
    administered_date date   not null,
    next_due_date    date   not null,
    -- Next due date must be after administered date
    constraint check_vaccination_dates check (next_due_date > administered_date),
    -- Only records after system project milestone date
    constraint check_administered_date check (administered_date > date '2026-01-01')
);

-- ============================================================================
-- PART 3: ALTER TABLE OPERATIONS (FULLY RERUNNABLE & NO DROP)
-- ============================================================================

alter table clinic.owners add column if not exists phone_number varchar(15);

alter table clinic.owners alter column phone_number type varchar(20);

alter table clinic.treatments alter column is_surgical set default false;

create unique index if not exists uq_vet_license_idx on clinic.vets (license_number);
create unique index if not exists uq_owner_email_idx on clinic.owners (email);

-- ============================================================================
-- PART 4: TRUNCATE (Reset tables before data seeding)
-- ============================================================================

truncate
    clinic.vaccinations, clinic.visit_treatments, clinic.treatments,
    clinic.visits, clinic.pets, clinic.vets,
    clinic.species, clinic.owners
restart identity cascade;

-- ============================================================================
-- PART 5: INSERT INTO (Data seeding)
-- ============================================================================

insert into clinic.owners (full_name, email, phone_number) values
('Ибрагимова Диана',  'diana@example.kz',   '+77011112233'),
('Аманжол Нурали',    'nurali@example.kz',  '+77022223344'),
('Бексултан Аружан',  'aruzhan@example.kz', '+77033334455'),
('Ким Алексей',       'alex@example.kz',    '+77044445566'),
('Омарова Камила',    'kamila@example.kz',  '+77055556677');

insert into clinic.species (species_name) values
('Dog'),
('Cat'),
('Bird'),
('Rabbit'),
('Reptile');

insert into clinic.vets (full_name, license_number, specialization) values
('Dr. Асанов Данияр',      'LIC-100200', 'General Medicine'),
('Dr. Волкова Екатерина',  'LIC-300400', 'Surgery'),
('Dr. Серикбаев Мадияр',   'LIC-500600', 'Dermatology'),
('Dr. Тян Владимир',       'LIC-700800', 'Cardiology'),
('Dr. Сулейменова Дана',   'LIC-900100', 'General Medicine');

insert into clinic.pets (owner_id, species_id, pet_name, birth_date, gender) values
(
    (select owner_id from clinic.owners where email = 'diana@example.kz'),
    (select species_id from clinic.species where species_name = 'Dog'),
    'Aktosh', '2023-04-12', 'Male'
),
(
    (select owner_id from clinic.owners where email = 'nurali@example.kz'),
    (select species_id from clinic.species where species_name = 'Cat'),
    'Simba', '2024-01-20', 'Male'
),
(
    (select owner_id from clinic.owners where email = 'aruzhan@example.kz'),
    (select species_id from clinic.species where species_name = 'Bird'),
    'Chika', '2025-05-10', 'Female'
),
(
    (select owner_id from clinic.owners where email = 'alex@example.kz'),
    (select species_id from clinic.species where species_name = 'Rabbit'),
    'Pushok', '2024-08-15', 'Unknown'
),
(
    (select owner_id from clinic.owners where email = 'kamila@example.kz'),
    (select species_id from clinic.species where species_name = 'Cat'),
    'Murka', '2022-11-02', 'Female'
);

insert into clinic.treatments (treatment_name, base_cost, is_surgical) values
('General Checkup',     1500.00,  false),
('Core Vaccination',    4500.00,  false),
('Dental Cleaning',     12000.00, false),
('Sterilization Surgery',32000.00, true),
('Cardiac Ultrasound',  25000.00, false),
('Fracture Repair',     41000.00, true),
('Ear Cleaning',        2500.00,  false),
('Skin Scraping Test',  6000.00,  false),
('Deworming Pill',      1200.00,  false),
('X-Ray Scan',          8500.00,  false),
('Nail Trimming',       1000.00,  false);

insert into clinic.visits (pet_id, vet_id, visit_date, visit_reason) values
(
    (select pet_id from clinic.pets where pet_name = 'Simba' and owner_id = (select owner_id from clinic.owners where email = 'nurali@example.kz')),
    (select vet_id from clinic.vets where license_number = 'LIC-300400'),
    '2026-02-20 14:15:00', 'Scheduled Sterilization Surgery'
),
(
    (select pet_id from clinic.pets where pet_name = 'Pushok' and owner_id = (select owner_id from clinic.owners where email = 'alex@example.kz')),
    (select vet_id from clinic.vets where license_number = 'LIC-700800'),
    '2026-04-01 09:00:00', 'Heart rhythm evaluation'
),
(
    (select pet_id from clinic.pets where pet_name = 'Aktosh' and owner_id = (select owner_id from clinic.owners where email = 'diana@example.kz')),
    (select vet_id from clinic.vets where license_number = 'LIC-100200'),
    '2026-02-18 10:30:00', 'Routine checkout and hygiene'
),
(
    (select pet_id from clinic.pets where pet_name = 'Chika' and owner_id = (select owner_id from clinic.owners where email = 'aruzhan@example.kz')),
    (select vet_id from clinic.vets where license_number = 'LIC-500600'),
    '2026-03-05 18:45:00', 'Itching around wings and checkup'
),
(
    (select pet_id from clinic.pets where pet_name = 'Murka' and owner_id = (select owner_id from clinic.owners where email = 'kamila@example.kz')),
    (select vet_id from clinic.vets where license_number = 'LIC-900100'),
    '2026-04-12 12:00:00', 'Emergency walk-in basic exam'
);

insert into clinic.vaccinations (pet_id, vaccine_name, administered_date, next_due_date) values
(
    (select pet_id from clinic.pets where pet_name = 'Simba' and owner_id = (select owner_id from clinic.owners where email = 'nurali@example.kz')),
    'Feline Rabies Vaccine', '2026-02-10', '2027-02-10'
),
(
    (select pet_id from clinic.pets where pet_name = 'Pushok' and owner_id = (select owner_id from clinic.owners where email = 'alex@example.kz')),
    'Rabbit Myxomatosis Shot', '2026-03-01', '2026-09-01'
),
(
    (select pet_id from clinic.pets where pet_name = 'Aktosh' and owner_id = (select owner_id from clinic.owners where email = 'diana@example.kz')),
    'Canine Parvovirus Booster', '2026-01-15', '2027-01-15'
),
(
    (select pet_id from clinic.pets where pet_name = 'Chika' and owner_id = (select owner_id from clinic.owners where email = 'aruzhan@example.kz')),
    'Avian Polyomavirus Dose', '2026-04-20', '2027-04-20'
),
(
    (select pet_id from clinic.pets where pet_name = 'Murka' and owner_id = (select owner_id from clinic.owners where email = 'kamila@example.kz')),
    'Feline Leukemia Shot', '2026-05-01', '2027-05-01'
);

insert into clinic.visit_treatments (visit_id, treatment_id, quantity, charged_price)
select
    v.visit_id,
    t.treatment_id,
    1,
    t.cost_with_vat
from clinic.visits v
join clinic.pets p on v.pet_id = p.pet_id
join clinic.owners o on p.owner_id = o.owner_id
cross join clinic.treatments t
where o.email = 'diana@example.kz'
  and t.treatment_name in ('General Checkup', 'Nail Trimming');

insert into clinic.visit_treatments (visit_id, treatment_id, quantity, charged_price) values
(
    (select visit_id from clinic.visits where visit_date = '2026-02-20 14:15:00'),
    (select treatment_id from clinic.treatments where treatment_name = 'Sterilization Surgery'),
    1, 35840.00
),
(
    (select visit_id from clinic.visits where visit_date = '2026-02-20 14:15:00'),
    (select treatment_id from clinic.treatments where treatment_name = 'Ear Cleaning'),
    1, 2800.00
),
(
    (select visit_id from clinic.visits where visit_date = '2026-03-05 18:45:00'),
    (select treatment_id from clinic.treatments where treatment_name = 'Skin Scraping Test'),
    1, 6720.00
),
(
    (select visit_id from clinic.visits where visit_date = '2026-04-01 09:00:00'),
    (select treatment_id from clinic.treatments where treatment_name = 'Cardiac Ultrasound'),
    1, 28000.00
),
(
    (select visit_id from clinic.visits where visit_date = '2026-04-12 12:00:00'),
    (select treatment_id from clinic.treatments where treatment_name = 'General Checkup'),
    1, 1680.00
),
(
    (select visit_id from clinic.visits where visit_date = '2026-04-12 12:00:00'),
    (select treatment_id from clinic.treatments where treatment_name = 'X-Ray Scan'),
    1, 9520.00
),
(
    (select visit_id from clinic.visits where visit_date = '2026-03-05 18:45:00'),
    (select treatment_id from clinic.treatments where treatment_name = 'General Checkup'),
    1, 1680.00
),
(
    (select visit_id from clinic.visits where visit_date = '2026-04-01 09:00:00'),
    (select treatment_id from clinic.treatments where treatment_name = 'Deworming Pill'),
    2, 2688.00
);

-- ============================================================================
-- PART 6: UPDATE OPERATIONS
-- ============================================================================

-- Business reason: apply 5% price increase to all non-surgical (general care) treatments
update clinic.treatments
set base_cost = base_cost * 1.05
where is_surgical = false;

-- Business reason: sync all visit treatment charges with the current cost_with_vat from treatments
update clinic.visit_treatments vt
set charged_price = t.cost_with_vat
from clinic.treatments t
where vt.treatment_id = t.treatment_id;

-- ============================================================================
-- PART 8: PRIVILEGES (FULLY RERUNNABLE & NO DROP)
-- ============================================================================

grant usage on schema clinic to clinic_readonly;
grant select on all tables in schema clinic to clinic_readonly;

grant usage on schema clinic to clinic_writer;
grant insert on clinic.visits           to clinic_writer;
grant insert on clinic.visit_treatments to clinic_writer;

-- ============================================================================
-- PART 7: DELETE OPERATIONS (wrapped in transaction — data preserved for defense)
-- ============================================================================

begin;

-- Business reason: clear out invalid historic placeholder vaccinations scheduled before Feb 15 2026
delete from clinic.vaccinations
where next_due_date < date '2026-02-15'
returning vaccination_id, pet_id, next_due_date;

rollback;
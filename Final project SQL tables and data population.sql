--Mechanism to prevent guest wristband IDs and family member wristband IDs from overlapping
CREATE SEQUENCE IF NOT EXISTS global_id_seq;

-------------Table creations-------------
CREATE TABLE Hotel_Building(
    Address VARCHAR(255) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Number_of_rooms INT NOT NULL CHECK (Number_of_rooms > 0)
);

CREATE TABLE Room(
    Address VARCHAR(255) NOT NULL REFERENCES Hotel_Building(Address) ON DELETE CASCADE,
    Room_Number INT NOT NULL CHECK (Room_Number > 0),
    PRIMARY KEY (Address, Room_Number)
);

CREATE TABLE guest (
    First_Name VARCHAR(32) NOT NULL,
    Last_Name VARCHAR(32) NOT NULL,
    Wristband_ID INT PRIMARY KEY DEFAULT nextval('global_id_seq'),
    Has_Gold_Membership BOOLEAN DEFAULT FALSE
);

CREATE TABLE Family_Member (
    Wristband_ID INT PRIMARY KEY DEFAULT nextval('global_id_seq'),
    Main_Guest_ID INT NOT NULL REFERENCES Guest(Wristband_ID) ON DELETE CASCADE,
    First_Name VARCHAR(32) NOT NULL,
    Last_Name VARCHAR(32) NOT NULL
);

CREATE TABLE Booking(
    Booking_ID SERIAL PRIMARY KEY,
    Guest_ID INT NOT NULL REFERENCES Guest(Wristband_ID) ON DELETE CASCADE,
    Address VARCHAR(255) NOT NULL,
    Room_Number INT NOT NULL,
    Booking_Range DATERANGE NOT NULL,
    FOREIGN KEY (Address, Room_Number)
        REFERENCES Room(Address, Room_Number) ON DELETE CASCADE
);

--This trigger allows us to prevent two bookings from overlapping
CREATE OR REPLACE FUNCTION prevent_booking_overlap()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM Booking
        WHERE Address = NEW.Address
          AND Room_Number = NEW.Room_Number
          AND Booking_Range && NEW.Booking_Range
    ) THEN
        RAISE EXCEPTION 'Room is already booked during this date range.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_booking_conflict
    BEFORE INSERT ON Booking
    FOR EACH ROW EXECUTE FUNCTION prevent_booking_overlap();

CREATE TABLE Payment(
    Payment_ID SERIAL PRIMARY KEY,
    Booking_ID INT NOT NULL REFERENCES Booking(Booking_ID) ON DELETE CASCADE,
    Guest_ID INT NOT NULL REFERENCES Guest(Wristband_ID) ON DELETE CASCADE,
    Amount NUMERIC(10, 2) NOT NULL CHECK (Amount > 0),
    Payment_Time TIMESTAMP NOT NULL,
    Payment_Type VARCHAR(20) NOT NULL CHECK (Payment_Type IN ('CreditCard', 'ApplePay'))
);

CREATE TABLE Credit_Card_Payment(
    Payment_ID INT PRIMARY KEY REFERENCES Payment(Payment_ID) ON DELETE CASCADE,
    Card_Number VARCHAR(20) NOT NULL,
    Card_Expiration_Date DATE NOT NULL
);

CREATE TABLE Apple_Pay_Payment(
    Payment_ID INT PRIMARY KEY REFERENCES Payment(Payment_ID) ON DELETE CASCADE,
    Device_Account_Number INT NOT NULL CHECK (Device_Account_Number > 0)
);

CREATE TABLE Wake_Up_Call (
    Guest_ID INT NOT NULL REFERENCES Guest(Wristband_ID) ON DELETE CASCADE,
    Wakeup_Date DATE NOT NULL,
    Wakeup_Time TIME NOT NULL,
    PRIMARY KEY (Guest_ID, Wakeup_Date, Wakeup_Time)
);

-------------Data population below-------------

-- Insert Hotels
INSERT INTO Hotel_Building (Address, Name, Number_of_rooms) VALUES
('123 Ocean Ave', 'Seaside Escape', 5),
('456 Mountain Rd', 'Hilltop Haven', 3);

-- Insert Rooms
INSERT INTO Room (Address, Room_Number) VALUES
('123 Ocean Ave', 101), ('123 Ocean Ave', 102), ('123 Ocean Ave', 103),
('456 Mountain Rd', 201), ('456 Mountain Rd', 202);

-- Insert Guests
INSERT INTO Guest (First_Name, Last_Name, Has_Gold_Membership) VALUES
('Alice', 'Smith', TRUE),
('Bob', 'Johnson', FALSE),
('Charlie', 'Lee', TRUE),
('Diana', 'Cruz', FALSE),
('Edward', 'Nguyen', TRUE),
('Fiona', 'Taylor', FALSE),
('George', 'Martinez', TRUE);

-- Insert Family Members
INSERT INTO Family_Member (Main_Guest_ID, First_Name, Last_Name) VALUES
(1, 'Ella', 'Smith'),
(2, 'Daisy', 'Johnson'),
(3, 'Frank', 'Lee'),
(4, 'Leo', 'Cruz'),
(4, 'Maya', 'Cruz'),
(5, 'Hannah', 'Nguyen'),
(6, 'Oliver', 'Taylor'),
(7, 'Nina', 'Martinez');

-- Insert Bookings (non-overlapping)
INSERT INTO Booking (Guest_ID, Address, Room_Number, Booking_Range) VALUES
(1, '123 Ocean Ave', 101, '[2025-07-29,2025-08-05)'),
(2, '456 Mountain Rd', 201, '[2025-08-03,2025-08-07)'   ),
(3, '123 Ocean Ave', 102, '[2025-08-10,2025-08-14)'),
(4, '123 Ocean Ave', 103, '[2025-08-15,2025-08-20)'),
(5, '456 Mountain Rd', 202, '[2025-08-01,2025-08-03)'),
(6, '123 Ocean Ave', 101, '[2025-08-21,2025-08-25)');

-- Insert Payments
INSERT INTO Payment (Booking_ID, Guest_ID, Amount, Payment_Time, Payment_Type) VALUES
(1, 1, 500.00, '2025-07-15 10:00:00', 'CreditCard'),
(2, 2, 400.00, '2025-07-16 11:30:00', 'ApplePay'),
(3, 3, 650.00, '2025-07-17 14:00:00', 'CreditCard'),
(4, 4, 550.00, '2025-07-20 09:30:00', 'CreditCard'),
(5, 5, 300.00, '2025-07-22 15:15:00', 'ApplePay'),
(6, 6, 475.00, '2025-07-24 13:45:00', 'CreditCard');

-- Insert Credit Card Payments
INSERT INTO Credit_Card_Payment (Payment_ID, Card_Number, Card_Expiration_Date) VALUES
(1, '4111111111111111', '2026-12-01'),
(3, '5555555555554444', '2027-05-01'),
(4, '4000123412341234', '2026-11-01'),
(6, '6011000990139424', '2027-09-01');

-- Insert Apple Pay Payments
INSERT INTO Apple_Pay_Payment (Payment_ID, Device_Account_Number) VALUES
(2, 987654321),
(5, 123456789);

-- Insert Wake-Up Calls
INSERT INTO Wake_Up_Call (Guest_ID, Wakeup_Date, Wakeup_Time) VALUES
(1, '2025-08-02', '07:00'),
(2, '2025-08-04', '06:30'),
(3, '2025-08-11', '08:00'),
(4, '2025-08-16', '06:45'),
(5, '2025-08-02', '07:30'),

(6, '2025-08-22', '08:15');

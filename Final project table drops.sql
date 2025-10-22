--This block wipes all tables and resets the ID counter. Use with caution!
DO $$
BEGIN
    DROP TABLE IF EXISTS
        Apple_Pay_Payment,
        Credit_Card_Payment,
        Payment,
        Wake_Up_Call,
        Booking,
        Family_Member,
        Guest,
        Room,
        Hotel_Building
    CASCADE;
    ALTER SEQUENCE global_id_seq RESTART;
END;
$$ LANGUAGE plpgsql;



-- Q1. Airlines

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
    pass_id INT,
    name VARCHAR(100),
    airlines INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS departured_flight CASCADE;
DROP VIEW IF EXISTS took_departured_flight CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW departured_flight AS
SELECT Departure.flight_id, Flight.airline
FROM Flight, Departure
WHERE Flight.id = Departure.flight_id;

CREATE VIEW took_departured_flight AS
SELECT Booking.flight_id, Booking.pass_id, departured_flight.airline
FROM Booking, departured_flight
WHERE Booking.flight_id=departured_flight.flight_id;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q1
SELECT Passenger.id, Passenger.firstname||' '||Passenger.surname, count(distinct airline)
FROM Passenger LEFT JOIN took_departured_flight ON passenger.id=took_departured_flight.pass_id
GROUP BY Passenger.id;

CREATE DATABASE medical_appointments;
USE medical_appointments;

-- Basic SQL & Data Retrieval

-- 1. Retrieve all columns from the Appointments table
SELECT * FROM Appointments;

-- 2. List the first 10 appointments where the patient is older than 60
SELECT * 
FROM Appointments 
WHERE Age > 60 
LIMIT 10;

-- 3. Show the unique neighborhoods from which patients came
SELECT DISTINCT Neighbourhood 
FROM Appointments;

-- 4. Find all female patients who received an SMS reminder and give count
SELECT COUNT(*) AS FemalePatientsWithSMS
FROM Appointments
WHERE Gender = 'Female' AND SMS_received = 1;

-- Data Modification & Filtering

-- 5. Update dates to correct format
SET SQL_SAFE_UPDATES = 0;
UPDATE Appointments
SET ScheduledDay = STR_TO_DATE(ScheduledDay, '%Y-%m-%d'),
    AppointmentDay = STR_TO_DATE(AppointmentDay, '%Y-%m-%d')
WHERE ScheduledDay IS NOT NULL AND AppointmentDay IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;
    
-- 6. Modify datatypes of date columns
ALTER TABLE Appointments
MODIFY ScheduledDay DATE,
MODIFY AppointmentDay DATE;

-- 7. Update 'Showed_up' status
SET SQL_SAFE_UPDATES = 0;
UPDATE Appointments
SET Showed_up = 'Yes'
WHERE Showed_up IS NULL OR Showed_up = '';
SET SQL_SAFE_UPDATES = 1;

-- 8. Add AppointmentStatus column
ALTER TABLE Appointments
ADD COLUMN AppointmentStatus VARCHAR(10);

UPDATE Appointments
SET AppointmentStatus = CASE 
    WHEN Showed_up = 'No' THEN 'No Show' 
    ELSE 'Attended' 
END;
SHOW COLUMNS FROM Appointments LIKE 'AppointmentStatus';
-- 9. Filter appointments for diabetic patients with hypertension
SELECT *
FROM Appointments
WHERE Diabetes = 1 AND Hypertension = 1;

-- 10. Top 5 oldest patients
SELECT *
FROM Appointments
ORDER BY Age DESC
LIMIT 5;

-- 11. First 5 appointments for patients under 18
SELECT *
FROM Appointments
WHERE Age < 18
LIMIT 5;

--  12. Appointments scheduled between May 1-31, 2023
SELECT *
FROM Appointments
WHERE ScheduledDay >= STR_TO_DATE('05-01-2023', '%m-%d-%Y') 
  AND ScheduledDay < STR_TO_DATE('06-01-2023', '%m-%d-%Y');
  
-- Aggregation and CASE

-- 13. Average age by gender
SELECT 
    Gender, 
    ROUND(AVG(Age), 2) AS AverageAge
FROM Appointments
GROUP BY Gender;

-- 14. SMS reminders by attendance status
SELECT Showed_up, COUNT(*) AS PatientCount
FROM Appointments
WHERE SMS_received = 1
GROUP BY Showed_up;

-- 15. No-show appointments by neighbourhood
SELECT Neighbourhood, COUNT(*) AS NoShowCount
FROM Appointments
WHERE Showed_up = 'No'
GROUP BY Neighbourhood
ORDER BY NoShowCount DESC;

-- 16. Neighbourhoods with >100 appointments
SELECT Neighbourhood, COUNT(*) AS TotalAppointments
FROM Appointments
GROUP BY Neighbourhood
HAVING COUNT(*) > 100;

-- 17. Age group counts
SELECT 
    SUM(CASE WHEN Age < 12 THEN 1 ELSE 0 END) AS Children,
    SUM(CASE WHEN Age BETWEEN 12 AND 60 THEN 1 ELSE 0 END) AS Adults,
    SUM(CASE WHEN Age > 60 THEN 1 ELSE 0 END) AS Seniors
FROM Appointments;

-- 18. Appointment attendance by day of week
SELECT 
    DAYNAME(AppointmentDay) AS DayOfWeek,
    COUNT(*) AS TotalAppointments,
    SUM(CASE WHEN Showed_up = 'Yes' THEN 1 ELSE 0 END) AS Attended,
    SUM(CASE WHEN Showed_up = 'No' THEN 1 ELSE 0 END) AS NoShows,
    ROUND(SUM(CASE WHEN Showed_up = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS ShowPercentage,
    ROUND(SUM(CASE WHEN Showed_up = 'No' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS NoShowPercentage
FROM Appointments
GROUP BY DayOfWeek
ORDER BY NoShowPercentage DESC;

-- Window Functions

-- 19. Running total of appointments by neighbourhood
SELECT 
    Neighbourhood,
    AppointmentDay,
    COUNT(*) OVER (PARTITION BY Neighbourhood ORDER BY AppointmentDay) AS RunningTotal
FROM Appointments
ORDER BY Neighbourhood, AppointmentDay;

-- 20. Rank patients by age within gender groups
SELECT 
    PatientId,
    Gender,
    Age,
    DENSE_RANK() OVER (PARTITION BY Gender ORDER BY Age DESC) AS AgeRank
FROM Appointments;

-- 21. Days since last appointment in same neighbourhood
WITH NeighborhoodAppointments AS (
    SELECT 
        Neighbourhood,
        AppointmentDay,
        LAG(AppointmentDay) OVER (PARTITION BY Neighbourhood ORDER BY AppointmentDay) AS PreviousAppointment
    FROM Appointments
)
SELECT 
    Neighbourhood,
    AppointmentDay,
    PreviousAppointment,
    DATEDIFF(AppointmentDay, PreviousAppointment) AS DaysSinceLastAppointment
FROM NeighborhoodAppointments;

-- 22. Neighbourhoods ranked by no-shows
WITH NeighbourhoodNoShows AS (
    SELECT 
        Neighbourhood,
        COUNT(*) AS NoShowCount
    FROM Appointments
    WHERE Showed_up = 'No'
    GROUP BY Neighbourhood
)
SELECT 
    Neighbourhood,
    NoShowCount,
    DENSE_RANK() OVER (ORDER BY NoShowCount DESC) AS NoShowRank
FROM NeighbourhoodNoShows;

-- Subqueries and CTEs

-- 23. Neighbourhoods with 2nd and 3rd highest no-show counts
SELECT 
    Neighbourhood,
    COUNT(*) AS NoShowCount
FROM Appointments
WHERE Showed_up = 'No'
GROUP BY Neighbourhood
ORDER BY NoShowCount DESC
LIMIT 3;

-- 24. Female patients older than average female age
WITH FemaleAges AS (
    SELECT AVG(Age) AS AvgAge
    FROM Appointments
    WHERE Gender = 'Female'
)
SELECT *
FROM Appointments
WHERE Gender = 'Female' AND Age > (SELECT AvgAge FROM FemaleAges);

-- 25. Most recent appointment in each neighborhood
WITH LatestAppointments AS (
    SELECT 
        Neighbourhood,
        MAX(AppointmentDay) AS LatestDate
    FROM Appointments
    GROUP BY Neighbourhood
)
SELECT a.*
FROM Appointments a
JOIN LatestAppointments la ON a.Neighbourhood = la.Neighbourhood AND a.AppointmentDay = la.LatestDate;
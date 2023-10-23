# The file contains:
# (1) database instances
# (2) the queries made (as in section 7)
# (3) the delete/update statements used to change the tables (as in section 8), and
# (4) the statements used to create and apply functions, procedures, triggers, and events (as in section 9)

USE HospitalDatabase;
# Database instances ##########################################################
SELECT * FROM Patient;
SELECT * FROM Doctor;
SELECT * FROM Nurse;
SELECT * FROM Treatment;
SELECT * FROM Consults;
SELECT * FROM Prescribes;
SELECT * FROM Treats;
SELECT * FROM ReportsTo;

# QUERY STATEMENTS #############################################################

-- View the No. of Consultations per Doctor
SELECT DoctorID, FirstName, LastName, COUNT(ConsultationID)  AS
NoConsultationsPerDoctor
FROM Doctor NATURAL JOIN Consults
GROUP BY DoctorID;

-- View the No. of Consultations per Patient
SELECT PatientID, FirstName, LastName, COUNT(ConsultationID)  AS
NoConsultationsPerPatient
FROM Patient NATURAL JOIN Consults
GROUP BY PatientID;

-- Sort patients by their age in ascending order.
SELECT
    FirstName,
    LastName,
    TIMESTAMPDIFF(YEAR, DateOfBirth, CURRENT_DATE()) as Age
FROM Patient
ORDER BY Age;

-- Display patients to be treated ordered by time
SELECT FirstName, LastName, TimeSlot AS NextConsultation
FROM Patient NATURAL JOIN Treats
GROUP BY Patient
ORDER BY TimeSlot;

### UPDATE and DELETE ##################################################

# [UPDATE] Nurses who reports to Jeremy Little (D-19447138) 
# must report to Hannah Gonzalez (D-25493670) in stead. 
# This can be understood as Little is in charge of 
# trainees, Gonzalez in charge of more experienced. Nurses 
# are then moved when they have passed training. 
# 
# Before update Little has two nurses who report to them. 
# After the update, those two nurses now report to Gonzalez.  
SELECT Doctor.LastName as "Doctor's Last Name", ReportsTo.NurseID as "Nurse ID"
FROM ReportsTo NATURAL JOIN Doctor 
WHERE ReportsTo.DoctorID IN ('D-25493670', 'D-19447138'); 
#
UPDATE ReportsTo SET DoctorID = 
  Case 
    WHEN DoctorID = 'D-19447138' THEN 'D-25493670'
    ELSE DoctorID
  END;

# [DELETE] Delete consultations where the log is empty 
# and the consultations has taken place, ie. the current 
# day is later than the consultation day. 
# 
# Add two new consultations where the log is empty, one before 
# current date and on after. 
INSERT Consults VALUES 
  ('C-300', 'D-65175607', 'P-71655523', 'R-189', '2023-04-12 10:00:00', '2022-04-12 11:30:00', NULL),
  ('C-301', 'D-56252722', 'P-49272331', 'R-100', '2022-03-05 07:20:00', '2022-03-05 08:00:00', NULL);
# 
SELECT * FROM Consults WHERE isnull(Log);
# 
DELETE FROM Consults WHERE 
  TIMESTAMPDIFF(DAY, EndTime, CURRENT_DATE()) > 0 
  AND isnull(log); 


# Apply functions, procedures, triggers, and events (as in section 9) ####################################
##########################################################################################################
# --------------------------------------------------------------------------------------------------------
-- Create a Procedure that copies all Expired 
-- prescriptions into an old backup table PrescribesOld
-- and therefore also delete all Expired prescriptions in the table Prescribes
DROP TABLE IF EXISTS PrescribesOld;
CREATE TABLE PrescribesOld LIKE Prescribes;

DROP PROCEDURE IF EXISTS PrescribesBackup;

DELIMITER //
CREATE PROCEDURE PrescribesBackup()
BEGIN
	SET SQL_SAFE_UPDATES = 0;
	INSERT INTO PrescribesOld
	SELECT * FROM Prescribes WHERE Prescribes.PrescriptionStatus = 'Expired';
	DELETE FROM Prescribes WHERE Prescribes.PrescriptionStatus = 'Expired';
END//
DELIMITER ;

# Example Usage ########
CALL PrescribesBackup;
SELECT * FROM PrescribesOld;
SELECT * FROM Prescribes; #notice exipred prescriptions dissapeared

# --------------------------------------------------------------------------------------------------------
-- Create a Event that calls the PrescribesBackup procedure
-- once a week

DROP TABLE IF EXISTS PrescribesOld;
CREATE TABLE PrescribesOld LIKE Prescribes;
ALTER TABLE PrescribesOld ADD LogTime TIMESTAMP(6);

CREATE EVENT PrecriptionEvent
ON SCHEDULE
	EVERY 1 WEEK
    STARTS '2016-02-21 00:00:01'
    DO
		CALL PrescribesBackup;

# Example Usage ########
SET GLOBAL event_scheduler = 1;
SHOW VARIABLES LIKE 'event_scheduler';    


# --------------------------------------------------------------------------------------------------------
-- Create a procedure InsertConsultation for
-- inserting a row into the Consults table. It
-- should signal an error in case the insertion of
-- the new tuple leads to a violation of the
-- constraint: start time of a consultation is before end time of the consultation

## AUXILIARY FUNCTION:
-- checks whether a consultation start time is before the consultation's end-time

DROP FUNCTION IF EXISTS Normal_Start_End_Time;

CREATE FUNCTION Normal_Start_End_Time(vStartTime DATETIME, vEndTime DATETIME) 
				RETURNS BOOLEAN
RETURN
vStartTime < vEndTime;

# Example Usage ########
SELECT Normal_Start_End_Time('2022-04-12 10:00:00', '2022-04-12 11:30:00'); # returns 1, as in TRUE
SELECT Normal_Start_End_Time('2022-04-12 10:00:00', '2022-04-12 09:30:00'); # returns 0, as in FALSE


DROP PROCEDURE IF EXISTS InsertConsultation;
DELIMITER //
CREATE PROCEDURE InsertConsultation
	(
    IN vConsultationID VARCHAR(5),
    IN vDoctorID VARCHAR(10),
    IN vPatientID         VARCHAR(10),
    IN vRoomNo            VARCHAR(5),
    IN vStartTime         DATETIME, 
    IN vEndTime           DATETIME,
    IN vLog               VARCHAR(500)
    )
 BEGIN
	IF NOT (SELECT Normal_Start_End_Time(vStartTime, vEndTime))
	THEN SIGNAL SQLSTATE 'HY000'
	SET MYSQL_ERRNO = 1530, MESSAGE_TEXT = 'Consultation Time Interval Not Allowed: Start Time of the consultation must be before the End Time!'; 
    END IF;
    INSERT INTO Consults  VALUES (vConsultationID, vDoctorID, vPatientID, vRoomNo, vStartTime, vEndTime, vLog); 
END//
DELIMITER ;

# Example Usage ########
CALL InsertConsultation('C-243', 'D-56252722', 'P-49272331', 'R-100', '2022-03-10 07:20:00', '2022-03-10 08:00:00', 'Patient is sick - needs further consultations'); # no error
CALL InsertConsultation('C-244', 'D-56252722', 'P-49272331', 'R-100', '2022-03-10 09:20:00', '2022-03-10 08:00:00', 'Patient is sick - needs further consultations'); # ERNO 1530

# --------------------------------------------------------------------------------------------------------
-- Create a Trigger named Treats_Before_Insert that
-- after a new Treats row has been inserted into the table
-- it will signal an error in case the insertion of
-- the new Treats occurrence leads to a violation of the
-- constraints

# Constraints
-- The patient must be treated only with the prescribed treatment from the doctor
-- Administered treatment must be after the date of the prescription
-- Once the prescription is Expired, the nurse cannot administer the treatment anymore 

DROP TRIGGER IF EXISTS HospitalDatabase.Treats_Before_Insert;

DELIMITER //
CREATE TRIGGER Treats_Before_Insert
BEFORE INSERT ON Treats FOR EACH ROW
BEGIN
	IF New.TreatmentID NOT IN (SELECT TreatmentID FROM Prescribes WHERE Prescribes.PatientID = New.PatientID)
	THEN 
		SIGNAL SQLSTATE 'HY000'
		SET MYSQL_ERRNO = 1525, MESSAGE_TEXT = 'NOT ALLOWED: There is no such treatment prescribed for this patient!'; 
    END IF;
    IF NOT EXISTS (SELECT StartTime FROM Prescribes WHERE (Prescribes.StartTime < New.TimeSlot AND Prescribes.TreatmentID = New.TreatmentID AND Prescribes.PatientID = New.PatientID))
	THEN 
		SIGNAL SQLSTATE 'HY000'
		SET MYSQL_ERRNO = 1526, MESSAGE_TEXT = 'NOT ALLOWED: The Treatment Administered is before Prescription Time!'; 
    END IF;
    IF 'Expired' IN (SELECT PrescriptionStatus FROM Prescribes WHERE Prescribes.TreatmentID = New.TreatmentID AND Prescribes.PatientID = New.PatientID)
    THEN
		SIGNAL SQLSTATE 'HY000'
        SET MYSQL_ERRNO = 1527, MESSAGE_TEXT = 'NOT ALLOWED: Treatment is Expired!'; 
	END IF;
END//
DELIMITER ;

SELECT * FROM Prescribes;

# Example Usage ########
INSERT Treats VALUES ('N-28455410','2022-04-16 13:30:00','T-100','P-30832207','R-203'); # Allowed!
INSERT Treats VALUES ('N-28455410','2022-04-18 13:30:00','T-125','P-30832207','R-203');   # ERNO 1525 - No Such Treatment
INSERT Treats VALUES ('N-28455410','2022-04-12 11:00:00','T-101','P-71655523','R-110');  # ERNO 1526 - Treatment Administered is before Prescription Time!
INSERT Treats VALUES ('N-28455410','2022-04-13 12:00:00','T-130','P-71655523','R-110'); # ERNO 1527 - Treatment Expired

# --------------------------------------------------------------------------------------------------------
-- Create a Trigger that once a patient's status changes to Healthy
-- then all his/her prescriptions in the Prescribes table are set to Expired
DROP TRIGGER IF EXISTS HospitalDatabase.Prescribes_After_PatientEdit;

DELIMITER //
CREATE TRIGGER Prescribes_After_PatientEdit
AFTER UPDATE ON Patient FOR EACH ROW
BEGIN
	IF New.PatientStatus = 'Healthy'
    THEN
		UPDATE Prescribes
        SET Prescribes.PrescriptionStatus = 'Expired'
        WHERE Prescribes.PatientID = New.PatientID;
	END IF;
END//
DELIMITER ;

# Example Usage ########

# see changes before:
SELECT * FROM Prescribes;

# run an update which sets the trigger:
UPDATE Patient
SET PatientStatus = 'Healthy'
WHERE PatientID = 'P-30832207';

# see changes after
SELECT * FROM Prescribes;

# running the example usage above and having the Treats_Before_Insert trigger on as well should raise Error Message for this one:
INSERT Treats VALUES ('N-28455410','2022-04-20 13:30:00','T-100','P-30832207','R-203'); # ERNO 1527 - Treatment Expired

# 
# --------------------------------------------------------------------------------------------------------
-- Create a Trigger that before another nurse administers a treatment
-- There is a new row added to the ReportsTo table where that nurse is added 
-- to the ReportTo table to the doctor who prescribed that treatment

DROP TRIGGER IF EXISTS HospitalDatabase.ReportsTo_After_Treatment;

DELIMITER //
CREATE TRIGGER ReportsTo_After_Treatment
BEFORE INSERT ON Treats FOR EACH ROW
BEGIN
	SELECT DoctorID INTO @vDoctorID FROM Prescribes WHERE Prescribes.PatientID = New.PatientID;
	INSERT ReportsTo VALUES (New.NurseID, @vDoctorID);
END//
DELIMITER ;

# Example Usage ########
SELECT * FROM ReportsTo;

INSERT Treats VALUES ('N-89283519','2022-04-20 13:30:00','T-110','P-93900040','R-203');

SELECT * FROM ReportsTo;
# CREATE DATABASE HospitalDatabase;
USE HospitalDatabase;
# The file contains: 
# (1) the statements used to create the database, its tables and views (as used in section 5 of the report)
# (2) the statements used to populate the tables (as used in section 6)

### Drop statements ###
#SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Prescribes;
DROP TABLE IF EXISTS Treats;
DROP TABLE IF EXISTS ReportsTo;
DROP TABLE IF EXISTS Consults;
DROP TABLE IF EXISTS Patient;
DROP TABLE IF EXISTS Nurse;
DROP TABLE IF EXISTS Doctor;
DROP TABLE IF EXISTS Treatment;



### Table creation ###

CREATE TABLE Patient
( PatientID       VARCHAR(10) PRIMARY KEY,  # Danish social seciry CPR.
  FirstName       VARCHAR(20) NOT NULL,
  LastName        VARCHAR(15) NOT NULL,
  DateOfBirth     DATE,
  Address      	  VARCHAR(100),
  PhoneNo         VARCHAR(8),              # Danish phone number.
  PatientStatus   ENUM('Healthy', 'Sick')
);

CREATE TABLE Doctor
  ( DoctorID      	VARCHAR(10) PRIMARY KEY,   # Danish social seciry CPR.
    FirstName       VARCHAR(20) NOT NULL,
    LastName        VARCHAR(15) NOT NULL,
    DateOfBirth   	DATE,
    Address      	VARCHAR(100),
    PhoneNo       	VARCHAR(8)
  );

CREATE TABLE Nurse
  ( NurseID     	VARCHAR(10) PRIMARY KEY,
    FirstName   	VARCHAR(20) NOT NULL,
	LastName   		VARCHAR(20) NOT NULL,
    DateOfBirth 	DATE,
    Address      	VARCHAR(100),
    PhoneNo     	VARCHAR(8)
  );
  
CREATE TABLE ReportsTo
( NurseID     VARCHAR(10),
  DoctorID    VARCHAR(10),
  PRIMARY KEY(DoctorID, NurseID),
  FOREIGN KEY (NurseID) REFERENCES Nurse(NurseID) ON DELETE CASCADE ,
  FOREIGN KEY (DoctorID) REFERENCES Doctor(DoctorID) ON DELETE CASCADE
);

CREATE TABLE Treatment
( TreatmentID    		 VARCHAR(5),
  TreatmentDescription   VARCHAR(200),
  PRIMARY KEY(TreatmentID)
);


CREATE TABLE Consults
  ( ConsultationID    VARCHAR(5) PRIMARY KEY,
    DoctorID          VARCHAR(10),
    PatientID         VARCHAR(10),
    RoomNo            VARCHAR(5),
    StartTime         DATETIME, # Time slot split into start and end 
    EndTime           DATETIME,
    Log               VARCHAR(500), # Can write a few sentences. 
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE,
    FOREIGN KEY (DoctorID) REFERENCES Doctor(DoctorID) ON DELETE CASCADE
  );
  
  CREATE TABLE Prescribes
  ( PatientID    		VARCHAR(10),
    DoctorID   			VARCHAR(10),
    TreatmentID 		VARCHAR(5),
    StartTime       	DATETIME,
    PrescriptionStatus 	ENUM('Active','Expired'),
    PRIMARY KEY(DoctorID,PatientID,TreatmentID),
    FOREIGN KEY (DoctorID) REFERENCES Doctor(DoctorID) ON DELETE CASCADE,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE
    ,
  FOREIGN KEY (TreatmentID) REFERENCES Treatment(TreatmentID) ON DELETE CASCADE
);

CREATE TABLE Treats
(   NurseID       VARCHAR(10),
    TimeSlot      DATETIME,
    TreatmentID   VARCHAR(5),
    PatientID     VARCHAR(10),
    RoomNo        VARCHAR(5),
    PRIMARY KEY(NurseID, TimeSlot,TreatmentID),
    FOREIGN KEY (NurseID) REFERENCES Nurse(NurseID) ON DELETE CASCADE,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE,
    FOREIGN KEY (TreatmentID) REFERENCES Treatment(TreatmentID) ON DELETE CASCADE
);


### Data insertion ###

INSERT Patient VALUES
('P-30832207','Sarah','Obrien','1980-05-26','651 John Village
South Jamesfort, MT 80328','27872688','sick'),
('P-34741343','Jose','Allen','1978-06-15','29148 Stacey Tunnel
West Joseph, AL 80159','94116913','sick'),
('P-31071160','David','Mills','1989-09-21','127 Edgar Shore
Sullivanchester, NJ 47197','14990068','sick'),
('P-42085532','Kristin','White','1974-05-06','5090 Bernard Station
Lake Jonathan, VT 03111','93895292','sick'),
('P-49272331','Sherry','Elliott','1994-05-15','503 Jennifer Camp
Martinezmouth, HI 24415','81696077','sick'),
('P-90139518','Johnathan','Martinez','2015-03-17','174 Kelsey Islands Suite 631
Bishopport, NH 51523','33260264','healthy'),
('P-56860223','Joshua','Ortega','1984-11-06','Unit 0227 Box 2939
DPO AE 17757','02482430','healthy'),
('P-57429295','Sean','Rogers','2002-03-27','3350 Sparks Prairie
Jennifermouth, MA 20319','39693740','healthy'),
('P-63837950','Ashley','Mccoy','1971-03-18','32906 Montoya Viaduct Suite 959
Rubiofurt, MA 96387','18562106','healthy'),
('P-24809947','Mary','French','1981-08-13','9416 Sarah Cliffs Apt. 797
Portertown, OR 68108','51501039','sick'),
('P-94760272','Shawn','Campbell','1984-10-20','821 Houston Camp
Martinezland, WA 02608','51338074','sick'),
('P-57116744','Matthew','Hicks','1978-02-07','70201 Cervantes Drive Apt. 711
Edwardsview, TN 97246','63317133','sick'),
('P-71655523','Michael','Smith','1980-09-25','3111 Gabriel Forest
Jenningston, UT 74299','01030410','sick'),
('P-93900040','Christina','Taylor','2001-02-17','7748 Shelton Mill
Hamptonhaven, MS 66449','67853613','sick'),
('P-56377484','Michael','Davila','1978-04-07','823 Jones Ridge Apt. 700
East Christopher, NM 21698','17967804','healthy');

INSERT Doctor VALUES
('D-19447138','Jeremy','Little','1996-04-15','79010 Nelson Common
Christinaland, ME 42809','89878136'),
('D-34965336','Matthew','Weber','1984-10-06','PSC 7571, Box 6758
APO AA 06726','04647969'),
('D-25493670','Hannah','Gonzalez','1974-03-28','4999 Davies Station
Moranton, CO 35197','04931406'),
('D-34687454','Caroline','Anderson','1976-12-20','Unit 3950 Box 7395
DPO AE 60005','92639815'),
('D-56252722','Michele','Lindsey','1967-08-10','18849 Stephens Bypass
Wilsonton, WV 49810','49956718'),
('D-81464876','Heather','Lee','1987-09-29','30844 Natalie Fall Suite 305
East Laura, NE 51290','17829879'),
('D-98052012','Heather','Vang','1988-10-31','98674 Stephen Creek Suite 019
West Sharon, NJ 86547','23441105'),
('D-65175607','Whitney','Garcia','1970-08-11','49894 Gordon Courts Apt. 276
Jessicashire, IL 80313','14915758'),
('D-56415958','Kyle','Marshall','1974-08-12','Unit 5860 Box 7114
DPO AA 15767','54993586'),
('D-88848630','Sarah','Peterson','1955-03-14','062 Lauren Manors Suite 001
Johnsontown, MD 73695','82136788');

INSERT Nurse VALUES
('N-28455410','Dana','Keith','1998-01-06','20254 Shane Knolls Apt. 307
New Megan, KS 32756','95045897'),
('N-33576051','Kristin','Clark','1994-02-01','824 Perry Course
West Davidhaven, WV 97203','45228588'),
('N-33184831','Nicholas','Lopez','1992-04-07','117 Merritt Ville
Johnsonburgh, WV 66179','17133765'),
('N-65917738','Allen','Barker','1973-05-28','0330 Paula Wall
Petersonland, FL 75551','46523468'),
('N-64664542','Mary','Fields','1986-01-21','9763 Benjamin Motorway
North Deniseside, NC 39086','96469320'),
('N-89283519','Larry','Smith','1987-10-24','625 Pamela Glen Apt. 418
North Davidstad, WI 04306','90587330'),
('N-48472376','Greg','Walker','1982-01-19','290 Alicia Villages Apt. 881
Dianastad, MI 95026','20932032'),
('N-46931007','Joshua','Thompson','1985-05-12','0601 Molly Plains Suite 066
Port Wesley, SD 08228','41122489'),
('N-49332298','Pamela','Bradley','1973-08-28','5388 David Course Suite 645
Lake Gabrieltown, ND 92953','68224453'),
('N-62992232','Stacey','Graham','1976-08-14','59321 Middleton Hollow Apt. 484
Serranomouth, SD 11767','60568720'),
('N-61865163','Anita','Garcia','1977-08-13','USNV Clark
FPO AP 75822','87931033'),
('N-68701394','Molly','Jackson','1981-01-06','1948 Crystal Prairie
Taylorstad, AZ 71072','60417529'),
('N-52317711','Stuart','Thomas','1982-04-20','255 John Manors Suite 967
East Michael, DC 63350','76162488')
;

INSERT Treatment VALUES
('T-100','Antibody Treatment'),
('T-101','Chemotherapy'),
('T-105','Dialysis'),
('T-110','Antibiotics Injection'),
('T-111','Painkillers'),
('T-115','Buprenorphine Injection'),
('T-120','Steroid Injection'),
('T-121','Perfusion'),
('T-125','Blood Transfer'),
('T-130','Morphine Injection')
;

INSERT Consults VALUES
('C-234', 'D-65175607', 'P-71655523', 'R-189', '2022-04-12 10:00:00', '2022-04-12 11:30:00', 'Patient is sick with cancer'),
('C-235', 'D-56415958', 'P-42085532', 'R-188', '2022-04-21 08:00:00', '2022-04-21 08:10:00', 'Patient is sick with COVID'),
('C-236', 'D-98052012', 'P-93900040', 'R-189', '2022-04-12 10:00:00', '2022-04-12 11:30:00', 'Patient is sick with pneumonia'),
('C-237', 'D-19447138', 'P-30832207', 'R-189', '2022-04-12 10:00:00', '2022-04-12 11:30:00', 'Patient has all sort of diseases - see prescription'),
('C-238', 'D-56252722', 'P-56377484', 'R-100', '2022-03-05 07:20:00', '2022-03-05 08:00:00', 'Patient is healthy - no need for prescription'),
('C-239', 'D-56252722', 'P-49272331', 'R-100', '2022-03-05 07:20:00', '2022-03-05 08:00:00', 'Patient is sick - needs further consultations'),
('C-240', 'D-56252722', 'P-49272331', 'R-100', '2022-03-06 07:20:00', '2022-03-05 08:00:00', 'Patient is still sick - needs further consultations')
;

INSERT Prescribes VALUES
# all patients who are getting a treatment are also getting the prescription
# also, patients are only prescribed the treatment they are being administered
('P-71655523', 'D-65175607', 'T-130', '2022-04-12 12:00:00', 'Expired'),
('P-71655523', 'D-65175607', 'T-101', '2022-04-12 12:00:00', 'Active'),
('P-42085532', 'D-56415958', 'T-100', '2022-04-21 12:10:00', 'Active'),
('P-93900040', 'D-98052012', 'T-110', '2022-04-12 12:30:00', 'Active'),
('P-30832207', 'D-19447138', 'T-100', '2022-04-12 12:30:00', 'Active'), # Doc D-19447138 has patients: P-30832207. Assigned nurses: N-28455410,
('P-30832207', 'D-19447138', 'T-110', '2022-04-12 12:30:00', 'Active'),
('P-30832207', 'D-19447138', 'T-130', '2022-04-12 12:30:00', 'Active') #same patient, doc but different treatment - assign: N-28455410 to Doc
;

INSERT Treats VALUES
('N-28455410','2022-04-14 12:00:00','T-101','P-71655523','R-110'),
('N-33576051','2022-04-14 12:30:00','T-100','P-30832207','R-110'),
('N-49332298','2022-04-22 12:10:00','T-100','P-42085532','R-230'),
('N-68701394','2022-04-15 12:30:00','T-110','P-93900040','R-103'),
('N-52317711','2022-04-16 12:30:00','T-110','P-30832207','R-103'),
('N-28455410','2022-04-18 12:30:00','T-130','P-30832207','R-203'),
('N-28455410','2022-04-20 12:30:00','T-130','P-30832207','R-203') # same: patient, treatment, nurse, room but different time
;

INSERT ReportsTo VALUES
('N-28455410', 'D-65175607'),
('N-49332298', 'D-56415958'),
('N-68701394','D-98052012'),
('N-33576051','D-19447138'),
('N-28455410','D-19447138')
;
#Nurse reports to the doctor only if nurse administers the prescribed treatment of the doctor






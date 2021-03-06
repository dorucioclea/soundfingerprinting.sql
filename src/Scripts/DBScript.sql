USE master
IF EXISTS (SELECT NAME FROM sys.databases WHERE NAME = 'FingerprintsDb')
BEGIN
	DROP DATABASE FingerprintsDb
END
GO
CREATE DATABASE FingerprintsDb
GO
USE FingerprintsDb
GO
ALTER DATABASE FingerprintsDb SET RECOVERY SIMPLE;
GO
CHECKPOINT;
GO
CHECKPOINT; -- run twice to ensure file wrap-around
GO
DBCC SHRINKFILE(FingerprintsDb_log, 1024);
GO
-- TABLE WHICH WILL CONTAIN TRACK METADATA
CREATE TABLE Tracks
(
	Id INT IDENTITY(1, 1) NOT NULL,
	ISRC VARCHAR(50),
	Artist VARCHAR(255),
	Title VARCHAR(255),
	Album VARCHAR(255),
	ReleaseYear INT DEFAULT 0,
	Length FLOAT DEFAULT 0,
	CONSTRAINT CK_TracksTrackLength CHECK(Length > -1),
	CONSTRAINT CK_ReleaseYear CHECK(ReleaseYear > -1),
	CONSTRAINT PK_TracksId PRIMARY KEY(Id)
)
GO 
-- TABLE WHICH CONTAINS ALL THE INFORMATION RELATED TO SUB-FINGERPRINTS
-- USED BY LSH+MINHASH SCHEMA
CREATE TABLE SubFingerprints
(
	Id BIGINT IDENTITY(1, 1) NOT NULL,
	TrackId INT NOT NULL,
	SequenceNumber INT NOT NULL,
	SequenceAt FLOAT NOT NULL,
    HashTable_0 INT NOT NULL,
    HashTable_1 INT NOT NULL,
    HashTable_2 INT NOT NULL,
    HashTable_3 INT NOT NULL,
    HashTable_4 INT NOT NULL,
    HashTable_5 INT NOT NULL,
    HashTable_6 INT NOT NULL,
    HashTable_7 INT NOT NULL,
    HashTable_8 INT NOT NULL,
    HashTable_9 INT NOT NULL,
    HashTable_10 INT NOT NULL,
    HashTable_11 INT NOT NULL,
    HashTable_12 INT NOT NULL,
    HashTable_13 INT NOT NULL,
    HashTable_14 INT NOT NULL,
    HashTable_15 INT NOT NULL,
    HashTable_16 INT NOT NULL,
    HashTable_17 INT NOT NULL,
    HashTable_18 INT NOT NULL,
    HashTable_19 INT NOT NULL,
    HashTable_20 INT NOT NULL,
    HashTable_21 INT NOT NULL,	
	HashTable_22 INT NOT NULL,	
	HashTable_23 INT NOT NULL,	
	HashTable_24 INT NOT NULL,
	Clusters VARCHAR(255),
	CONSTRAINT PK_SubFingerprintsId PRIMARY KEY(Id),
	CONSTRAINT FK_SubFingerprints_Tracks FOREIGN KEY (TrackId) REFERENCES dbo.Tracks(Id)
)
GO
-- TABLE FOR FINGERPRINTS (NEURAL NASHER)
CREATE TABLE Fingerprints
(
	Id INT IDENTITY(1,1) NOT NULL,
	Signature VARBINARY(4096) NOT NULL,
	TrackId INT NOT NULL,
	CONSTRAINT PK_FingerprintsId PRIMARY KEY(Id),
	CONSTRAINT FK_Fingerprints_Tracks FOREIGN KEY (TrackId) REFERENCES dbo.Tracks(Id)
)
GO
-- TABLE INDEXES
CREATE INDEX IX_TrackIdLookup ON Fingerprints(TrackId) 
GO
CREATE INDEX IX_TrackIdLookupOnSubfingerprints ON SubFingerprints(TrackId) 
GO
-- INSERT A TRACK INTO TRACKS TABLE
IF OBJECT_ID('sp_InsertTrack','P') IS NOT NULL
	DROP PROCEDURE sp_InsertTrack
GO
CREATE PROCEDURE sp_InsertTrack
	@ISRC VARCHAR(50),
	@Artist VARCHAR(255),
	@Title VARCHAR(255),
	@Album VARCHAR(255),
	@ReleaseYear INT,
	@Length FLOAT
AS
INSERT INTO Tracks (
	ISRC,
	Artist,
	Title,
	Album,
	ReleaseYear,
	Length
	) OUTPUT inserted.Id
VALUES
(
 	@ISRC, @Artist, @Title, @Album, @ReleaseYear, @Length
);
GO
-- INSERT INTO SUBFINGERPRINTS
IF OBJECT_ID('sp_InsertSubFingerprint','P') IS NOT NULL
	DROP PROCEDURE sp_InsertSubFingerprint
GO
CREATE PROCEDURE sp_InsertSubFingerprint
	@TrackId INT,
	@SequenceNumber INT,
	@SequenceAt FLOAT,
	@HashTable_0 INT,
    @HashTable_1 INT,
    @HashTable_2 INT,
    @HashTable_3 INT,
    @HashTable_4 INT,
    @HashTable_5 INT,
    @HashTable_6 INT,
    @HashTable_7 INT,
    @HashTable_8 INT,
    @HashTable_9 INT,
    @HashTable_10 INT,
    @HashTable_11 INT,
    @HashTable_12 INT,
    @HashTable_13 INT,
    @HashTable_14 INT,
    @HashTable_15 INT,
    @HashTable_16 INT,
    @HashTable_17 INT,
    @HashTable_18 INT,
    @HashTable_19 INT,
    @HashTable_20 INT,
    @HashTable_21 INT,	
	@HashTable_22 INT,	
	@HashTable_23 INT,	
	@HashTable_24 INT,
	@Clusters VARCHAR(255)
AS
BEGIN
INSERT INTO SubFingerprints (
	TrackId,
	SequenceNumber,
	SequenceAt,
	HashTable_0,
    HashTable_1,
    HashTable_2,
    HashTable_3,
    HashTable_4,
    HashTable_5,
    HashTable_6,
    HashTable_7,
    HashTable_8,
    HashTable_9,
    HashTable_10,
    HashTable_11,
    HashTable_12,
    HashTable_13,
    HashTable_14,
    HashTable_15,
    HashTable_16,
    HashTable_17,
    HashTable_18,
    HashTable_19,
    HashTable_20,
    HashTable_21,	
	HashTable_22,	
	HashTable_23,	
	HashTable_24,
	Clusters
	) OUTPUT inserted.Id
VALUES
(
	@TrackId, @SequenceNumber, @SequenceAt, @HashTable_0, @HashTable_1, @HashTable_2, @HashTable_3, @HashTable_4, @HashTable_5, @HashTable_6,
    @HashTable_7, @HashTable_8, @HashTable_9, @HashTable_10, @HashTable_11, @HashTable_12, @HashTable_13, @HashTable_14, @HashTable_15,
    @HashTable_16, @HashTable_17, @HashTable_18, @HashTable_19, @HashTable_20, @HashTable_21, @HashTable_22, @HashTable_23, @HashTable_24,
	@Clusters
);
END
GO
-- INSERT A FINGERPRINT INTO FINGERPRINTS TABLE USED BY NEURAL HASHER
IF OBJECT_ID('sp_InsertFingerprint','P') IS NOT NULL
	DROP PROCEDURE sp_InsertFingerprint
GO
CREATE PROCEDURE sp_InsertFingerprint
	@Signature VARBINARY(4096),
	@TrackId INT
AS
BEGIN
INSERT INTO Fingerprints (
	Signature,
	TrackId
	) OUTPUT inserted.Id
VALUES
(
	@Signature, @TrackId
);
END
GO
-- READ ALL TRACKS FROM THE DATABASE
IF OBJECT_ID('sp_ReadTracks','P') IS NOT NULL
	DROP PROCEDURE sp_ReadTracks
GO
CREATE PROCEDURE sp_ReadTracks
AS
SELECT * FROM Tracks
GO
-- READ A TRACK BY ITS IDENTIFIER
IF OBJECT_ID('sp_ReadTrackById','P') IS NOT NULL
	DROP PROCEDURE sp_ReadTrackById
GO
CREATE PROCEDURE sp_ReadTrackById
	@Id INT
AS
SELECT * FROM Tracks WHERE Tracks.Id = @Id
GO
-- READ FINGERPRINTS BY TRACK ID
IF OBJECT_ID('sp_ReadFingerprintByTrackId','P') IS NOT NULL
	DROP PROCEDURE sp_ReadFingerprintByTrackId
GO
CREATE PROCEDURE sp_ReadFingerprintByTrackId
	@TrackId INT
AS
BEGIN
	SELECT * FROM Fingerprints WHERE TrackId = @TrackId
END
GO
--- ------------------------------------------------------------------------------------------------------------
--- READ HASHBINS BY HASHBINS AND THRESHOLD TABLE
--- ADDED 20.10.2013 CIUMAC SERGIU
--- E.g. [25;36;89;56...]
--- -----------------------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_ReadFingerprintsByHashBinHashTableAndThreshold','P') IS NOT NULL
	DROP PROCEDURE sp_ReadFingerprintsByHashBinHashTableAndThreshold
GO
CREATE PROCEDURE sp_ReadFingerprintsByHashBinHashTableAndThreshold
	@HashBin_0 INT, @HashBin_1 INT, @HashBin_2 INT, @HashBin_3 INT, @HashBin_4 INT, 
	@HashBin_5 INT, @HashBin_6 INT, @HashBin_7 INT, @HashBin_8 INT, @HashBin_9 INT,
	@HashBin_10 INT, @HashBin_11 INT, @HashBin_12 INT, @HashBin_13 INT, @HashBin_14 INT, 
	@HashBin_15 INT, @HashBin_16 INT, @HashBin_17 INT, @HashBin_18 INT, @HashBin_19 INT,
	@HashBin_20 INT, @HashBin_21 INT, @HashBin_22 INT, @HashBin_23 INT, @HashBin_24 INT,
	@Threshold INT
AS
SELECT * FROM SubFingerprints, 
	( SELECT Id FROM 
	   (
		SELECT Id FROM SubFingerprints WHERE HashTable_0 = @HashBin_0
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_1 = @HashBin_1
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_2 = @HashBin_2
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_3 = @HashBin_3
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_4 = @HashBin_4
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_5 = @HashBin_5
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_6 = @HashBin_6
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_7 = @HashBin_7
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_8 = @HashBin_8
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_9 = @HashBin_9
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_10 = @HashBin_10
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_11 = @HashBin_11
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_12 = @HashBin_12
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_13 = @HashBin_13
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_14 = @HashBin_14
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_15 = @HashBin_15
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_16 = @HashBin_16
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_17 = @HashBin_17
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_18 = @HashBin_18
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_19 = @HashBin_19
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_20 = @HashBin_20
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_21 = @HashBin_21
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_22 = @HashBin_22
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_23 = @HashBin_23
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_24 = @HashBin_24
	  ) AS Hashes
	 GROUP BY Hashes.Id
	 HAVING COUNT(Hashes.Id) >= @Threshold
	) AS Thresholded
WHERE SubFingerprints.Id = Thresholded.Id	
GO
IF OBJECT_ID('sp_ReadSubFingerprintsByHashBinHashTableAndThresholdWithClusters','P') IS NOT NULL
	DROP PROCEDURE sp_ReadSubFingerprintsByHashBinHashTableAndThresholdWithClusters
GO
CREATE PROCEDURE sp_ReadSubFingerprintsByHashBinHashTableAndThresholdWithClusters
@HashBin_0 INT, @HashBin_1 INT, @HashBin_2 INT, @HashBin_3 INT, @HashBin_4 INT, 
	@HashBin_5 INT, @HashBin_6 INT, @HashBin_7 INT, @HashBin_8 INT, @HashBin_9 INT,
	@HashBin_10 INT, @HashBin_11 INT, @HashBin_12 INT, @HashBin_13 INT, @HashBin_14 INT, 
	@HashBin_15 INT, @HashBin_16 INT, @HashBin_17 INT, @HashBin_18 INT, @HashBin_19 INT,
	@HashBin_20 INT, @HashBin_21 INT, @HashBin_22 INT, @HashBin_23 INT, @HashBin_24 INT,
	@Threshold INT, @Clusters VARCHAR(255)
AS
SELECT * FROM SubFingerprints, 
	( SELECT Id FROM 
	   (
		SELECT Id FROM SubFingerprints WHERE HashTable_0 = @HashBin_0
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_1 = @HashBin_1
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_2 = @HashBin_2
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_3 = @HashBin_3
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_4 = @HashBin_4
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_5 = @HashBin_5
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_6 = @HashBin_6
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_7 = @HashBin_7
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_8 = @HashBin_8
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_9 = @HashBin_9
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_10 = @HashBin_10
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_11 = @HashBin_11
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_12 = @HashBin_12
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_13 = @HashBin_13
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_14 = @HashBin_14
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_15 = @HashBin_15
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_16 = @HashBin_16
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_17 = @HashBin_17
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_18 = @HashBin_18
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_19 = @HashBin_19
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_20 = @HashBin_20
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_21 = @HashBin_21
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_22 = @HashBin_22
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_23 = @HashBin_23
		UNION ALL
		SELECT Id FROM SubFingerprints WHERE HashTable_24 = @HashBin_24
	  ) AS Hashes
	 GROUP BY Hashes.Id
	 HAVING COUNT(Hashes.Id) >= @Threshold
	) AS Thresholded
WHERE SubFingerprints.Id = Thresholded.Id AND SubFingerprints.Clusters LIKE @Clusters
GO
IF OBJECT_ID('sp_ReadSubFingerprintsByTrackId','P') IS NOT NULL
	DROP PROCEDURE sp_ReadSubFingerprintsByTrackId
GO
CREATE PROCEDURE sp_ReadSubFingerprintsByTrackId
	@TrackId INT
AS
BEGIN
   SELECT * FROM SubFingerprints WHERE SubFingerprints.TrackId = @TrackId
END					 
-- READ TRACK BY ARTIST NAME AND SONG NAME
IF OBJECT_ID('sp_ReadTrackByArtistAndSongName','P') IS NOT NULL
	DROP PROCEDURE sp_ReadTrackByArtistAndSongName
GO
CREATE PROCEDURE sp_ReadTrackByArtistAndSongName
	@Artist VARCHAR(255),
	@Title VARCHAR(255) 
AS
SELECT * FROM Tracks WHERE Tracks.Title = @Title AND Tracks.Artist = @Artist
GO
-- READ TRACK BY ISRC
IF OBJECT_ID('sp_ReadTrackISRC','P') IS NOT NULL
	DROP PROCEDURE sp_ReadTrackISRC
GO
CREATE PROCEDURE sp_ReadTrackISRC
	@ISRC VARCHAR(50)
AS
SELECT * FROM Tracks WHERE Tracks.ISRC = @ISRC
GO
-- DELETE TRACK
IF OBJECT_ID('sp_DeleteTrack','P') IS NOT NULL
	DROP PROCEDURE sp_DeleteTrack
GO
CREATE PROCEDURE sp_DeleteTrack
	@Id INT
AS
BEGIN
	DELETE FROM SubFingerprints WHERE SubFingerprints.TrackId = @Id
	DELETE FROM Tracks WHERE Tracks.Id = @Id
END
GO

CREATE DATABASE Serials
USE Serials
CREATE TABLE TVChannels
(
	Id int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Name nvarchar(50) NOT NULL UNIQUE
)
CREATE TABLE Genre
(
	Id int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Name nvarchar(50) NOT NULL UNIQUE
)


CREATE TABLE Status
(
	Id int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Status nvarchar(50) UNIQUE CHECK (Status IN (('Continue'), ('Closed'), ('Decided the fate of the project')))
)

CREATE TABLE Serials
(
	Id int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Name nvarchar(50) NOT NULL,
	Id_TVChannel int NULL FOREIGN KEY REFERENCES TVChannels(Id) ON DELETE SET NULL ON UPDATE CASCADE,  
	"Description" TEXT, 
	id_Status int NULL FOREIGN KEY REFERENCES Status(Id) ON DELETE SET NULL ON UPDATE CASCADE
)

CREATE TABLE Series 
(
	Id int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Number int NOT NULL,
	Name nvarchar(50) NOT NULL,
	"Date" Date NULL,
	Duration time NULL,
	Id_Serial int NOT NULL FOREIGN KEY REFERENCES Serials(Id) ON DELETE NO ACTION ON UPDATE CASCADE,
	Season smallint NOT NULL
)


CREATE TABLE SerialGenre
(
	Id_Serial int  NOT NULL, 
	Id_Category int NOT NULL,
	CONSTRAINT PK_SerialCategory PRIMARY KEY (Id_Serial , Id_Category)
)

ALTER TABLE SerialGenre WITH CHECK 
ADD CONSTRAINT FKSerialGenreSerial FOREIGN KEY (Id_Serial) REFERENCES Serials(Id) ON DELETE CASCADE ON UPDATE CASCADE
ALTER TABLE SerialGenre WITH CHECK 
ADD CONSTRAINT FKSerialGenreCategory FOREIGN KEY (Id_Category) REFERENCES Genre(Id) ON DELETE CASCADE ON UPDATE CASCADE


CREATE TABLE Users
(
	Id int IDENTITY (1,1) PRIMARY KEY,
	Name nvarchar(50) NOT NULL UNIQUE,
	"Password" nvarchar(50) NOT NULL,
	Email nvarchar(50) NOT NULL UNIQUE
)

CREATE TABLE ViewedSerials
(
	Id_Serial int  NOT NULL, 
	Id_User int NOT NULL,
	CONSTRAINT PK_ViewedSerials PRIMARY KEY (Id_Serial , Id_User)
)

ALTER TABLE ViewedSerials WITH CHECK 
ADD CONSTRAINT FKViewedSerials FOREIGN KEY (Id_Serial) REFERENCES Serials(Id) ON DELETE CASCADE ON UPDATE CASCADE
ALTER TABLE ViewedSerials WITH CHECK 
ADD CONSTRAINT FKViewedUsers FOREIGN KEY (Id_User) REFERENCES Users(Id)ON DELETE CASCADE ON UPDATE CASCADE

CREATE TABLE WatchingSerials
(
	Id_Serial int  NOT NULL, 
	Id_User int NOT NULL,
	CONSTRAINT PK_WatchingSerials PRIMARY KEY (Id_Serial , Id_User)
)

ALTER TABLE WatchingSerials WITH CHECK 
ADD CONSTRAINT FKWatchingSerials FOREIGN KEY (Id_Serial) REFERENCES Serials(Id) ON DELETE CASCADE ON UPDATE CASCADE
ALTER TABLE WatchingSerials WITH CHECK 
ADD CONSTRAINT FKWatchingUsers FOREIGN KEY (Id_User) REFERENCES Users(Id) ON DELETE CASCADE ON UPDATE CASCADE


CREATE TABLE Likes
(
	Id_Series int  NOT NULL, 
	Id_User int NOT NULL,
	CONSTRAINT PK_Likes PRIMARY KEY (Id_Series , Id_User)
)

ALTER TABLE Likes WITH CHECK 
ADD CONSTRAINT FKLikesSeries FOREIGN KEY (Id_Series) REFERENCES Series(Id) ON DELETE CASCADE ON UPDATE CASCADE
ALTER TABLE Likes WITH CHECK 
ADD CONSTRAINT FKLikesUsers FOREIGN KEY (Id_User) REFERENCES Users(Id) ON DELETE CASCADE ON UPDATE CASCADE


CREATE TABLE Marks
(
	Id_Serial int  NOT NULL, 
	Id_User int NOT NULL,
	Mark int NOT NULL CHECK (Mark Between 0 and 100), 
	CONSTRAINT PK_Reviews PRIMARY KEY (Id_Serial , Id_User)
)

ALTER TABLE Marks WITH CHECK 
ADD CONSTRAINT FKMarksSerials FOREIGN KEY (Id_Serial) REFERENCES Serials(Id) ON DELETE CASCADE ON UPDATE CASCADE
ALTER TABLE Marks WITH CHECK 
ADD CONSTRAINT FKMarksUsers FOREIGN KEY (Id_User) REFERENCES Users(Id) ON DELETE CASCADE ON UPDATE CASCADE


GO
CREATE PROCEDURE  sp_add_user @Name nvarchar(50), @Password nvarchar(50), @Mail nvarchar(50)
AS
	BEGIN TRANSACTION
	
	declare @register nvarchar(4000) = 'create login ['+@Name+'] with password = '''+@Password+''', default_database=[Serials]'
	execute (@register)
	SET @register = 'create user ['+@Name+'] for login ['+@Name+']'
	execute (@register)

	INSERT INTO Serials.dbo.Users
	VALUES (@Name,@Password,@Mail)

	exec sp_addrolemember 'UserDb', @Name

	COMMIT TRANSACTION


GO
CREATE PROCEDURE sp_my_serials @UserName nvarchar(50)
AS
	declare @UserId int
	SELECT @UserId = id FROM Users WHERE Name = @UserName 
	SELECT Serials.Name as 'Название сериала',  MIN(YEAR(Date)) as 'Год', MAX(Season) as 'Количество сезонов', Status as 'Статус', Mark as 'Моя оценка'
	FROM Serials JOIN Series ON Serials.Id = Series.Id_Serial	
				 JOIN Status ON Serials.id_Status = Status.Id
				 LEFT JOIN Marks ON Marks.Id_User = @UserId AND Serials.Id = Marks.Id_Serial
	WHERE Serials.Id IN
	(
		SELECT Id_Serial
		FROM WatchingSerials
		WHERE Id_User = @UserId
	)
	GROUP BY Serials.Name,Status,Mark

GO
CREATE PROCEDURE sp_viewed_serials @UserName nvarchar(50)
AS
	declare @UserId int
	SELECT @UserId = id FROM Users WHERE Name = @UserName
	SELECT Serials.Name as 'Название сериала',  MIN(YEAR(Date)) as 'Год', MAX(Season) as 'Количество сезонов', Status as 'Статус',Mark as 'Моя оценка'
	FROM Serials JOIN Series ON Serials.Id = Series.Id_Serial	
				 JOIN Status ON Serials.id_Status = Status.Id
				 LEFT JOIN Marks ON Marks.Id_User = @UserId AND Serials.Id = Marks.Id_Serial
	WHERE Serials.Id IN
	(
		SELECT Id_Serial
		FROM ViewedSerials
		WHERE Id_User = @UserId
	)
	GROUP BY Serials.Name,Status,Mark


GO
CREATE PROCEDURE sp_genre @genre nvarchar(50)
AS
	DECLARE @Genre_id int;
	SET @Genre_id = (SELECT Id FROM Genre WHERE Genre.Name = @genre)

    SELECT Serials.Name as 'Название сериала',MIN(YEAR(Date)) as 'Год', MAX(Season) as 'Количество сезонов', Status as 'Статус', Genre.Name as 'Жанр'
	FROM Serials JOIN SerialGenre 
		on SerialGenre.Id_Serial= Serials.Id AND Id_Category = @Genre_id
				 JOIN Series ON Serials.Id = Series.Id_Serial	
				 JOIN Status ON Serials.id_Status = Status.Id
				 JOIN Genre ON Genre.Id = @Genre_id
	GROUP BY Serials.Name,Status,Genre.Name

GO
CREATE PROCEDURE sp_view_year @year int
AS
    SELECT Serials.Name as 'Название сериала',MIN(YEAR(Date)) as 'Год', MAX(Season) as 'Количество сезонов', Status as 'Статус'
	FROM Serials JOIN Series ON Serials.Id = Series.Id_Serial 	
				 JOIN Status ON Serials.id_Status = Status.Id
	GROUP BY Serials.Name,Status
	having MIN(YEAR(Date)) = @year

GO
CREATE PROCEDURE sp_view_status @status nvarchar(50)
AS
    SELECT Serials.Name as 'Название сериала',MIN(YEAR(Date)) as 'Год', MAX(Season) as 'Количество сезонов', Status as 'Статус'
	FROM Serials JOIN Series ON Serials.Id = Series.Id_Serial 	
				 JOIN Status ON Serials.id_Status = Status.Id
	GROUP BY Serials.Name,Status
	having Status = @status 

GO
CREATE PROCEDURE sp_rating
AS
	select Serials.Name as 'Название сериала', avg(Marks.Mark) as 'Средняя оценка'
	from Serials JOIN Marks ON Marks.Id_Serial = Serials.Id
	group by Serials.Name
	order by avg(Marks.Mark) Desc

GO
CREATE PROCEDURE sp_series @name nvarchar(50)
AS
	DECLARE @serial_id int;
	SET @serial_id = (SELECT Id FROM Serials WHERE Serials.Name = @name)
	SELECT Number, Name, Date, Duration, Season
	FROM Series
	WHERE Series.Id_Serial = @serial_id
	ORDER BY Season desc ,Number asc

GO 
CREATE PROCEDURE sp_my_likes @UserName nvarchar(50)
AS
	declare @UserId int
	SELECT @UserId = id FROM Users WHERE Name = @UserName
	SELECT Serials.Name as 'Название сериала',Series.Number as 'Номер серии', Series.Name as 'Название серии', Date as 'Дата', Duration as 'Длительность'
	FROM Series JOIN Likes ON Id_User = @UserId AND Id = Likes.Id_Series
				JOIN Serials ON Series.Id_Serial = Serials.Id
	ORDER BY Serials.Name

GO
CREATE PROCEDURE sp_my_series @UserName nvarchar(50)
AS
	declare @UserId int
	SELECT @UserId = id FROM Users WHERE Name = @UserName
	SELECT Serials.Name as 'Название сериала',Series.Number as 'Номер серии', Series.Name as 'Название серии', Date as 'Дата'
	FROM Series JOIN WatchingSerials ON WatchingSerials.Id_User = @UserId AND WatchingSerials.Id_Serial = Series.Id_Serial
				JOIN Serials ON Series.Id_Serial = Serials.Id
	--WHERE DATEDIFF(DAY,Series.Date,GETDATE()) < 0
	WHERE Series.Date > GETDATE()
	ORDER BY Serials.Name


--select  Serials.Name, Description, Genre.Name, TVChannels.Name as TVChannel
--from Genre join SerialGenre 
--				on SerialGenre.Id_Category = Genre.Id
--				LEFT join Serials on Serials.Id = SerialGenre.Id_Serial
--				JOIN TVChannels ON Serials.Id_TVChannel = TVChannels.Id

GO
CREATE PROCEDURE sp_add_watchingserial @UserName nvarchar(50), @SerialName nvarchar(50)
AS
    declare @UserId int 
	declare @SerialId int
	SELECT @UserId = id FROM Users WHERE Name = @UserName
	SELECT @SerialId = id FROM Serials WHERE Name = @SerialName

	INSERT INTO WatchingSerials
	VALUES (@SerialId,@UserId)

GO
CREATE PROCEDURE sp_add_viewedserial @UserName nvarchar(50), @SerialName nvarchar(50)
AS
    declare @UserId int 
	declare @SerialId int
	SELECT @UserId = id FROM Users WHERE Name = @UserName
	SELECT @SerialId = id FROM Serials WHERE Name = @SerialName

	INSERT INTO ViewedSerials
	VALUES (@SerialId,@UserId)

GO
CREATE PROCEDURE sp_add_mark @UserName nvarchar(50), @SerialName nvarchar(50), @Mark int 
AS
    declare @UserId int 
	declare @SerialId int
	SELECT @UserId = id FROM Users WHERE Name = @UserName
	SELECT @SerialId = id FROM Serials WHERE Name = @SerialName

	INSERT INTO Marks
	VALUES (@SerialId,@UserId,@Mark)


GO
CREATE PROCEDURE sp_add_serial @SerialName nvarchar(50),  @TVChanel nvarchar(50), @Description TEXT,  @Status nvarchar(50),  @Genre nvarchar(50)
AS 
	BEGIN TRANSACTION
	declare @tempId1 int
	SELECT @tempId1 = id FROM TVChannels WHERE Name =  @TVChanel
	declare @tempId2 int
	SELECT @tempId2 = id FROM Status WHERE Status =  @Status
	INSERT INTO Serials.dbo.Serials
	VALUES (@SerialName,@tempId1,@Description,@tempId2)
	
	SELECT @tempId1 = id FROM Serials WHERE Name = @SerialName
	SELECT @tempId2 = id FROM Genre WHERE Name = @Genre
	INSERT INTO SerialGenre
	VALUES (@tempId1, @tempId2)
	COMMIT TRANSACTION

GO
CREATE PROCEDURE sp_add_series  @SerialName nvarchar(50), @Number int, @EpisodeName nvarchar(50), @Date Date, @Drution time, @Season int
AS
	declare @tempId1 int
	SELECT @tempId1 = id FROM Serials WHERE Name = @SerialName
	INSERT INTO Serials.dbo.Series (Number,Name, Date, Id_Serial, Season,Duration)
	VALUES (@Number,@EpisodeName,convert(DATE,@Date),@tempId1,@Season,convert(TIME,@Drution,108))


GO
CREATE PROCEDURE sp_add_like @SerialName nvarchar(50),@EpisodeName nvarchar(50), @UserName nvarchar(50)
AS
	declare @tempId1 int
	SELECT @tempId1 = id FROM Serials WHERE Name = @SerialName

	declare @tempId2 int
	SELECT @tempId2 = id FROM Series WHERE Name =  @EpisodeName AND Id_Serial = @tempId1

	declare @tempId3 int
	SELECT @tempId3 = id FROM Users WHERE Name =  @UserName

	INSERT INTO Likes
	VALUES (@tempId2,@tempId3)
	



-------------------------------------------------------------------------------------------
CREATE ROLE UserDb
GRANT SELECT ON Genre TO UserDb
GRANT SELECT,INSERT ON Likes TO UserDb
GRANT SELECT,INSERT ON Marks TO UserDb
GRANT SELECT ON SerialGenre TO UserDb
GRANT SELECT ON Serials TO UserDb
GRANT SELECT ON Series TO UserDb
GRANT SELECT ON Status TO UserDb
GRANT SELECT ON TVChannels TO UserDb
GRANT SELECT,INSERT ON ViewedSerials TO UserDb
GRANT SELECT,INSERT ON WatchingSerials TO UserDb

GRANT EXECUTE ON sp_my_serials TO UserDb
GRANT EXECUTE ON sp_viewed_serials TO UserDb
GRANT EXECUTE ON sp_add_watchingserial TO UserDb
GRANT EXECUTE ON sp_add_viewedserial TO UserDb
GRANT EXECUTE ON sp_my_serials TO UserDb
GRANT EXECUTE ON sp_genre TO UserDb
GRANT EXECUTE ON sp_view_year TO UserDb
GRANT EXECUTE ON sp_view_status TO UserDb
GRANT EXECUTE ON sp_rating TO UserDb
GRANT EXECUTE ON sp_series TO UserDb
GRANT EXECUTE ON sp_my_likes TO UserDb
GRANT EXECUTE ON sp_my_series TO UserDb
GRANT EXECUTE ON sp_add_mark TO UserDb



CREATE ROLE ContentManager
GRANT SELECT,INSERT,DELETE,UPDATE ON Genre TO ContentManager
GRANT SELECT ON Marks TO ContentManager
GRANT SELECT,INSERT,DELETE,UPDATE ON SerialGenre TO ContentManager
GRANT SELECT,INSERT,DELETE,UPDATE ON Serials TO ContentManager
GRANT SELECT,INSERT,DELETE,UPDATE ON Series TO ContentManager
GRANT SELECT,INSERT,DELETE,UPDATE ON Status TO ContentManager
GRANT SELECT,INSERT,DELETE,UPDATE ON TVChannels TO ContentManager
GRANT SELECT ON ViewedSerials TO ContentManager
GRANT SELECT ON WatchingSerials TO ContentManager
GRANT EXECUTE ON sp_rating TO ContentManager
GRANT EXECUTE ON sp_series TO ContentManager
GRANT EXECUTE ON sp_genre TO ContentManager
GRANT EXECUTE ON sp_view_year TO ContentManager
GRANT EXECUTE ON sp_view_status TO ContentManager
GRANT EXECUTE ON sp_add_serial TO ContentManager
GRANT EXECUTE ON sp_add_series TO ContentManager


CREATE LOGIN [admin_db] WITH PASSWORD = '1337',
DEFAULT_DATABASE = Serials
CREATE USER [admin_db] FOR LOGIN [admin_db]
exec sp_addrolemember 'db_owner', 'admin_db'

CREATE LOGIN [content_manager] WITH PASSWORD = '322',
DEFAULT_DATABASE = Serials
CREATE USER [content_manager] FOR LOGIN [content_manager]
exec sp_addrolemember 'ContentManager','content_manager'

-------------------------------------------------------------------------------------------

INSERT INTO Serials.dbo.TVChannels
VALUES
('HBO'),
('History'),
('BBC One'),
('USA'),
('Showtime'),
('The CW'),
('Fox'),
('NBC')

INSERT INTO Serials.dbo.Genre
VALUES
('Detective'),
('Drama'),
('Comedy'),
('Mystic'),
('Thriller'),
('Horrors'),
('Fantasy')


INSERT INTO Serials.dbo.Status
VALUES ('Continue'), ('Closed'), ('Decided the fate of the project')

INSERT INTO Serials.dbo.Serials
VALUES ('Colony',4,NULL,1),('Sherlock',3,NULL,3),('Westworld',1,NULL,2)


INSERT INTO Serials.dbo.Series (Number,Name, Date, Id_Serial, Season,Duration)
VALUES (1,'Pilot',convert(DATE,'2015.12.15'),1,1,convert(TIME,'00:44',108)),
	(2,'Brave New World', convert(DATE,'2016.01.21'),1,1,convert(TIME,'00:44',108)),
	(3,'98 Seconds', convert(DATE,'2016.01.28'),1,1,convert(TIME,'00:44',108)),
	(4,'Blind Spot', convert(DATE,'2016.02.04'),1,1,convert(TIME,'00:44',108)),
	(5,'Geronimo', convert(DATE,'2016.02.11'),1,1,convert(TIME,'00:44',108)),
	(6,'Yoknapatawpha', convert(DATE,'2016.02.18'),1,1,convert(TIME,'00:44',108)),
	(7,'Broussard', convert(DATE,'2016.02.25'),1,1,convert(TIME,'00:44',108)),
	(8,'In from the Cold', convert(DATE,'2016.03.03'),1,1,convert(TIME,'00:44',108)),
	(9,'Zero Day',convert(DATE,'2016.03.10'),1,1,convert(TIME,'00:44',108)),
	(10,'Gateway', convert(DATE,'2016.03.17'),1,1,convert(TIME,'00:44',108)),
	(1,'Eleven.Thirteen',  convert(DATE,'2017.01.12'),1,2,convert(TIME,'00:44',108)),
	(2,'Somewhere Out There', convert(DATE,'2017.01.19'),1,2,convert(TIME,'00:44',108)),
	(3,'Sublimation',  convert(DATE,'2017.01.26'),1,2,convert(TIME,'00:44',108)),
	(4,'Panopticon',  convert(DATE,'2017.02.02'),1,2,convert(TIME,'00:44',108)),
	(5,'Company Man', convert(DATE,'2017.02.09'),1,2,convert(TIME,'00:44',108)),
	(6,'Fallout', convert(DATE,'2017.02.16'),1,2,convert(TIME,'00:44',108)),
	(7,'Free Radicals', convert(DATE,'2017.02.23'),1,2,convert(TIME,'00:44',108)),
	(8,'Good Intentions', convert(DATE,'2017.03.02'),1,2,convert(TIME,'00:44',108)),
	(9,'Tamam Shud', convert(DATE,'2017.03.09'),1,2,convert(TIME,'00:44',108)),
	(10,'The Garden of Beasts', convert(DATE,'2017.03.16'),1,2,convert(TIME,'00:44',108))

	
INSERT INTO Serials.dbo.Series (Number,Name, Date, Id_Serial, Season,Duration)
VALUES(1,'A Study in Pink',convert(DATE,'2010.07.25'),2,1,convert(TIME,'01:30',108)),
	(2,'The Blind Banker',convert(DATE,'2010.08.01'),2,1,convert(TIME,'01:30',108)),
	(3,'The Great Game',convert(DATE,'2010.08.08'),2,1,convert(TIME,'01:30',108)),
	(1,'A Scandal in Belgravia',convert(DATE,'2012.01.01'),2,2,convert(TIME,'01:30',108)),
	(2,'The Hounds of Baskerville',convert(DATE,'2012.01.08'),2,2,convert(TIME,'01:30',108)),
	(3,'The Reichenbach Fall',convert(DATE,'2012.01.15'),2,2,convert(TIME,'01:30',108)),
	(1,'The Empty Hearse',convert(DATE,'2014.01.01'),2,3,convert(TIME,'01:30',108)),
	(2,'The Sign of Three',convert(DATE,'2014.01.05'),2,3,convert(TIME,'01:30',108)),
	(3,'His Last Vow',convert(DATE,'2014.01.12'),2,3,convert(TIME,'01:30',108)),
	(1,'The Six Thatchers',convert(DATE,'2017.01.01'),2,4,convert(TIME,'01:30',108)),
	(2,'The Lying Detective',convert(DATE,'2017.01.08'),2,4,convert(TIME,'01:30',108)),
	(3,'The Final Problem',convert(DATE,'2017.10.15'),2,4,convert(TIME,'01:30',108))

INSERT INTO Serials.dbo.Series (Number,Name, Date, Id_Serial, Season,Duration)
VALUES(1,'The Original', convert(DATE,'2016.10.02'),3,1,convert(TIME,'01:00',108)),
	(2,'Chestnut', convert(DATE,'2016.10.09'),3,1,convert(TIME,'01:00',108)),
	(3,'The Stray',convert(DATE,'2016.10.16'),3,1,convert(TIME,'01:00',108)),
	(4,'Dissonance Theory',convert(DATE,'2016.10.23'),3,1,convert(TIME,'01:00',108)),
	(5,'Contrapasso',convert(DATE,'2016.10.30'),3,1,convert(TIME,'01:00',108)),
	(6,'The Adversary',convert(DATE,'2016.11.06'),3,1,convert(TIME,'01:00',108)),
	(7,'Trompe L Oeil',convert(DATE,'2016.11.13'),3,1,convert(TIME,'01:00',108)),
	(8,'Trace Decay',convert(DATE,'2016.11.20'),3,1,convert(TIME,'01:00',108)),
	(9,'The Well-Tempered Clavier',convert(DATE,'2016.11.27'),3,1,convert(TIME,'01:00',108)),
	(10,'The Bicameral Mind',convert(DATE,'2016.12.04'),3,1,convert(TIME,'01:00',108))

INSERT INTO Serials.dbo.SerialGenre
VALUES (3,2),(3,7),(2,2),(2,1),(1,2),(1,7)


exec sp_add_user 'test_user','test_user','test_user'

exec sp_add_viewedserial 'test_user','Westworld'

exec sp_add_watchingserial 'test_user', 'Colony'
exec sp_add_watchingserial 'test_user', 'Sherlock'

exec sp_add_mark 'test_user', 'Colony', 99
exec sp_add_mark 'test_user', 'Sherlock', 80
exec sp_add_mark 'test_user', 'Westworld', 50

exec sp_my_serials 'test_user'
exec sp_viewed_serials 'test_user'

INSERT INTO Likes
VALUES (1,1),(2,1),(3,1)

exec sp_my_likes 'test_user'

exec sp_my_series 'test_user'

exec sp_genre 'Fantasy'

exec sp_view_year '2010'

exec sp_view_status 'Continue'

exec sp_series 'Colony'

exec sp_rating

exec sp_add_serial 'TEST','Fox',NULL,'Continue','Comedy'
exec sp_add_series  'TEST',1,'The TEST', '2016.10.02', '01:00', 1
exec sp_add_like 'TEST', 'The TEST', 'test_user'
exec sp_add_watchingserial 'test_user','TEST'

-------------------------------------------------------------------------------------------------------------------------------
ALTER DATABASE Serials
SET RECOVERY FULL

exec sp_addumpdevice @devtype = 'disk', @logicalname = 'serialsBackUp', @physicalname ='C:\ШАГ 2015\Database\Serials\Serials.bak'
exec sp_helpdevice

DBCC CHECKDB ('serials') WITH ALL_ERRORMSGS --проверка всей дб
BACKUP DATABASE Serials TO serialsBackUp WITH NOINIT

RESTORE VERIFYONLY FROM serialsBackUp

RESTORE DATABASE Serials 
FROM serialsBackUp
WITH RECOVERY, REPLACE
-------------------------------------------------------------------------------------------------------------------------------

CREATE INDEX SerialName
ON Serials(Name)


CREATE INDEX UserName
ON Users(Name)

CREATE INDEX EpisodeName
ON Series(Name)







	
	
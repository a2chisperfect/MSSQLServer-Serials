
ALTER TABLE Serials ADD Path nvarchar(50)

ALTER TABLE Serials ALTER COLUMN Description nvarchar(100) NULL

UPDATE Serials
SET Path = 'C:\Posters\Colony.jpg'
WHERE Serials.Name ='Colony'



UPDATE Serials
SET Path = 'C:\Posters\sherlock.jpg'
WHERE Serials.Name ='Sherlock'

UPDATE Serials
SET Path = 'C:\Posters\Westworld.jpg'
WHERE Serials.Name ='Westworld'


Go
ALTER PROCEDURE sp_rating @count int 
AS
	SELECT TOP(@count)* FROM TEST
	order by TEST.[Average mark] Desc
	
	
GO
ALTER PROCEDURE sp_series @serial_id int
AS
	SELECT Serials.Name as 'SerialName',Series.Name as 'SeriesName', Date, Duration, Season,Series.Id,Number
	FROM Series JOIN Serials ON Series.Id_Serial = Serials.Id
	WHERE Series.Id_Serial = @serial_id
	ORDER BY Season desc ,Number asc
	
GO
CREATE PROCEDURE sp_get_serial_genres @serial_id int
AS
	SELECT Serials.Name as 'SerialName',Series.Name as 'SeriesName', Date, Duration, Season,Series.Id,Number
	FROM Series JOIN Serials ON Series.Id_Serial = Serials.Id
	WHERE Series.Id_Serial = @serial_id
	ORDER BY Season desc ,Number asc
	
GO
CREATE PROCEDURE sp_serial_genres @id_serial int
AS
	SELECT Genre.Id,Genre.Name
	FROM Genre JOIN SerialGenre ON SerialGenre.Id_Category = Genre.Id
	WHERE SerialGenre.Id_Serial = @id_serial
	
GRANT EXECUTE ON sp_serial_genres TO UserDB
	

GO 
ALTER PROCEDURE sp_my_likes @User_Id int
AS
	SELECT Id_Series FROM Likes
	WHERE Id_User = @User_Id
	
	
GO
ALTER PROCEDURE sp_add_like @User_Id int,@Series_Id int
AS
	INSERT INTO Likes
	VALUES (@Series_Id,@User_Id)

		
GO
CREATE PROCEDURE sp_remove_like @User_Id int,@Series_Id int
AS
	DELETE FROM Likes
	WHERE Id_User = @User_Id AND Id_Series =  @Series_Id


GRANT EXECUTE ON sp_remove_like TO UserDB
	
GO
CREATE PROCEDURE sp_user_mark @User_Id int,@Serial_Id int
AS
	Select Mark from Marks
	where Id_User = @User_Id AND Id_Serial = @Serial_Id
	
GRANT EXECUTE ON sp_user_mark TO UserDB
GO
CREATE VIEW TEST
AS
--SELECT Serials.Id as 'Id', Serials.Name as 'Name', Serials.Description as 'Description', TVChannels.Name as 'TVChannel', MIN(YEAR(Date)) as 'Year', MAX(Season) as 'Seasons', Status as 'Status', avg(Marks.Mark) as 'Average mark', Serials.Path as 'Path'
--	FROM Serials JOIN Series ON Serials.Id = Series.Id_Serial	
--				 JOIN Status ON Serials.id_Status = Status.Id
--				 JOIN TVChannels ON Serials.Id_TVChannel = TVChannels.Id
--				 LEFT JOIN Marks ON Marks.Id_Serial = Serials.Id
--	GROUP BY Serials.Id,Serials.Name,Status,TVChannels.Name,Mark,Serials.Description,Serials.Pa
	
	SELECT Serials.Id as 'Id', Serials.Name as 'Name', Serials.Description as 'Description', TVChannels.Name as 'TVChannel', MIN(YEAR(Date)) as 'Year', MAX(Season) as 'Seasons', Status as 'Status',(select avg(Mark) from Marks m where Serials.Id = m.Id_Serial)as 'Average mark', Serials.Path as 'Path'
	FROM Serials JOIN Series ON Serials.Id = Series.Id_Serial	
				 JOIN Status ON Serials.id_Status = Status.Id
				 JOIN TVChannels ON Serials.Id_TVChannel = TVChannels.Id
				 --LEFT JOIN Marks ON Marks.Id_Serial = Serials.Id
	GROUP BY Serials.Id,Serials.Name,Status,TVChannels.Name,Serials.Description,Serials.Path


Go
ALTER PROCEDURE sp_serial_info
AS
	SELECT * FROM TEST

GRANT EXECUTE ON sp_serial_info TO UserDb

GO
ALTER PROCEDURE sp_my_serials @UserId int
AS
	SELECT Id as 'Id', Name as Name,Description,TVChannel,Year,Seasons, Status,[Average mark],Path, Marks.Mark 
	FROM TEST LEFT JOIN Marks ON Marks.Id_Serial = Id AND Marks.Id_User = @UserId
	WHERE Id IN
	(
		SELECT Id_Serial
		FROM WatchingSerials
		WHERE Id_User = @UserId
	)

GO
ALTER PROCEDURE sp_viewed_serials @UserId int
AS
	SELECT Id as 'Id', Name as Name,Description,TVChannel,Year,Seasons, Status,[Average mark],Path, Marks.Mark 
	FROM TEST LEFT JOIN Marks ON Marks.Id_Serial = Id AND Marks.Id_User = @UserId
	WHERE Id IN
	(
		SELECT Id_Serial
		FROM ViewedSerials
		WHERE Id_User = @UserId
	)

GO
ALTER PROCEDURE sp_my_series @UserId int
AS
	SELECT Serials.Name as 'SerialName',Series.Name as 'SeriesName', Date, Duration, Season,Series.Id,Number
	FROM Series JOIN Serials ON Series.Id_Serial = Serials.Id
				JOIN WatchingSerials ON WatchingSerials.Id_User = @UserId AND WatchingSerials.Id_Serial = Series.Id_Serial
				WHERE Series.Date > GETDATE()
	ORDER BY Season desc ,Number asc


GO
ALTER PROCEDURE sp_check_viewded @UserId int, @SerialId int
AS
declare @status bit
if exists(select ViewedSerials.Id_User from ViewedSerials where ViewedSerials.Id_User = @UserId AND ViewedSerials.Id_Serial =  @SerialId)
SET @status = 1;
ELSE
SET @status = 0;
SELECT @status

GO
ALTER PROCEDURE sp_check_watchinig @UserId int, @SerialId int
AS
declare @status bit
if exists(select WatchingSerials.Id_User from WatchingSerials where WatchingSerials.Id_User = @UserId AND WatchingSerials.Id_Serial =  @SerialId)
SET @status = 1;
ELSE
SET @status = 0;
SELECT @status


GRANT EXECUTE ON sp_check_watchinig TO UserDB
GRANT EXECUTE ON sp_check_viewded TO UserDB

GO
ALTER PROCEDURE sp_add_watchingserial @UserId int, @SerialId int
AS
	INSERT INTO WatchingSerials
	VALUES (@SerialId,@UserId)

GO
ALTER PROCEDURE sp_add_viewedserial @UserId int, @SerialId int
AS
	INSERT INTO ViewedSerials
	VALUES (@SerialId,@UserId)
GO
CREATE PROCEDURE sp_remove_viewed_serial @UserId int, @SerialId int
AS
	DELETE FROM ViewedSerials WHERE Id_User = @UserId AND Id_Serial = @SerialId;

	GO
CREATE PROCEDURE sp_remove_watching_serial @UserId int, @SerialId int
AS
	DELETE FROM WatchingSerials WHERE Id_User = @UserId AND Id_Serial = @SerialId;


GRANT EXECUTE ON sp_remove_viewed_serial TO UserDB
GRANT EXECUTE ON sp_remove_watching_serial TO UserDB

GO
ALTER PROCEDURE sp_add_mark  @UserId int, @SerialId int, @Mark int 
AS
    if exists(select Marks.Mark from Marks WHERE Marks.Id_Serial = @SerialId AND Marks.Id_User = @UserId)
	BEGIN
	UPDATE Marks
	SET Mark = @Mark
	WHERE Marks.Id_Serial = @SerialId AND Marks.Id_User = @UserId
	END
	ELSE
	BEGIN
	INSERT INTO Marks
	VALUES (@SerialId,@UserId,@Mark)
	END
	

Go
CREATE PROCEDURE sp_get_serial_rating @SerialId int
AS 
	SELECT avg(Marks.Mark) as 'Average mark' FROM Marks WHERE Marks.Id_Serial = @SerialId

GRANT EXECUTE ON sp_get_serial_rating TO UserDB

GO 
CREATE PROCEDURE sp_get_serial @SerialId int
AS
SELECT * FROM TEST WHERE Id = @SerialId

GRANT EXECUTE ON sp_get_serial TO UserDB

GO
CREATE PROCEDURE sp_check_user_name @UserName nvarchar(50) 
AS
	declare @status bit
    if exists(Select Users.Name FROM Users WHERE Users.Name =@UserName)
    SET @status = 1
	ELSE
	SET @status = 0
	SELECT @status

GRANT EXECUTE ON sp_check_user_name TO UserDB

GO
CREATE PROCEDURE sp_check_user_mail @UserMail nvarchar(50) 
AS
	declare @status bit
    if exists(Select Users.Email FROM Users WHERE Users.Email =@UserMail)
	SET @status = 1
	ELSE
	SET @status = 0
	SELECT @status



GRANT EXECUTE ON sp_check_user_mail TO UserDB
GRANT EXECUTE ON sp_add_like TO UserDB
GRANT SELECT ON Users TO UserDB



GO 
CREATE PROCEDURE sp_check_content_role @username nvarchar(50) 
AS
	declare @status bit
	IF IS_ROLEMEMBER ('ContentManager') = 1
		SET @status = 1    
	ELSE IF IS_ROLEMEMBER ('ContentManager') = 0  
	    SET @status = 0
		SELECT @status

GRANT EXECUTE ON sp_check_content_role TO ContentManager

GO 
CREATE PROCEDURE sp_check_user_role @username nvarchar(50) 
AS
	declare @status bit
	IF IS_ROLEMEMBER ('UserDB') = 1
		SET @status = 1    
	ELSE IF IS_ROLEMEMBER ('UserDB') = 0  
	    SET @status = 0
		SELECT @status

GRANT EXECUTE ON sp_check_user_role TO UserDB
GRANT EXECUTE ON sp_check_user_role TO ContentManager
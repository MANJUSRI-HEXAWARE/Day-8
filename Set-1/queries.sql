CREATE DATABASE BankDB;
GO
USE BankDB;
GO
--table creation
CREATE TABLE Accounts
(
    AccountID INT PRIMARY KEY,
    AccountHolder VARCHAR(50),
    Balance DECIMAL(10,2),
    AccountStatus VARCHAR(20)
);
--insert
INSERT INTO Accounts
VALUES
(101, 'Arun', 50000, 'ACTIVE'),
(102, 'Priya', 30000, 'ACTIVE'),
(103, 'Kumar', 10000, 'INACTIVE');

SELECT * FROM Accounts;

--Task 1: Funds transfer using transactions
DECLARE @FromAccount INT = 101;
DECLARE @ToAccount INT = 102;
DECLARE @Amount DECIMAL(10,2) = 5000;

DECLARE @Balance DECIMAL(10,2);
DECLARE @Status VARCHAR(20);

BEGIN TRY

    BEGIN TRAN;

    -- Check sender account
    SELECT
        @Balance = Balance,
        @Status = AccountStatus
    FROM Accounts
    WHERE AccountID = @FromAccount;
    IF @Balance IS NULL
        THROW 50001, 'Sender account not found', 1;
    IF @Status <> 'ACTIVE'
        THROW 50002, 'Sender account is inactive', 1;
    IF @Balance < @Amount
        THROW 50003, 'Insufficient balance', 1;
    -- Check receiver account
    SELECT @Status = AccountStatus
    FROM Accounts
    WHERE AccountID = @ToAccount;
    IF @Status IS NULL
        THROW 50004, 'Receiver account not found', 1;
    IF @Status <> 'ACTIVE'
        THROW 50005, 'Receiver account is inactive', 1;

    -- Debit sender
    UPDATE Accounts
    SET Balance = Balance - @Amount
    WHERE AccountID = @FromAccount;

    -- Credit receiver
    UPDATE Accounts
    SET Balance = Balance + @Amount
    WHERE AccountID = @ToAccount;
    COMMIT TRAN;
    PRINT 'Money transferred successfully';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;
    PRINT ERROR_MESSAGE();
END CATCH;

--Task 2 – Demonstrate failure and ROLLBACK
BEGIN TRY

    BEGIN TRAN;
    -- Debit Arun
    UPDATE Accounts
    SET Balance = Balance - 2000
    WHERE AccountID = 101;
    PRINT 'Amount debited successfully';
    -- Generate a deliberate error
    THROW 50001, 'Transfer failed deliberately', 1;
    -- Credit Priya (will not execute)
    UPDATE Accounts
    SET Balance = Balance + 2000
    WHERE AccountID = 102;
    COMMIT TRAN;
END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;

    PRINT 'Error: ' + ERROR_MESSAGE();
    PRINT 'Transaction rolled back successfully';

END CATCH;
-- Check balances after rollback
SELECT * FROM Accounts
WHERE AccountID IN (101, 102);

--Task 3 – Using SAVE TRANSACTION
--fee table creation
CREATE TABLE AccountFees
(
    FeeID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT,
    FeeAmount DECIMAL(10,2)
);
--query
BEGIN TRY
    BEGIN TRAN;
    -- Debit Arun
    UPDATE Accounts
    SET Balance = Balance - 3000
    WHERE AccountID = 101
      AND AccountStatus = 'ACTIVE'
      AND Balance >= 3000;
    IF @@ROWCOUNT = 0
        THROW 50001, 'Insufficient balance or inactive sender', 1;
    -- Credit Priya
    UPDATE Accounts
    SET Balance = Balance + 3000
    WHERE AccountID = 102
      AND AccountStatus = 'ACTIVE';
    IF @@ROWCOUNT = 0
        THROW 50002, 'Receiver account unavailable', 1;
    PRINT 'Money transferred successfully';
    -- Create savepoint before fee posting
    SAVE TRANSACTION FeeSavepoint;
    BEGIN TRY
        -- Attempt fee posting
        INSERT INTO AccountFees
        VALUES (101, 50);

        -- Generate deliberate error
        THROW 50003, 'Fee posting failed deliberately', 1;

    END TRY

    BEGIN CATCH
        -- Roll back only fee posting
        IF XACT_STATE() = 1
        BEGIN
            ROLLBACK TRANSACTION FeeSavepoint;
            PRINT 'Fee posting rolled back';
        END
        ELSE
        BEGIN
            THROW;
        END
    END CATCH;
    -- Commit the successful transfer
    COMMIT TRAN;
    PRINT 'Transfer committed successfully';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;
    PRINT ERROR_MESSAGE();
END CATCH;

--Task 4 – Monthly Statement using CTE, ROW_NUMBER() and LAG()
--sample transaction records
INSERT INTO AccountTransactions
    (AccountID, TransactionType, Amount, BalanceAfter, TransactionDate)
VALUES
    (101, 'CREDIT', 10000, 55000, '2026-11-01'),
    (101, 'DEBIT', 5000, 50000, '2026-11-05'),
    (101, 'DEBIT', 3000, 47000, '2026-11-10'),
    (101, 'CREDIT', 2000, 49000, '2026-11-15'),
    (101, 'DEBIT', 7000, 42000, '2026-11-19');

DECLARE @AccountID INT = 101;

WITH MonthlyStatement AS
(
    SELECT
        AccountID,
        TransactionType,
        Amount,
        BalanceAfter,
        TransactionDate,

        ROW_NUMBER() OVER
        (
            ORDER BY TransactionDate
        ) AS TransactionNumber,

        LAG(BalanceAfter) OVER
        (
            ORDER BY TransactionDate
        ) AS PreviousBalance

    FROM AccountTransactions
    WHERE AccountID = @AccountID
)

SELECT *
FROM MonthlyStatement
WHERE MONTH(TransactionDate) = 11
  AND YEAR(TransactionDate) = 2026
ORDER BY TransactionDate;

--Task 5 – Isolation Levels
--READ COMMITTED isolation

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
SELECT Balance
FROM Accounts
WHERE AccountID = 101;
WAITFOR DELAY '00:00:15';
SELECT Balance
FROM Accounts
WHERE AccountID = 101;
COMMIT TRANSACTION;
--While Session A is waiting, execute this in Session B

UPDATE Accounts
SET Balance = Balance + 1000
WHERE AccountID = 101;

--SNAPSHOT isolation
ALTER DATABASE BankDB
SET ALLOW_SNAPSHOT_ISOLATION ON;
GO


SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
SELECT Balance
FROM Accounts
WHERE AccountID = 101;
WAITFOR DELAY '00:00:15';
SELECT Balance
FROM Accounts
WHERE AccountID = 101;
COMMIT TRANSACTION;

--While Session A is waiting, execute this in Session B
UPDATE Accounts
SET Balance = Balance + 2000
WHERE AccountID = 101;

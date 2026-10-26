# Module catalog

The database has 74 code modules: 59 stored procedures, 8 views, 3 scalar functions, 1 inline table-valued function, 2 multi-statement table-valued functions, 1 trigger. Each module has a source file whose header states what it does, what it shows and which tables it reads. The sections below follow the families of those headers. The examples run as written on the delivered database, except where the entry says none. The examples of the modules that write data change the database: run them on a copy.

## Business modules

Procedures, views and one intelligent query processing demonstration that behave like the application code of a training company: enroll a trainee, issue invoices, record a payment, schedule a session. (11 modules)

### Contact.UpdateContactDetails

Updates the email and phone supplied for a contact, and leaves untouched those that are NULL; refuses an email outside the domain of the contact's company, or already taken by another contact.

- Type: stored procedure
- Shows: partial update (ISNULL on each parameter), consistency check before writing, going through the trigger Contact.atr_Contact_CheckEmail (which checks the shape of the email and rolls back if it is wrong)
- Tables: Contact.Contact, Contact.Company
- Writes data: yes
- Minimum version: SQL Server 2016

```sql
DECLARE @c int = (SELECT TOP (1) c.ContactId FROM Contact.Contact c JOIN Contact.Company co ON co.CompanyId = c.CompanyId WHERE c.Email IS NOT NULL AND c.ContactId > 1000 ORDER BY c.ContactId), @mail varchar(150), @phone varchar(15); SELECT @mail = LOWER(c.FirstName + '.' + c.LastName + '.new') + '@' + co.EmailDomain FROM Contact.Contact c JOIN Contact.Company co ON co.CompanyId = c.CompanyId WHERE c.ContactId = @c; SET @phone = '01 99 99 99 99'; EXEC Contact.UpdateContactDetails @ContactId = @c, @Email = @mail, @Phone = @phone;
```

### Course.ScheduleSession

Creates an open-enrollment session of a course if the room and the trainer are free, on weekdays, outside holidays and outside the Christmas period; the price is that of the last session of the course.

- Type: stored procedure
- Shows: overlap search written to be seekable by index: StartDate is bounded by a fixed window (a session lasts at most 5 days), on the index uq_Session_StartDateRoom, then the exact test is applied to the rows of that window; range locks (HOLDLOCK) so that two calls do not take the same room
- Tables: Course.Session, Course.Course, Course.CourseLanguage, Trainer.Trainer, Trainer.TrainerDomain, Trainer.TrainerLanguage, Reference.TrainingRoom, Reference.TrainingLocation, Reference.Holiday, Tools.CalendarDay
- Writes data: yes
- Minimum version: SQL Server 2016

```sql
DECLARE @st int = (SELECT TOP (1) st.CourseId FROM Course.Course st WHERE st.CategoryCode <> 'CU' AND st.CancellationDate IS NULL AND EXISTS (SELECT 1 FROM Course.CourseLanguage l WHERE l.CourseId = st.CourseId AND l.LanguageCode = 'FR') AND EXISTS (SELECT 1 FROM Course.Session s WHERE s.CourseId = st.CourseId AND s.LanguageCode = 'FR') ORDER BY st.CourseId), @sa int = (SELECT TOP (1) sa.TrainingRoomId FROM Reference.TrainingRoom sa JOIN Reference.TrainingLocation l ON l.TrainingLocationId = sa.TrainingLocationId WHERE l.IsPachaCenter = 1 AND l.Address1 IS NOT NULL AND l.ClosingDate IS NULL ORDER BY sa.TrainingRoomId), @fo int, @sid int; SET @fo = (SELECT TOP (1) f.TrainerId FROM Trainer.Trainer f JOIN Course.Course st ON st.CourseId = @st WHERE f.DepartureDate IS NULL AND f.ArrivalDate <= '20280306' AND EXISTS (SELECT 1 FROM Trainer.TrainerDomain d WHERE d.TrainerId = f.TrainerId AND d.DomainCode = st.DomainCode) AND EXISTS (SELECT 1 FROM Trainer.TrainerLanguage l WHERE l.TrainerId = f.TrainerId AND l.LanguageCode = 'FR') ORDER BY f.TrainerId); EXEC Course.ScheduleSession @CourseId = @st, @LanguageCode = 'FR', @TrainingRoomId = @sa, @StartDate = '20280306', @TrainerId = @fo, @SessionId = @sid OUTPUT; SELECT @sid AS SessionId;
```

### Elearning.vAccessWindow

Gives, for each active enrollment of a session starting on or after March 1, 2018, the window in which its e-learning activity is allowed: AccessStart and AccessEnd.

- Type: view
- Shows: a CROSS APPLY that finds the last day of the session as the Duration-th business day of the country of the location (weekdays, holidays excluded), and bounds on both sides by fixed dates
- Tables: Enrollment.Enrollment, Course.Session, Reference.TrainingRoom, Reference.TrainingLocation, Tools.CalendarDay, Reference.Holiday
- Writes data: no
- Minimum version: SQL Server 2016

```sql
SELECT TOP (10) * FROM Elearning.vAccessWindow ORDER BY EnrollmentId;
```

### Enrollment.CancelEnrollment

Cancels an enrollment and promotes the first person on the waiting list to its place.

- Type: stored procedure
- Shows: two linked writes in the same transaction (the cancellation and the promotion), under a lock on the session
- Tables: Enrollment.Enrollment, Course.Session, Contact.Contact, Contact.Company
- Writes data: yes
- Minimum version: SQL Server 2016

```sql
DECLARE @i int = (SELECT TOP (1) i.EnrollmentId FROM Enrollment.Enrollment i JOIN Course.Session s ON s.SessionId = i.SessionId JOIN Contact.Contact c ON c.ContactId = i.ContactId LEFT JOIN Contact.Company co ON co.CompanyId = c.CompanyId WHERE s.StatusCode = 'CONFIRMED' AND s.StartDate > '20261018' AND i.CancellationDate IS NULL AND i.WaitingList = 0 AND ISNULL(co.InvoiceBeforeEnrollment, 0) = 0 AND NOT EXISTS (SELECT 1 FROM Elearning.Activity ea WHERE ea.EnrollmentId = i.EnrollmentId) AND EXISTS (SELECT 1 FROM Enrollment.Enrollment a JOIN Contact.Contact ca ON ca.ContactId = a.ContactId LEFT JOIN Contact.Company ca2 ON ca2.CompanyId = ca.CompanyId WHERE a.SessionId = i.SessionId AND a.WaitingList = 1 AND a.CancellationDate IS NULL AND ISNULL(ca2.InvoiceBeforeEnrollment, 0) = 0) ORDER BY s.StartDate, i.EnrollmentId); EXEC Enrollment.CancelEnrollment @EnrollmentId = @i;
```

### Enrollment.EnrollTrainee

Enrolls a contact in a session, or puts the contact on the waiting list when the session is full (capacity: the smaller of Course.MaxAttendees and the seats of the room).

- Type: stored procedure
- Shows: short transaction, UPDLOCK and HOLDLOCK on the session row to prevent overbooking, TRY/CATCH and THROW
- Tables: Course.Session, Course.Course, Reference.TrainingRoom, Enrollment.Enrollment, Contact.Contact, Contact.Company
- Writes data: yes
- Minimum version: SQL Server 2016

```sql
DECLARE @free int = (SELECT TOP (1) s.SessionId FROM Course.Session s JOIN Course.Course st ON st.CourseId = s.CourseId JOIN Reference.TrainingRoom sa ON sa.TrainingRoomId = s.TrainingRoomId WHERE s.StatusCode = 'OPEN' AND s.IsInHouse = 0 AND s.StartDate > '20261018' AND (SELECT COUNT(*) FROM Enrollment.Enrollment i WHERE i.SessionId = s.SessionId AND i.CancellationDate IS NULL AND i.WaitingList = 0) < CASE WHEN st.MaxAttendees < sa.Seats THEN st.MaxAttendees ELSE sa.Seats END ORDER BY s.SessionId), @full int = (SELECT TOP (1) s.SessionId FROM Course.Session s JOIN Course.Course st ON st.CourseId = s.CourseId JOIN Reference.TrainingRoom sa ON sa.TrainingRoomId = s.TrainingRoomId WHERE s.StatusCode = 'CONFIRMED' AND s.IsInHouse = 0 AND s.StartDate > '20261018' AND (SELECT COUNT(*) FROM Enrollment.Enrollment i WHERE i.SessionId = s.SessionId AND i.CancellationDate IS NULL AND i.WaitingList = 0) >= CASE WHEN st.MaxAttendees < sa.Seats THEN st.MaxAttendees ELSE sa.Seats END ORDER BY s.SessionId DESC), @c1 int = (SELECT TOP (1) c.ContactId FROM Contact.Contact c LEFT JOIN Contact.Company co ON co.CompanyId = c.CompanyId WHERE c.BirthDate BETWEEN '19700101' AND '19901231' AND ISNULL(co.InvoiceBeforeEnrollment, 0) = 0 AND NOT EXISTS (SELECT 1 FROM Enrollment.Enrollment i WHERE i.ContactId = c.ContactId) ORDER BY c.ContactId), @c2 int = (SELECT TOP (1) c.ContactId FROM Contact.Contact c LEFT JOIN Contact.Company co ON co.CompanyId = c.CompanyId WHERE c.BirthDate BETWEEN '19700101' AND '19901231' AND ISNULL(co.InvoiceBeforeEnrollment, 0) = 0 AND NOT EXISTS (SELECT 1 FROM Enrollment.Enrollment i WHERE i.ContactId = c.ContactId) ORDER BY c.ContactId DESC); EXEC Enrollment.EnrollTrainee @SessionId = @free, @ContactId = @c1; EXEC Enrollment.EnrollTrainee @SessionId = @full, @ContactId = @c2;
```

### Enrollment.IssueInvoices

Issues, for a completed session, one invoice and its lines per company (or per individual) for the attendees to be invoiced who are not yet; one invoice per session for an in-house session.

- Type: stored procedure
- Shows: set-based processing (one query per table, no cursor), OUTPUT ... INTO to link the invoices created to their enrollments and to their lines, continuous numbering under a range lock
- Tables: Enrollment.Invoice, Enrollment.InvoiceLine, Enrollment.EnrollmentInvoice, Enrollment.Enrollment, Course.Session, Contact.Contact, Contact.Company, Reference.VatRate, Reference.TrainingRoom, Reference.TrainingLocation
- Writes data: yes
- Minimum version: SQL Server 2016

```sql
DECLARE @s int = (SELECT TOP (1) s.SessionId FROM Course.Session s JOIN Trainer.Trainer f ON f.TrainerId = s.TrainerId WHERE s.StatusCode = 'CONFIRMED' AND s.IsInHouse = 0 AND s.StartDate > '20261018' AND f.Status = 'E' AND (SELECT COUNT(*) FROM Enrollment.Enrollment i JOIN Contact.Contact c ON c.ContactId = i.ContactId LEFT JOIN Contact.Company co ON co.CompanyId = c.CompanyId WHERE i.SessionId = s.SessionId AND i.WaitingList = 0 AND i.CancellationDate IS NULL AND ISNULL(co.InvoiceBeforeEnrollment, 0) = 0) >= 3 ORDER BY s.SessionId); UPDATE Course.Session SET StatusCode = 'COMPLETED' WHERE SessionId = @s; UPDATE Enrollment.Enrollment SET Attended = 1 WHERE SessionId = @s AND WaitingList = 0 AND CancellationDate IS NULL; EXEC Enrollment.IssueInvoices @SessionId = @s;
```

### Enrollment.RecordPayment

Records the payment of an invoice and refuses an overpayment, based on the balance given by Enrollment.vInvoiceBalance.

- Type: stored procedure
- Shows: consistency check before writing, under a lock on the invoice, and business error through THROW
- Tables: Enrollment.Payment, Enrollment.Invoice, Enrollment.vInvoiceBalance, Reference.PaymentMethod
- Writes data: yes
- Minimum version: SQL Server 2016

```sql
DECLARE @f varchar(50), @m decimal(9,2), @a decimal(9,2), @r decimal(9,2); SELECT TOP (1) @f = InvoiceCode, @m = Balance FROM Enrollment.vInvoiceBalance WHERE Status = 'UNPAID' AND Balance BETWEEN 100 AND 50000 ORDER BY InvoiceDate DESC, InvoiceCode; SET @a = ROUND(@m / 2, 2); SET @r = @m - @a; EXEC Enrollment.RecordPayment @InvoiceCode = @f, @Amount = @a, @PaymentMethodCode = 'WIRE', @PaymentDate = '20261018'; EXEC Enrollment.RecordPayment @InvoiceCode = @f, @Amount = @r, @PaymentMethodCode = 'WIRE', @PaymentDate = '20261018';
```

### Enrollment.vInvoiceBalance

Gives, for each invoice, its gross amount, the credit notes that reduce it, what has been paid, the balance and a derived status.

- Type: view
- Shows: a view that aggregates each linked table before the join, so that an invoice never has two rows (statuses PAID, PARTIAL, UNPAID, CANCELED, PENDING; the status is computed, it is not stored)
- Tables: Enrollment.Invoice, Enrollment.Payment
- Writes data: no
- Minimum version: SQL Server 2016
- Reference date: October 18, 2026, the date of the data. An unpaid invoice whose due date has not passed at that date is PENDING, otherwise UNPAID. Freezing the date keeps the view reproducible.
- Due date: the DueDate column is filled for all the invoices; failing that, 30 days after the invoice date.

```sql
SELECT Status, COUNT(*) AS Invoices, SUM(Balance) AS TotalBalance FROM Enrollment.vInvoiceBalance GROUP BY Status ORDER BY Status;
```

### iqp.AdaptiveJoins

Looks for the June invoices of the contacts named Simon, joining invoice, invoice-enrollment link, enrollment and contact; drops before, then recreates after, a filtered columnstore index on Enrollment.Invoice.

- Type: stored procedure
- Shows: the adaptive join, which chooses at run time between a nested loop and a hash join according to the number of rows actually read. The filtered columnstore index (on a date that nobody has, 2099-01-01) serves only to give the engine the possibility of batch mode on a rowstore table. Original version: the procedure also set the compatibility level of the database to 150; this one changes no database option, the level is that of the database.
- Tables: Enrollment.Invoice, Enrollment.EnrollmentInvoice, Enrollment.Enrollment, Contact.Contact
- Writes data: yes
- Minimum version: SQL Server 2017

Example: none (creates or replaces a filtered columnstore index on Enrollment.Invoice, a schema change that remains after the call)

### Marketing.CreateCampaign

Creates a letter (campaign of type Letter) and its deliveries, one per contact who has an email.

- Type: stored procedure
- Shows: large set-based insert (about 108,000 rows) in a transaction, identifier computed under a lock because Marketing.Campaign has no IDENTITY, OUTPUT parameter
- Tables: Marketing.Campaign, Marketing.Delivery, Contact.Contact
- Writes data: yes
- Minimum version: SQL Server 2016

```sql
DECLARE @c int; EXEC Marketing.CreateCampaign @Name = 'Test letter for the procedures', @SendDate = '20261102', @CampaignId = @c OUTPUT; SELECT @c AS CampaignId, (SELECT COUNT(*) FROM Marketing.Delivery WHERE CampaignId = @c) AS Deliveries;
```

### Marketing.RecordOpen

Marks a delivery as opened, and as clicked when @Clicked is 1 (a click implies an open).

- Type: stored procedure
- Shows: single update by primary key, idempotent (called again, it changes nothing), error if the key does not exist
- Tables: Marketing.Delivery
- Writes data: yes
- Minimum version: SQL Server 2016

```sql
DECLARE @e int = (SELECT MIN(DeliveryId) FROM Marketing.Delivery WHERE Opened = 0); EXEC Marketing.RecordOpen @DeliveryId = @e, @Clicked = 1;
```

## Writing patterns

Small procedures that each show one way of writing Transact-SQL: an upsert without MERGE, deletion by batches, JSON output, a table-valued parameter, a calendar computation, a searchable prefix search. (6 modules)

### Contact.GetContactsByList

Returns the contacts whose identifier is in the list received.

- Type: stored procedure
- Shows: table-valued parameter (dbo.ContactId, one int column ContactId), necessarily READONLY, joined like a table
- Tables: Contact.Contact, Contact.Company, dbo.ContactId (table type)
- Writes data: no
- Minimum version: SQL Server 2016

```sql
DECLARE @list dbo.ContactId; INSERT @list (ContactId) VALUES (1), (2), (3), (500), (12000); EXEC Contact.GetContactsByList @Ids = @list;
```

### Contact.SearchByName

Returns the contacts whose name starts with the text received, treating %, _ and [ as ordinary characters.

- Type: stored procedure
- Shows: seekable prefix search (LIKE @Prefix + '%', seek on nix_contact_lastname: 107 reads for 'Dupon', against 1,371 reads, a scan of the clustered index, without OPTION (RECOMPILE), measured on the French twin of this database, SQL Server 2022, 2026-10-26) and escaping of the wildcard characters
- Tables: Contact.Contact
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Contact.SearchByName @Prefix = 'Dupon';
```

### Course.CatalogJson

Returns, as a single JSON value, the catalog of the open-enrollment courses available in a language, each with its upcoming sessions (after October 18, 2026, the date of the data), canceled sessions excluded.

- Type: stored procedure
- Shows: FOR JSON PATH with a correlated subquery, which produces a nested JSON array; ROOT for the envelope; the result is put in a variable to come out in a single row, without being split into chunks of 2,033 characters
- Tables: Course.Course, Course.CourseLanguage, Course.Session, Reference.TrainingRoom, Reference.TrainingLocation
- Writes data: no
- Minimum version: SQL Server 2016
- Types: @LanguageCode follows Course.Language.LanguageCode (char(2)), checked on October 26, 2026.

```sql
EXEC Course.CatalogJson @LanguageCode = 'EN';
```

### Course.SaveTranslation

Creates or replaces the translation of a course in a language (title, subtitle, summary, prerequisites, audience profile, objectives); the fields not supplied are NULL in the saved row, it is a replacement and not a merge.

- Type: stored procedure
- Shows: "upsert" without MERGE: UPDATE under UPDLOCK and SERIALIZABLE, then INSERT if nothing was touched, in a transaction
- Tables: Course.CourseLanguage, Course.Course, Course.Language
- Writes data: yes
- Minimum version: SQL Server 2016

```sql
IF NOT EXISTS (SELECT 1 FROM Course.Language WHERE LanguageCode = 'ES') INSERT Course.Language (LanguageCode, LocalName, FrenchName) VALUES ('ES', 'Español', 'Espagnol'); DECLARE @s int = (SELECT TOP (1) st.CourseId FROM Course.Course st WHERE NOT EXISTS (SELECT 1 FROM Course.CourseLanguage l WHERE l.CourseId = st.CourseId AND l.LanguageCode = 'ES') ORDER BY st.CourseId); EXEC Course.SaveTranslation @CourseId = @s, @LanguageCode = 'ES', @Title = 'Essay title', @Subtitle = 'first version'; EXEC Course.SaveTranslation @CourseId = @s, @LanguageCode = 'ES', @Title = 'Essay title', @Subtitle = 'second version', @Objectives = 'Understand the essay';
```

### Marketing.PurgeDeliveries

Deletes the deliveries of a campaign in batches of @BatchSize rows and returns a summary; the campaign remains.

- Type: stored procedure
- Shows: batched delete (DELETE TOP), one transaction per batch, so that the log and the locks stay short
- Tables: Marketing.Delivery, Marketing.Campaign
- Writes data: yes
- Minimum version: SQL Server 2016

```sql
DECLARE @c int = (SELECT MAX(CampaignId) FROM Marketing.Campaign WHERE Name = 'Test letter for the procedures'); EXEC Marketing.PurgeDeliveries @CampaignId = @c, @BatchSize = 20000; (the example of Marketing.CreateCampaign, which comes earlier in alphabetical order, created this campaign)
```

### Reference.BusinessDays

Lists the business days of a country between two dates inclusive (neither Saturday, nor Sunday, nor a holiday of the country), numbered.

- Type: stored procedure
- Shows: calendar through Tools.CalendarDay and Reference.Holiday; weekday computed by the difference from a known Monday (January 1, 1900), which depends neither on SET DATEFIRST nor on the language; error rather than holidays counted as business days outside the covered range
- Tables: Tools.CalendarDay, Reference.Holiday
- Writes data: no
- Minimum version: SQL Server 2016
- Range: Reference.Holiday covers January 1, 2010 to December 31, 2028 (FRA, BEL, CHE, DEU, ITA). Beyond that, the procedure raises error 50191 instead of returning wrong business days.

```sql
EXEC Reference.BusinessDays @Start = '20260101', @End = '20260131', @CountryCode = 'FRA';
```

## Anti-patterns and their fixes

Schema Demo. Each slow version has a fixed version that returns the same result, so that the two can be compared with the execution plan and the I/O statistics. The Measure line, where present, gives the figures taken on the French twin of this database, PachadataFormation, which has the same data and the same indexes. Two pairs are marked as pairs without threshold: their subject is not speed. (16 modules)

### Demo.ActivityPage_Slow

Returns a page of learning activities, starting from an offset in rows.

- Type: stored procedure
- Shows: OFFSET @Offset ROWS: to reach the page, the engine reads and discards all the rows that precede it, so the deeper the page, the more it costs
- Tables: Elearning.Activity
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Demo.ActivityPage_Slow @Offset = 1000000, @PageSize = 50;
```

### Demo.ActivityPage_Fixed

Returns a page of learning activities, starting from the last key of the previous page, like Demo.ActivityPage_Slow.

- Type: stored procedure
- Shows: keyset pagination: the engine seeks ActivityId > @LastId in pk_Activity and reads only the page, whatever its depth. The identifiers of the delivered database are contiguous from 1 to 7,805,406: the page that follows offset N is the one that follows key N.
- Tables: Elearning.Activity
- Writes data: no
- Minimum version: SQL Server 2016
- Measure: slow 1,001,914 reads, 610 ms CPU, 611 ms; fixed 53 reads, 0 ms CPU, 0 ms (measured on the French twin of this database, SQL Server 2022, median of three warm-cache runs, 2026-10-25)

```sql
EXEC Demo.ActivityPage_Fixed @LastId = 1000000, @PageSize = 50;
```

### Demo.ContactsByName_Slow

Looks for the contacts who have a given name.

- Type: stored procedure
- Shows: an nvarchar parameter compared with a varchar column (Contact.Contact.LastName): the nvarchar type wins, the plan converts the column (CONVERT_IMPLICIT on LastName) and finds its seek range again only through GetRangeThroughConvert
- Tables: Contact.Contact
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Demo.ContactsByName_Slow @LastName = N'Jones';
```

### Demo.ContactsByName_Fixed

Looks for the contacts who have a given name, like Demo.ContactsByName_Slow.

- Type: stored procedure
- Shows: a parameter of the same type as the column (varchar(50)): the plan compares LastName with the parameter, without converting the column. Pair without threshold: under the Windows collation French_CI_AS of the database, the engine keeps a range seek even with the nvarchar parameter, so the reads are the same. The pair shows the conversion in the plan, not a gain. Under a SQL collation, the slow version scans the index.
- Tables: Contact.Contact
- Writes data: no
- Minimum version: SQL Server 2016
- Measure: slow 438 reads, 1 ms CPU, 0 ms; fixed 438 reads, 0 ms CPU, 0 ms (pair without threshold) (measured on the French twin of this database, SQL Server 2022, median of three warm-cache runs, 2026-10-25)

```sql
EXEC Demo.ContactsByName_Fixed @LastName = 'Jones';
```

### Demo.ContactsWithoutDelivery_Slow

Lists the contacts who received no mailing delivery.

- Type: stored procedure
- Shows: NOT IN on a subquery: a single NULL in the list empties the whole result, because x NOT IN (..., NULL) is never true
- Tables: Contact.Contact, Marketing.Delivery
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Demo.ContactsWithoutDelivery_Slow;
```

### Demo.ContactsWithoutDelivery_Fixed

Lists the contacts who received no mailing delivery, like Demo.ContactsWithoutDelivery_Slow.

- Type: stored procedure
- Shows: NOT EXISTS, which does not depend on NULLs. Pair without threshold: Marketing.Delivery.ContactId is NOT NULL, the engine knows it and compiles both writings into the same hash anti-join, which reads ix_Delivery_ContactId in full; on the delivered database, they return the same contacts. The difference is in the data: if the column allowed NULL, the slow version would return zero rows. Demonstration without touching the table: DECLARE @Delivery TABLE (ContactId int NULL); INSERT @Delivery VALUES (1), (NULL); SELECT COUNT(*) FROM (VALUES (1), (2), (3)) AS c(Id) WHERE c.Id NOT IN (SELECT ContactId FROM @Delivery);                  -- 0 rows SELECT COUNT(*) FROM (VALUES (1), (2), (3)) AS c(Id) WHERE NOT EXISTS (SELECT 1 FROM @Delivery AS e WHERE e.ContactId = c.Id); -- 2 rows
- Tables: Contact.Contact, Marketing.Delivery
- Writes data: no
- Minimum version: SQL Server 2016
- Measure: slow 6,825 reads, 572 ms CPU, 304 ms; fixed 6,825 reads, 576 ms CPU, 304 ms (pair without threshold) (measured on the French twin of this database, SQL Server 2022, median of three warm-cache runs, 2026-10-25)

```sql
EXEC Demo.ContactsWithoutDelivery_Fixed;
```

### Demo.FlagReminders_Slow

Adds one reminder (ReminderLevel, ReminderDate) to the invoices overdue at a date and without any payment recorded, at most one reminder per day and three in total.

- Type: stored procedure
- Shows: a WHILE loop that updates one invoice at a time: one statement, one key lookup and one log write per invoice, where a set-based update handles the batch
- Tables: Enrollment.Invoice, Enrollment.Payment
- Writes data: yes
- Minimum version: SQL Server 2016
- Criterion: an invoice 'I' due before @AsOfDate, without payment, already reminded fewer than three times and not reminded the same day. Credit notes are not taken into account: with the full balance (payments and credit notes), the batch of 1,020 invoices costs only predicate reads common to both versions and the pair shows no measurable difference.

```sql
EXEC Demo.FlagReminders_Slow @AsOfDate = '20261231';
```

### Demo.FlagReminders_Fixed

Adds one reminder (ReminderLevel, ReminderDate) to the invoices overdue at a date and without any payment recorded, at most one reminder per day and three in total, like Demo.FlagReminders_Slow.

- Type: stored procedure
- Shows: a set-based update in batches of 5,000 (UPDATE TOP): the criterion excludes the rows already flagged, so each batch moves on without tracking any state, and the loop stops at the first incomplete batch
- Tables: Enrollment.Invoice, Enrollment.Payment
- Writes data: yes
- Minimum version: SQL Server 2016
- Criterion: an invoice 'I' due before @AsOfDate, without payment, already reminded fewer than three times and not reminded the same day. Credit notes are not taken into account: with the full balance (payments and credit notes), the batch of 1,020 invoices costs only predicate reads common to both versions and the pair shows no measurable difference.
- Measure: slow 13,532 reads, 405 ms CPU, 20,601 ms; fixed 15,777 reads, 150 ms CPU, 184 ms (inside a rolled-back transaction; the gain is in CPU, not in reads) (measured on the French twin of this database, SQL Server 2022, median of three warm-cache runs, 2026-10-25)

```sql
EXEC Demo.FlagReminders_Fixed @AsOfDate = '20261231';
```

### Demo.LastDeliveryByContact_Slow

Gives, for each contact of a company, the date, the campaign and the open status of its last delivery.

- Type: stored procedure
- Shows: three scalar correlated subqueries, one per column: the last delivery is looked up three times per contact
- Tables: Contact.Contact, Marketing.Delivery
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Demo.LastDeliveryByContact_Slow @CompanyId = 36;
```

### Demo.LastDeliveryByContact_Fixed

Gives, for each contact of a company, the date, the campaign and the open status of its last delivery, like Demo.LastDeliveryByContact_Slow.

- Type: stored procedure
- Shows: an OUTER APPLY with TOP (1): the last delivery is looked up once per contact, through ix_Delivery_ContactId, and OUTER keeps the contacts without a delivery. The pair is limited to one company: over all the contacts, the plan scans Marketing.Delivery.
- Tables: Contact.Contact, Marketing.Delivery
- Writes data: no
- Minimum version: SQL Server 2016
- Measure: slow 25,667 reads, 38 ms CPU, 26 ms; fixed 9,515 reads, 25 ms CPU, 15 ms (measured on the French twin of this database, SQL Server 2022, median of three warm-cache runs, 2026-10-25)

```sql
EXEC Demo.LastDeliveryByContact_Fixed @CompanyId = 36;
```

### Demo.RevenueByCourse_Slow

Computes the net revenue and the number of billing documents per course (credit notes deducted).

- Type: stored procedure
- Shows: a cursor that accumulates row by row: one read and one assignment per document, 110,000 times, where an aggregation reads the table once
- Tables: Enrollment.Invoice, Course.Session
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Demo.RevenueByCourse_Slow;
```

### Demo.RevenueByCourse_Fixed

Computes the net revenue and the number of billing documents per course (credit notes deducted), like Demo.RevenueByCourse_Slow.

- Type: stored procedure
- Shows: a set-based query: a single GROUP BY replaces the cursor, and the engine chooses the aggregation algorithm
- Tables: Enrollment.Invoice, Course.Session
- Writes data: no
- Minimum version: SQL Server 2016
- Measure: slow 447,152 reads, 625 ms CPU, 626 ms; fixed 949 reads, 55 ms CPU, 54 ms (reads and times read from sys.dm_exec_requests: STATISTICS IO writes one message per cursor FETCH) (measured on the French twin of this database, SQL Server 2022, median of three warm-cache runs, 2026-10-25)

```sql
EXEC Demo.RevenueByCourse_Fixed;
```

### Demo.SearchSessions_Slow

Looks for sessions by course, language and start date, all optional.

- Type: stored procedure
- Shows: optional parameters written (Col = @p OR @p IS NULL): a single plan serves all the combinations, so none of them can seek in an index
- Tables: Course.Session
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Demo.SearchSessions_Slow @CourseId = 25, @LanguageCode = 'FR';
```

### Demo.SearchSessions_Fixed

Looks for sessions by course, language and start date, all optional, like Demo.SearchSessions_Slow.

- Type: stored procedure
- Shows: dynamic SQL parameterized through sp_executesql: only the filters supplied enter the query, each combination has its own plan, and the values remain parameters (no value concatenation, so no injection). With @CourseId and @LanguageCode, the engine seeks in nix_temp_02 (CourseId, LanguageCode).
- Tables: Course.Session
- Writes data: no
- Minimum version: SQL Server 2016
- Measure: slow 41 reads, 2 ms CPU, 2 ms; fixed 12 reads, 0 ms CPU, 0 ms (measured on the French twin of this database, SQL Server 2022, median of three warm-cache runs, 2026-10-25)

```sql
EXEC Demo.SearchSessions_Fixed @CourseId = 25, @LanguageCode = 'FR';
```

### Demo.SessionsByYear_Slow

Lists the sessions of a year.

- Type: stored procedure
- Shows: a function applied to the filter column (YEAR(StartDate)): the index on StartDate cannot serve a seek, it is read in full
- Tables: Course.Session
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Demo.SessionsByYear_Slow @Year = 2024;
```

### Demo.SessionsByYear_Fixed

Lists the sessions of a year, like Demo.SessionsByYear_Slow.

- Type: stored procedure
- Shows: a half-open interval on the column, without a function: the engine seeks in the index uq_Session_StartDateRoom (StartDate, TrainingRoomId) instead of reading it in full. The column list fits in this index (SessionId, key of the clustered index, appears in every nonclustered index): with one more column, both versions read the clustered index.
- Tables: Course.Session
- Writes data: no
- Minimum version: SQL Server 2016
- Measure: slow 32 reads, 3 ms CPU, 3 ms; fixed 5 reads, 1 ms CPU, 0 ms (measured on the French twin of this database, SQL Server 2022, median of three warm-cache runs, 2026-10-25)

```sql
EXEC Demo.SessionsByYear_Fixed @Year = 2024;
```

## Reports

Schema Report. Analytical queries wrapped in procedures: window functions, aggregates, batch mode. (9 modules)

### Report.ActivityByDevice

Events, distinct learners and duration per device (computer, mobile, tablet) and per week, over a period.

- Type: stored procedure
- Shows: an aggregation on Elearning.Activity, a rowstore table of 7.8 million rows; at compatibility level 150 and above, the engine can process it in batch mode without a columnstore index. The week is computed by a day difference from a known Monday (1900-01-01) and not by DATEPART(week), which depends on DATEFIRST.
- Tables: Elearning.Activity
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Report.ActivityByDevice @Start = '20260101', @End = '20260331';
```

### Report.CampaignPerformance

Open and click rates of the deliveries, per campaign type and per send month, for the campaigns whose send date falls in the period.

- Type: stored procedure
- Shows: a join between a small table (16,426 campaigns) and a large one (4 million deliveries) filtered by the small one, then an aggregation of bits converted to integers; the rates are computed on the deliveries, not on the campaigns
- Tables: Marketing.Campaign, Marketing.Delivery
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Report.CampaignPerformance @Start = '20260101', @End = '20260630';
```

### Report.ElearningEngagement

Engagement per online learning module: learners who open the module, who complete it, dropout, time spent on pages and videos, average score and pass rate on quizzes (threshold 70).

- Type: stored procedure
- Shows: an aggregation on Analytics.ActivityFact, the table with an ordered clustered columnstore index: the plan reads the row groups in batch mode, with conditional COUNT(DISTINCT) (COUNT(DISTINCT CASE ...)) to compute several measures in a single pass. A module that is opened and not completed counts as dropped.
- Tables: Analytics.ActivityFact, Elearning.Module
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Report.ElearningEngagement @CourseId = 169;
```

### Report.LapsedReaders

Contacts who stopped opening letters: those whose last open comes more than @Months months before the last letter they received, with the number of letters received since. Returns the first 100, the longest lapsed first.

- Type: stored procedure
- Shows: window functions on the deliveries of the letters, on two levels (ROW_NUMBER() OVER to number the letters of each contact and isolate the last one, MAX() OVER for the last open up to the current row); it is the analytic query of the DOP return (journal of October 19, 2026), of the order of ten seconds. The computation is relative to the last letter of each contact, not to today's date.
- Tables: Marketing.Delivery, Marketing.Campaign, Contact.Contact
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Report.LapsedReaders @Months = 6;
```

### Report.MonthlyRevenue

Net revenue per month and per invoice line type (credit notes deducted), with the calendar-year running total and the share of the month in the year, over the requested period.

- Type: stored procedure
- Shows: window functions on an aggregation: SUM() OVER (PARTITION BY year, type ORDER BY month ROWS UNBOUNDED PRECEDING) for the running total, SUM() OVER (PARTITION BY year, type) for the total of the year. The ROWS frame is written out: the default frame (RANGE) is more expensive. The running total and the share cover the months of the period, not the whole year.
- Tables: Enrollment.Invoice, Enrollment.InvoiceLine
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Report.MonthlyRevenue @Start = '20250101', @End = '20251231';
```

### Report.OverduePayments

Invoices overdue and not settled at a date, with the customer, the balance still due, the number of days overdue and the aging bucket (1 to 30 days, 31 to 60, 61 to 90, over 90), the oldest first.

- Type: stored procedure
- Shows: a procedure that relies on a view (Enrollment.vInvoiceBalance) instead of redoing the joins to the payments and the credit notes; the bucket is computed by CASE on the day difference. OPTION (HASH JOIN): the filter on the balance, a column computed by the view, is estimated at one row, and without the hint the engine chooses nested loops that reread Enrollment.Payment for each invoice (more than two minutes of CPU measured, against 0.7 s with the hint). Without a date, the procedure takes October 18, 2026, the date of the data (like the view), not today's date: the report stays reproducible.
- Tables: Enrollment.vInvoiceBalance, Contact.Company, Contact.Contact
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Report.OverduePayments;
```

### Report.RecipientsByCampaign

Recipients of a campaign: last name, first name, email, send date and open status of each delivery.

- Type: stored procedure
- Shows: (new in SQL Server 2022: the procedure compiles from 2016, but gets a dispatcher plan only at level 160) a skewed distribution of the CampaignId values (from 1 to 20 deliveries for an invitation, more than 100,000 for a letter): at compatibility level 160, the engine compiles a dispatcher plan (Dispatcher) and two variants, one per campaign size (parameter-sensitive plans). It relies on the statistics ix_Delivery_CampaignId, built on all the rows with the histogram of coeur-10-marketing.sql. The query is that of exercise 19 of the upgrade course.
- Tables: Marketing.Delivery, Contact.Contact
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Report.RecipientsByCampaign @CampaignId = 1001;
```

### Report.SessionFillRate

Fill rate of the sessions of a year, per training location and per month: confirmed enrollments (neither canceled nor on the waiting list) relative to the seats of the rooms.

- Type: stored procedure
- Shows: two nested aggregations (enrolled per session, then seats and enrolled per location and month) so as not to multiply the seats by the number of enrolled; canceled sessions and those without a room are excluded
- Tables: Course.Session, Enrollment.Enrollment, Reference.TrainingRoom, Reference.TrainingLocation
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Report.SessionFillRate @Year = 2025;
```

### Report.TrainerRanking

Ranking of the trainers of a year: days taught, revenue invoiced by the trainer (days at the daily rate, plus travel expenses), average rating of the evaluations of their sessions, rank by revenue and rank by rating.

- Type: stored procedure
- Shows: RANK() on two criteria in the same query, and an average rating computed on the numeric answers (Rating not NULL) without multiplying the days or the revenue by the number of answers: each measure is aggregated separately before the join
- Tables: Trainer.Engagement, Trainer.Trainer, Contact.Contact, Course.Session, Enrollment.Enrollment, Enrollment.Evaluation, Enrollment.Answer
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Report.TrainerRanking @Year = 2025;
```

## Book fixtures

Objects that Pachadata books, articles and courses refer to by name. They are kept under their original role so that the examples of those texts run unchanged. (32 modules)

### Contact.atr_Contact_CheckEmail

After an update of Contact.Contact, rolls the transaction back with error 50000 (severity 16) if the email of the row read in inserted does not have the shape x@y.z.

- Type: trigger
- Shows: an AFTER UPDATE trigger that reads a single row of inserted and rolls back the caller's transaction (ROLLBACK inside the trigger)
- Tables: Contact.Contact
- Writes data: no
- Minimum version: SQL Server 2016

Example: none (a trigger: it fires on an UPDATE of Contact.Contact, which Contact.UpdateContactDetails exercises)

### Contact.CheckProspects

Flags in Contact.ProspectUS (column IsContact) the prospects who are already contacts (same last name, first name, zip code and city); with @clean = 1, first resets the flag; adds the column if it is missing.

- Type: stored procedure
- Shows: a DYNAMIC cursor over about a million prospects with UPDATE ... WHERE CURRENT OF, and a lookup in Contact.Contact for each row
- Tables: Contact.ProspectUS, Contact.Contact, Contact.Address, Reference.City
- Writes data: yes
- Minimum version: SQL Server 2016

Example: none (a cursor over the 1,000,000 prospects, with one lookup per row: it runs for a long time and rewrites IsContact)

### Contact.ContactShort

Exposes four columns of Contact.Contact (identifier, last name, first name, email).

- Type: view
- Shows: a simple projection view, used by Contact.GetContactAndEnrollmentCountById
- Tables: Contact.Contact
- Writes data: no
- Minimum version: SQL Server 2016

```sql
SELECT TOP (10) * FROM Contact.ContactShort;
```

### Contact.GetContactAndEnrollmentCountById

Counts the enrollments of a contact given by its identifier.

- Type: stored procedure
- Shows: a query through a view (Contact.ContactShort) joined to a table, filtered on the key
- Tables: Contact.ContactShort, Enrollment.Enrollment
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Contact.GetContactAndEnrollmentCountById @ContactId = 20;
```

### Contact.GetContactAndEnrollmentCountByName_OptimizeForSimon

Counts the enrollments of the contacts who have a given last name.

- Type: stored procedure
- Shows: OPTIMIZE FOR (@LastName = 'Simon'): the plan is built for a value of the parameter chosen in advance, whatever the value received
- Tables: Contact.Contact, Enrollment.Enrollment
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Contact.GetContactAndEnrollmentCountByName_OptimizeForSimon @LastName = 'Martin';
```

### Contact.GetContactByName

Returns the name, email, phone and fax of the contacts who have a given last name.

- Type: stored procedure
- Shows: a query filtered on the LastName column by a parameter, in its simplest form (nvarchar parameter)
- Tables: Contact.Contact
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Contact.GetContactByName @LastName = N'Simon';
```

### Contact.GetContactByName_DensityVector

Returns all the columns of the contacts who have a given last name.

- Type: stored procedure
- Shows: the parameter copied into a local variable before the query, with WITH RECOMPILE on the procedure: the estimate comes from the density vector and not from the histogram
- Tables: Contact.Contact
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Contact.GetContactByName_DensityVector @LastName = 'Simon';
```

### Contact.GetContactByName_WithRecompile

Returns all the columns of the contacts who have a given last name.

- Type: stored procedure
- Shows: WITH RECOMPILE on the procedure: a new plan at each call, built for the value received
- Tables: Contact.Contact
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Contact.GetContactByName_WithRecompile @LastName = 'Simon';
```

### Contact.GetEnrollmentCount

Returns the number of enrollments of a contact.

- Type: scalar function
- Shows: a scalar function that reads a table, called once per row by diagnostic.udf_scalar
- Tables: Enrollment.Enrollment
- Writes data: no
- Minimum version: SQL Server 2016

```sql
SELECT Contact.GetEnrollmentCount(20) AS EnrollmentCount;
```

### Contact.GetEnrollmentCountTableInline

Returns, as a table, the number of enrollments of a contact.

- Type: inline table-valued function
- Shows: an inline table-valued function, expanded into the calling query (compare with the multi-statement version)
- Tables: Enrollment.Enrollment
- Writes data: no
- Minimum version: SQL Server 2016

```sql
SELECT * FROM Contact.GetEnrollmentCountTableInline(20);
```

### Contact.GetEnrollmentCountTableMulti

Returns, as a table, the number of enrollments of a contact.

- Type: multi-statement table-valued function
- Shows: a multi-statement table-valued function (table variable filled then returned), opaque to the optimizer
- Tables: Enrollment.Enrollment
- Writes data: no
- Minimum version: SQL Server 2016

```sql
SELECT * FROM Contact.GetEnrollmentCountTableMulti(20);
```

### Contact.GetSessionsByContacts

For each contact of a list, concatenates in one string the start date and the status of the sessions in which the contact is enrolled.

- Type: stored procedure
- Shows: table-valued parameter (dbo.ContactId) and string aggregation with STUFF and FOR XML PATH
- Tables: Contact.Contact, Enrollment.Enrollment, Course.Session, dbo.ContactId (table type)
- Writes data: no
- Minimum version: SQL Server 2017

```sql
DECLARE @ids dbo.ContactId; INSERT @ids (ContactId) VALUES (20), (56); EXEC Contact.GetSessionsByContacts @ContactIds = @ids;
```

### Contact.ProspectsByParameter

Returns the name of the prospects whose zip code matches the parameter.

- Type: stored procedure
- Shows: the parameter used directly in the predicate (LIKE @zip): the plan is built for the value received at the first call (parameter sniffing)
- Tables: Contact.ProspectUS
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Contact.ProspectsByParameter @zip = '97355';
```

### Contact.ProspectsByZipCode

Returns the name, zip code and city of the prospects whose zip code matches the parameter.

- Type: stored procedure
- Shows: a LIKE on the zip code, supported by the index nix_prospectus_zipcode
- Tables: Contact.ProspectUS
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Contact.ProspectsByZipCode @zip = '97355';
```

### Contact.ProspectsLocalVariable

Returns the name of the prospects whose zip code matches the parameter.

- Type: stored procedure
- Shows: the parameter copied into a local variable before the query: the optimizer does not see its value and uses the density vector
- Tables: Contact.ProspectUS
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Contact.ProspectsLocalVariable @zip = '97355';
```

### Contact.SearchProspect

Returns the prospects for a zip code and a city, both optional.

- Type: stored procedure
- Shows: the pattern with optional parameters (Col = @p OR @p IS NULL), where a single plan serves every combination
- Tables: Contact.ProspectUS
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Contact.SearchProspect @ZipCode = '97355';
```

### dbo.ContactsByName

Counts the enrollments per last name of contact.

- Type: view
- Shows: a view that aggregates a left join (contacts and their enrollments)
- Tables: Contact.Contact, Enrollment.Enrollment
- Writes data: no
- Minimum version: SQL Server 2016

```sql
SELECT TOP (10) * FROM dbo.ContactsByName;
```

### dbo.fnDateTable

Returns a table of dates from @StartDate to @EndDate, one per day, month, year or hour according to @DayPart.

- Type: multi-statement table-valued function
- Shows: a multi-statement table-valued function that fills its table variable in a WHILE loop
- Tables: none
- Writes data: no
- Minimum version: SQL Server 2016

```sql
SELECT * FROM dbo.fnDateTable('20260101', '20260105', 'day');
```

### dbo.GetEnrollmentCount

Returns the number of enrollments of a contact.

- Type: scalar function
- Shows: a scalar function in the dbo schema, a copy of Contact.GetEnrollmentCount with a different return type (int)
- Tables: Enrollment.Enrollment
- Writes data: no
- Minimum version: SQL Server 2016

```sql
SELECT dbo.GetEnrollmentCount(20) AS EnrollmentCount;
```

### dbo.InvoiceAll

Exposes the current invoices and the archived invoices as a single set.

- Type: view
- Shows: a partitioned view (UNION ALL of two tables with the same columns)
- Tables: Enrollment.Invoice, Enrollment.InvoiceHistory
- Writes data: no
- Minimum version: SQL Server 2016

```sql
SELECT TOP (10) * FROM dbo.InvoiceAll;
```

### dbo.ProcedurePlans

Lists, for each statement of the cached procedures, the execution counts, the text of the statement, the plan and the query hashes, ordered by procedure and statement offset.

- Type: stored procedure
- Shows: the plan cache DMVs (sys.dm_exec_procedure_stats, sys.dm_exec_query_stats, sys.dm_exec_query_plan, sys.dm_exec_sql_text) joined on plan_handle
- Tables: sys.dm_exec_procedure_stats, sys.dm_exec_query_stats, sys.dm_exec_query_plan, sys.dm_exec_sql_text
- Writes data: no
- Minimum version: SQL Server 2016

Example: none (reads the plan cache: it returns rows only once procedures of the database have run since the last restart)

### dbo.RecompileEvents

Reads the ring buffer of the Extended Events session XE_Recompiles and returns, for each recompile event, its time, its cause, the object and the statement offsets.

- Type: stored procedure
- Shows: shredding of Extended Events XML (nodes and value) with conversion of the UTC timestamp to local time
- Tables: sys.dm_xe_sessions, sys.dm_xe_session_targets
- Writes data: no
- Minimum version: SQL Server 2016

Example: none (needs an Extended Events session named XE_Recompiles with a ring_buffer target, a server object that is not part of the database)

### dbo.vBestInvoices

Gives, for each month of each year, the largest gross invoice amount.

- Type: view
- Shows: a view that aggregates with MAX and groups by two expressions on the same date
- Tables: Enrollment.Invoice
- Writes data: no
- Minimum version: SQL Server 2016

```sql
SELECT TOP (10) * FROM dbo.vBestInvoices ORDER BY YearNo, MonthNo;
```

### dbo.vContactInvoice

Lists, for each contact, the invoices of its enrollments: gross amount, invoice code and date.

- Type: view
- Shows: a view that joins four tables (contact, enrollment, enrollment-invoice link, invoice)
- Tables: Contact.Contact, Enrollment.Enrollment, Enrollment.EnrollmentInvoice, Enrollment.Invoice
- Writes data: no
- Minimum version: SQL Server 2016

```sql
SELECT TOP (10) * FROM dbo.vContactInvoice;
```

### diagnostic.GenerateWorkload

Generates a workload lasting @duration minutes: for each of 1,500 distinct last names, two ad hoc queries (a SELECT, then a SELECT INTO a global temporary table), then a loop of three reporting queries every 3 seconds.

- Type: stored procedure
- Shows: a workload for the plan cache and the diagnostic tools: dynamic SQL with concatenated values, global temporary tables, a cursor, queries repeated in a loop
- Tables: Contact.Contact, Enrollment.EnrollmentInvoice, Enrollment.Enrollment, Enrollment.Invoice, Course.Session, Course.CourseLanguage, Course.Course
- Writes data: no
- Minimum version: SQL Server 2016

Example: none (runs for @duration minutes and creates up to 1,500 global temporary tables ##temp<n>, which stay until the server restarts)

### diagnostic.udf_scalar

Lists all the contacts with their number of enrollments, computed by the scalar function Contact.GetEnrollmentCount.

- Type: stored procedure
- Shows: a scalar function called once per row in the select list
- Tables: Contact.Contact, Contact.GetEnrollmentCount (function)
- Writes data: no
- Minimum version: SQL Server 2016

Example: none (returns one row per contact, about 120,000, and calls the function once per row: meant to be profiled, not read)

### diagnostic.udf_tableInline

Lists all the contacts with their number of enrollments, computed by the inline function Contact.GetEnrollmentCountTableInline.

- Type: stored procedure
- Shows: an inline table-valued function called through OUTER APPLY
- Tables: Contact.Contact, Contact.GetEnrollmentCountTableInline (function)
- Writes data: no
- Minimum version: SQL Server 2016

Example: none (returns one row per contact, about 120,000: meant to be compared with diagnostic.udf_scalar and diagnostic.udf_tableMulti, not read)

### diagnostic.udf_tableMulti

Lists the contacts with their number of enrollments, computed by the multi-statement function Contact.GetEnrollmentCountTableMulti.

- Type: stored procedure
- Shows: a multi-statement table-valued function called through CROSS APPLY
- Tables: Contact.Contact, Contact.GetEnrollmentCountTableMulti (function)
- Writes data: no
- Minimum version: SQL Server 2016

Example: none (calls the function once per contact, about 120,000 times: meant to be compared with diagnostic.udf_scalar and diagnostic.udf_tableInline, not read)

### Enrollment.vEnrollmentWithArchives

Exposes the current enrollments and the 2011 archive as a single set, with a Source column (0 for current, 2011 for the archive).

- Type: view
- Shows: a UNION ALL view over two tables with the same columns
- Tables: Enrollment.CurrentEnrollment, Enrollment.Enrollment_Archive2011
- Writes data: no
- Minimum version: SQL Server 2016

```sql
SELECT TOP (10) * FROM Enrollment.vEnrollmentWithArchives;
```

### Reference.GetCitiesByRegion

Returns all the columns of the cities of a region given by its code.

- Type: stored procedure
- Shows: a filter on RegionCode with a float parameter
- Tables: Reference.City
- Writes data: no
- Minimum version: SQL Server 2016

```sql
EXEC Reference.GetCitiesByRegion @RegionCode = 82;
```

### to_trace.WeirdProcedure01

For each trainer, lists the sessions of the same course and language taught by another trainer, among the sessions that have enrollments.

- Type: stored procedure
- Shows: a WHILE loop over a table variable, with a join of sessions on themselves, meant to be traced
- Tables: Trainer.Trainer, Enrollment.Enrollment, Course.Session
- Writes data: no
- Minimum version: SQL Server 2016

Example: none (loops over every trainer with a self-join of the sessions: heavy, and meant to be traced rather than read)

### Tools.GetSetOptions

Decodes the @@OPTIONS bit mask received into the comma-separated list of the SET options it enables.

- Type: scalar function
- Shows: a scalar function that builds a lookup table variable and aggregates the names with STRING_AGG
- Tables: none
- Writes data: no
- Minimum version: SQL Server 2017

```sql
SELECT Tools.GetSetOptions(@@OPTIONS) AS SetOptions;
```

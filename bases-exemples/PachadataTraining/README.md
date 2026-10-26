# PachadataTraining

PachadataTraining is the English-language sample database of Pachadata for SQL Server. It models a French training company: contacts and client companies, a course catalog, sessions, enrollments, invoices and payments, trainers, e-mail campaigns and an e-learning platform. The people, companies and cities in the data are French and fictitious. The names of the schemas, tables, columns, constraints, indexes and modules, the descriptions and the reference labels are in English.

It supports the Pachadata training courses, books and articles. Its French twin, PachadataFormation, has the same data and French names.

## Version

The current version is `2026-10`. A published version never changes. It is named by its month and recorded in the database as the extended property `Version`. The [changelog](CHANGELOG.md) lists the versions. The database has compatibility level 160 (SQL Server 2022) and the collation `French_CI_AS`.

## Contents

| Item | Count |
|---|---|
| Schemas with tables | 11 |
| Tables | 64 |
| Columns | 420 |
| Rows in all tables | 26,759,034 |
| Foreign keys | 68 |
| Primary keys | 55 |
| Unique constraints | 20 |
| Check constraints | 33 |
| Default constraints | 30 |
| Views | 8 |
| Stored procedures | 59 |
| Functions | 6 |
| Triggers | 1 |
| Descriptions (`MS_Description`) on tables and columns | 484 |

The largest tables are `Analytics.ActivityFact` (7,805,406 rows), `Elearning.Activity` (7,805,406 rows), `Marketing.Delivery` (4,018,304 rows), `Contact.ProspectUS` (1,000,000 rows), `Contact.ProspectUS_MAX` (1,000,000 rows). The [schema overview](schema/README.md) lists every table with its row count and description, and each schema has its own page with a diagram and the dictionary of its columns. The [module catalog](procedures.md) describes the 74 code modules (16 in the `Demo` schema, 9 in the `Report` schema).

The procedures take October 18, 2026 as today's date when they need one, because that is the date of the data. Their date parameters can be overridden.

## Language

- Object names are in English: 794 names were translated, from schemas to file names.
- Descriptions of tables and columns are in English.
- Reference labels and codes are in English where the table is small enough to be rewritten (see the next sections). Course texts have an English row for every course: 514 of 514 courses. The English texts that the French catalog did not have were machine-translated from the French rows.
- Names of people, companies and cities, and the free text of the generated data, stay French.
- The collation `French_CI_AS` is kept.

## Deliberate imperfections

Database options at delivery: automatic creation of statistics is on, read committed snapshot isolation is on, Query Store is on, and the database scoped configuration `MAXDOP` is 2. The imperfections below are kept on purpose, because the exercises need them.

- Foreign keys without a supporting index: 46 of 68 foreign keys have no rowstore index that starts with their columns. The Foreign keys table of each schema page marks them.
- Heaps: 12 tables are heaps (`Contact.ProspectUS`, `Contact.ProspectUS_MAX`, `Contact.ProspectUS_N`, `Contact.ProspectUS_SQL_Latin1`, `Elearning.Activity`, `Enrollment.CurrentEnrollment`, `Enrollment.Enrollment_Archive2011`, `Enrollment.PartitionedEnrollment`, `Reference.Country`, `Reference.CurrencyArchive`, `Reference.PaymentMethod`, `Reference.Region`). `Elearning.Activity` is a heap with a non-clustered primary key.
- Four copies of the same one million fictitious US prospects (`Contact.ProspectUS`, `Contact.ProspectUS_MAX`, `Contact.ProspectUS_N`, `Contact.ProspectUS_SQL_Latin1`), declared differently on purpose to compare storage size and collation behavior.
- `Reference.City` has columns with deliberately imperfect types.
- `Flat.Enrollment` is denormalized on purpose; `Flat.EnrollmentNormal` is its normalized form.
- `Enrollment.PartitionedEnrollment` is partitioned on its creation date.
- `Contact.atr_Contact_CheckEmail` is an `AFTER UPDATE` trigger that reads a single row of `inserted`, so only one row of a multi-row update is checked.
- `Report.OverduePayments` ends with `OPTION (HASH JOIN)`: the filter on the balance computed by a view is estimated at one row, and without the hint the engine chooses nested loops.
- The `Demo` schema has 8 pairs of procedures, each with a slow and a fixed version that return the same result (`Demo.ActivityPage`, `Demo.ContactsByName`, `Demo.ContactsWithoutDelivery`, `Demo.FlagReminders`, `Demo.LastDeliveryByContact`, `Demo.RevenueByCourse`, `Demo.SearchSessions`, `Demo.SessionsByYear`).

## Names that stay French

Some objects could not be renamed, and some codes were not translated.

- SQL Server refuses to rename partition functions and partition schemes with `sp_rename`, and a schema collection of XML cannot be renamed either. They keep their French names: the partition function `pfDateCreation`, the partition scheme `psDateCreation` and the XML schema collection `dbo.DepartementSchema`. Recreating them would mean rebuilding the partitioned table.
- The event type codes of the e-learning platform (`CONN`, `CVIR`, `DECO`, `FINM`, `OUVR`, `PAGE`, `QUIZ`, `VIDE`) stay as they are, with English labels in `Elearning.EventType`. The two tables that store them, `Elearning.Activity` and `Analytics.ActivityFact`, have 7,805,406 rows each, and translating the codes would rewrite them and destroy the row groups of the ordered columnstore index.
- Columns whose codes are not translated:

| Table | Column | Reason |
|---|---|---|
| `Analytics.ActivityFact` | `Device` | table of 7.8 million rows: translating the codes would rewrite the whole table |
| `Analytics.ActivityFact` | `EventTypeCode` | table of 7.8 million rows: translating the codes would rewrite the whole table |
| `Contact.Company` | `CountryCode` | ISO 3166 country code |
| `Contact.Company` | `LanguageCode` | ISO 639-1 language code |
| `Course.CourseLanguage` | `LanguageCode` | ISO 639-1 language code |
| `Course.Language` | `LanguageCode` | ISO 639-1 language code |
| `Course.Session` | `LanguageCode` | ISO 639-1 language code |
| `Elearning.Activity` | `Device` | table of 7.8 million rows: translating the codes would rewrite the whole table |
| `Elearning.Activity` | `EventTypeCode` | table of 7.8 million rows: translating the codes would rewrite the whole table |
| `Elearning.EventType` | `EventTypeCode` | key referenced by a table of 7.8 million rows: the codes stay, the labels are translated |
| `Enrollment.EnrollmentInvoice` | `InvoiceCode` | invoice identifier, the same in both languages |
| `Enrollment.Invoice` | `InvoiceCode` | invoice identifier, the same in both languages |
| `Enrollment.Invoice` | `OriginalInvoiceCode` | invoice identifier, the same in both languages |
| `Enrollment.InvoiceHistory` | `InvoiceCode` | invoice identifier, the same in both languages |
| `Enrollment.InvoiceHistory` | `OriginalInvoiceCode` | invoice identifier, the same in both languages |
| `Enrollment.InvoiceLine` | `InvoiceCode` | invoice identifier, the same in both languages |
| `Enrollment.Payment` | `InvoiceCode` | invoice identifier, the same in both languages |
| `Reference.City` | `CountryCode` | ISO 3166 country code |
| `Reference.Country` | `CountryCode` | ISO 3166 country code |
| `Reference.Currency` | `CurrencyCode` | ISO 4217 currency code |
| `Reference.CurrencyArchive` | `CurrencyCode` | ISO 4217 currency code |
| `Reference.CurrencyHistory` | `CurrencyCode` | ISO 4217 currency code |
| `Reference.Holiday` | `CountryCode` | ISO 3166 country code |
| `Reference.Region` | `CountryCode` | ISO 3166 country code |
| `Reference.TrainingLocation` | `CountryCode` | ISO 3166 country code |
| `Reference.TrainingRoom` | `Corridor` | the letters A and B, nothing to translate |
| `Trainer.TrainerLanguage` | `LanguageCode` | ISO 639-1 language code |

## Download

| Item | Value |
|---|---|
| File | `PachadataTraining-2026-10.bak` |
| For | SQL Server 2022 and later |
| Short link to the latest version | https://anaxago.re/pachadatatraining-sqlserver |
| Direct address of this version | https://files.pachadata.com/public/api/raw?hash=tAsyC50c6kfVadBp3zc6TQ&file=/PachadataTraining/SqlServer/PachadataTraining-2026-10.bak |
| Size | 626,184,192 bytes |
| SHA-256 | `1d05970d8e0576cd0c57bddba64c2ba8a583845ad4744adeb75d2ea4a3f7d44e` |

## Restoring the database

See [Restoring on SQL Server](engines/sql-server.md). A backup for SQL Server 2019, a `.bacpac` file and exports for other engines will come later.

## In this folder

- [schema/README.md](schema/README.md): schemas, tables, row counts and the diagram of the relationships between schemas.
- [procedures.md](procedures.md): the catalog of the 74 code modules.
- [engines/sql-server.md](engines/sql-server.md): restoring the backup.
- [CHANGELOG.md](CHANGELOG.md): the published versions.
- [vectors/](vectors/): the scripts and the course that add vector columns and embeddings, from an earlier version of this project.
- [archive/](archive/): the other files of the earlier version of this project, kept as they were.

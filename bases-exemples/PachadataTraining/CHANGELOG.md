# Changelog

Every published version is named by its month, never changes after publication, and has its own backup file. The name of the version is recorded in the database as the extended property `Version`.

## 2026-10

First published version of PachadataTraining, the English-language twin of the French sample database PachadataFormation, October 2026.

- Names of schemas, tables, columns, indexes, constraints, views, functions, procedures, triggers, types and files translated to English.
- Reference labels and the codes of the tables of fewer than one million rows translated; names and codes that stay French are listed in the README.
- Every course has an English text row.
- 74 code modules, all with a header that states what they do, what they show and which tables they read.
- 484 descriptions on tables and columns, as `MS_Description` extended properties.
- Compatibility level 160, backup for SQL Server 2022 and later.
- The files of the earlier project that used this folder moved to `vectors/` and `archive/`.

# Restoring on SQL Server

This page explains how to restore `PachadataTraining-2026-10.bak` on SQL Server 2022 and later.

## Requirements

- SQL Server 2022 or later. The database has compatibility level 160 and the backup was taken on SQL Server 2022. A backup taken on a newer version cannot be restored on an older one, so this file cannot be restored on SQL Server 2019 or earlier. A backup for SQL Server 2019 is planned and will be added to this page.
- Free disk space for the data and log files. `RESTORE FILELISTONLY` below reports the size of each file.
- A login with the `dbcreator` role, or `sysadmin`.

## Download

Download the latest version from the short link, or the file of this version from its direct address:

- Short link to the latest version: https://anaxago.re/pachadatatraining-sqlserver
- Direct address of version 2026-10: https://files.pachadata.com/public/api/raw?hash=tAsyC50c6kfVadBp3zc6TQ&file=/PachadataTraining/SqlServer/PachadataTraining-2026-10.bak

The size and the SHA-256 checksum of the file are in the [download section of the README](../README.md#download). To check the file on Linux or macOS:

```bash
sha256sum PachadataTraining-2026-10.bak
```

On Windows PowerShell:

```powershell
Get-FileHash .\PachadataTraining-2026-10.bak -Algorithm SHA256
```

## Restoring with Transact-SQL

First list the files stored in the backup. The logical names are needed for the `MOVE` clauses.

```sql
RESTORE FILELISTONLY
FROM DISK = N'C:\Backups\PachadataTraining-2026-10.bak';
```

The logical names of the delivered database are `PachadataTraining` for the data file and `PachadataTraining_log` for the log file. Use the names that `RESTORE FILELISTONLY` returns if they differ. Then restore the database, choosing the folders of your instance:

```sql
RESTORE DATABASE PachadataTraining
FROM DISK = N'C:\Backups\PachadataTraining-2026-10.bak'
WITH MOVE N'PachadataTraining' TO N'C:\SqlData\PachadataTraining.mdf',
     MOVE N'PachadataTraining_log' TO N'C:\SqlData\PachadataTraining_log.ldf',
     STATS = 10;
```

To restore under another name, change the database name and the two target files. The logical names stay the same.

## Restoring in a Linux container

The example uses Podman. With Docker, replace `podman` by `docker`. The container is called `sql2022` and runs an official SQL Server 2022 or 2025 image. Set the password of `sa` in the environment of your shell first, without writing it in the command line:

```bash
read -rs SQLCMDPASSWORD && export SQLCMDPASSWORD
podman exec sql2022 mkdir -p /var/opt/mssql/backup
podman cp PachadataTraining-2026-10.bak sql2022:/var/opt/mssql/backup/PachadataTraining-2026-10.bak
```

Then run the same two statements through `sqlcmd` in the container (the path below is the one of the 2022 images):

```bash
podman exec -i -e SQLCMDPASSWORD sql2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -Q "
RESTORE FILELISTONLY FROM DISK = N'/var/opt/mssql/backup/PachadataTraining-2026-10.bak';"

podman exec -i -e SQLCMDPASSWORD sql2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -Q "
RESTORE DATABASE PachadataTraining
FROM DISK = N'/var/opt/mssql/backup/PachadataTraining-2026-10.bak'
WITH MOVE N'PachadataTraining' TO N'/var/opt/mssql/data/PachadataTraining.mdf',
     MOVE N'PachadataTraining_log' TO N'/var/opt/mssql/data/PachadataTraining_log.ldf',
     STATS = 10;"
```

If the restore stops with operating system error 5 (access denied), the file copied into the container is not readable by the `mssql` user: give it to that user with `podman exec -u 0 sql2022 chown mssql:mssql /var/opt/mssql/backup/PachadataTraining-2026-10.bak` and run the restore again.

## Checking the restored database

```sql
SELECT name, compatibility_level, collation_name
FROM sys.databases
WHERE name = N'PachadataTraining';

SELECT value
FROM PachadataTraining.sys.extended_properties
WHERE class = 0 AND name = N'Version';

SELECT COUNT(*) AS tables
FROM PachadataTraining.sys.tables;
```

The expected values are compatibility level 160, collation `French_CI_AS`, version `2026-10` and 64 tables.

## Collation

The database collation is `French_CI_AS` and is kept by the restore. On an instance whose default collation is different, a comparison between a column of the database and a column of a temporary table can fail with error 468 (collation conflict). Create the temporary table with `COLLATE DATABASE_DEFAULT` on its text columns, or restore on an instance that uses the same collation.

## Other versions and other engines

This page only covers the SQL Server 2022 backup. A backup for SQL Server 2019, a `.bacpac` file for Azure SQL Database and exports for other database engines will be added later, each with its own page in this folder.

# Utilité de l'index clustered

## Création 

```sql
USE tempdb;
GO

DROP TABLE IF EXISTS messages_clustered;
GO

CREATE TABLE messages_clustered (
    message_isn bigint not null identity(1, 1) primary key clustered,
    message_id int not null,
    language_id smallint not null,
    severity tinyint not null,
    logged bit not null,
    texte nvarchar(max) not null
)
GO

INSERT INTO messages_clustered
(message_id, language_id, severity, logged, texte)
SELECT 
    message_id,
    language_id,
    severity,
    is_event_logged,
    [text]
FROM sys.messages;
GO

DROP TABLE IF EXISTS messages_nonclustered;
GO

CREATE TABLE messages_nonclustered (
    message_isn bigint not null identity(1, 1) primary key nonclustered,
    message_id int not null,
    language_id smallint not null,
    severity tinyint not null,
    logged bit not null,
    texte nvarchar(max) not null
)
GO

INSERT INTO messages_nonclustered
(message_id, language_id, severity, logged, texte)
SELECT 
    message_id,
    language_id,
    severity,
    is_event_logged,
    [text]
FROM sys.messages;
```

IO :

```
Table 'messages_clustered'. Nombre d'analyses 0, lectures logiques 45776.
(281182 lignes affectées)

Table 'messages_nonclustered'. Nombre d'analyses 0, lectures logiques 295811.
(281182 lignes affectées)
```

## Scan

```sql
SELECT *
FROM messages_clustered
WHERE severity = 40
OPTION (MAXDOP 1);
-- lectures logiques 9151

SELECT *
FROM messages_nonclustered
WHERE severity = 40
OPTION (MAXDOP 1);
-- lectures logiques 9055
```

## Création d'un index « secondaire »

```sql
CREATE NONCLUSTERED INDEX nix_messages_clustered_message_id ON messages_clustered (message_id);
CREATE NONCLUSTERED INDEX nix_messages_nonclustered_message_id ON messages_nonclustered (message_id);
```

## Recherche sur index « secondaire »

```sql
SELECT *
FROM messages_clustered
WHERE message_id = 1209
OPTION (MAXDOP 1);
-- lectures logiques 69

SELECT *
FROM messages_nonclustered
WHERE message_id = 1209
OPTION (MAXDOP 1);
-- lectures logiques 25
```

## Nettoyage

```sql
DROP TABLE IF EXISTS messages_clustered;
DROP TABLE IF EXISTS messages_nonclustered;
GO
```
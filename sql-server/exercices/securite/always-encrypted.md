# Always Encrypted

L'objectif de cet exercice est de démontrer comment utiliser Always Encrypted pour chiffrer une colonne dans une base de données SQL Server, 
et comment accéder aux données chiffrées à partir d'une application .NET Core en utilisant les clés de chiffrement.

## Étape 1 : Configuration du certificat de chiffrement et de la clé de chiffrement

La première étape consiste à créer un certificat de chiffrement et une clé de chiffrement dans SQL Server.
Vous pouvez utiliser les mêmes étapes que celles décrites précédemment pour créer le certificat et la clé de chiffrement.

```sql
USE PachaDataFormation;

CREATE COLUMN MASTER KEY MyCMK WITH (  
	KEY_STORE_PROVIDER_NAME = 'MSSQL_CERTIFICATE_STORE',  
	KEY_PATH = 'CurrentUser/My/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'  
);  
GO  

CREATE COLUMN ENCRYPTION KEY MyCEK WITH VALUES (  
	ENCRYPTED_VALUE = **************,  
	ENCRYPTION_TYPE = RANDOMIZED,  
	ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256'  
);  
GO  

CREATE TABLE Clients (  
	Id INT IDENTITY(1,1) PRIMARY KEY,  
	Nom NVARCHAR(50),  
	Prenom NVARCHAR(50),  
	Email NVARCHAR(100),  
	Telephone NVARCHAR(20),  
	Salaire DECIMAL(10, 2)   
	ENCRYPTED WITH (  
```

## Étape 2 : Création de la table dans la base de données

Créez une table "Clients" dans une base de données SQL Server contenant les colonnes suivantes :

- Id (int, identité, clé primaire)
- Nom (nvarchar(50))
- Prenom (nvarchar(50))
- Email (nvarchar(100))
- Telephone (nvarchar(20))
- Salaire (decimal(10, 2))

Chiffrez la colonne "Salaire" en utilisant Always Encrypted et la clé de chiffrement créée à l'étape précédente.

```sql	
CREATE TABLE Clients (  
	Id INT IDENTITY(1,1) PRIMARY KEY,  
	Nom NVARCHAR(50),  
	Prenom NVARCHAR(50),  
	Email NVARCHAR(100),  
	Telephone NVARCHAR(20),  
	Salaire DECIMAL(10, 2)   
	ENCRYPTED WITH (  
		COLUMN_ENCRYPTION_KEY = MyCEK,  
		ENCRYPTION_TYPE = RANDOMIZED,  
		ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256'  
	)  
);
```

## Étape 3 : Configuration de la connexion de base de données avec Always Encrypted

Créez une connexion de base de données avec Always Encrypted en utilisant le fournisseur de données SQL Server de .NET Core. 
La configuration de la connexion doit inclure les informations de clé de chiffrement nécessaires pour accéder aux données chiffrées.

```powershell
winget search Microsoft.DotNet
winget install Microsoft.DotNet.SDK.7
# winget install Microsoft.DotNet.SDK.Preview

# To specify the architecture (x86, x64, and Arm64), use the following command:
winget install --architecture x64 Microsoft.DotNet.SDK.7

# Uninstall .NET using winget
winget uninstall Microsoft.DotNet.SDK.7

# to update .NET using winget
winget upgrade Microsoft.DotNet.SDK.7

dotnet new console -o PachaChiffre

cd PachaChiffre
code .
```

```csharp
using System.Data;

# using System.Data.SqlClient; -- replaced by Microsoft.Data.SqlClient

using Microsoft.Data.SqlClient;

// Étape 3 : Configuration de la connexion de base de données avec Always Encrypted
string connectionString = "Server=myServerAddress;Database=myDataBase;User Id=myUsername;Password=myPassword;Column Encryption Setting=Enabled;";
SqlConnection connection = new SqlConnection(connectionString);

SqlColumnEncryptionCertificateStoreProvider certificateStoreProvider = new SqlColumnEncryptionCertificateStoreProvider();
SqlColumnEncryptionKeyStoreProvider keyStoreProvider = new SqlColumnEncryptionKeyStoreProvider();

SqlColumnEncryptionEnclaveProvider enclaveProvider = new SqlColumnEncryptionEnclaveProvider();
enclaveProvider.GetEnclaveSession("MyEnclaveSession");

SqlColumnEncryptionAzureKeyVaultProvider akvProvider = new SqlColumnEncryptionAzureKeyVaultProvider(certificateStoreProvider, keyStoreProvider, enclaveProvider);

SqlCommand cmd = connection.CreateCommand();
cmd.CommandText = "SELECT Nom, Prenom, Telephone, CONVERT(DECIMAL(10,2), Salaire) AS Salaire FROM Clients";
cmd.CommandType = CommandType.Text;

// Configure la connexion avec Always Encrypted
SqlColumnEncryptionConnection columnEncryptionConnection = new SqlColumnEncryptionConnection(connection, akvProvider);
columnEncryptionConnection.Open();

SqlDataReader reader = cmd.ExecuteReader(CommandBehavior.Default);

while (reader.Read())
{
    string nom = reader.GetString(0);
    string prenom = reader.GetString(1);
    string telephone = reader.GetString(2);
    decimal salaire = reader.GetDecimal(3);

    Console.WriteLine($"{nom} {prenom} ({telephone}) : {salaire:C}");
}

reader.Close();
columnEncryptionConnection.Close();
```

### Exécution de l'application

Assurez-vous que le fichier de projet ".csproj" est présent dans ce dossier.

Tapez la commande suivante pour restaurer les packages NuGet :

```powershell	
dotnet add package Microsoft.Data.SqlClient

dotnet restore
```

Cette commande télécharge et installe les packages NuGet nécessaires au projet.

Tapez la commande suivante pour compiler le projet :

```powershell	
dotnet build
```

Cette commande compile le projet et génère un exécutable dans le dossier "bin".

Tapez la commande suivante pour exécuter le projet :

```powershell	
dotnet run
```

## Étape 4 : Insertion de données chiffrées dans la table

Utilisez une application .NET Core pour insérer des données dans la table "Clients". 
Les données de la colonne "Salaire" doivent être chiffrées à l'aide de la clé de chiffrement configurée à l'étape 3.

## Étape 5 : Lecture des données chiffrées à partir de la table

Utilisez une application .NET Core pour lire les données de la table "Clients". 
Les données de la colonne "Salaire" doivent être déchiffrées à l'aide de la clé de chiffrement configurée à l'étape 3.

Voici le code côté SQL Server pour les étapes 1 et 2 :

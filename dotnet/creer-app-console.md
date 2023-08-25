# Créer une application .NET en console

1. Téléchargez le dernier SDK.

```powershell
winget install -e --id Microsoft.DotNet.SDK.7
```

2. dans un dossier dans la console :

```powershell
dotnet new console
```

3. ajouter le support des fichiers de configuration

```
dotnet add package Microsoft.Extensions.Configuration
dotnet add package Microsoft.Extensions.Configuration.Json
dotnet add package Microsoft.Data.SqlClient
```

If you want to copy a file to your output folder you can add this to your csproj file:

```xml
<ItemGroup>
   <None Update="appsettings.IntegrationTests.json">
     <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
   </None>
</ItemGroup>
```
using System;
using Microsoft.Extensions.Configuration;
using Microsoft.Data.SqlClient;

var configurationBuilder = new ConfigurationBuilder()
			.SetBasePath(AppDomain.CurrentDomain.BaseDirectory)
			.AddJsonFile("appsettings.json", optional: true, reloadOnChange: true);
			// .AddEnvironmentVariables()
			// .AddCommandLine(args);

IConfiguration configuration = configurationBuilder.Build();

// var appName = configuration["AppSettings:AppName"];
// var appVersion = configuration["AppSettings:AppVersion"];
var connectionString = configuration["ConnectionStrings:DefaultConnection"];

// Console.WriteLine($"AppName: {appName}");
// Console.WriteLine($"AppVersion: {appVersion}");
// Console.WriteLine($"ConnectionString: {connectionString}");

try 
{
    using (var connection = new SqlConnection(connectionString))
    {
        connection.Open();       

        String sql = "SELECT name, collation_name FROM sys.databases";

        using SqlCommand command = new SqlCommand(sql, connection);
        using SqlDataReader reader = command.ExecuteReader();
        while (reader.Read())
        {
            Console.WriteLine("{0} {1}", reader.GetString(0), reader.GetString(1));
        }
    }
}
catch (SqlException e)
{
    Console.WriteLine(e.ToString());
}


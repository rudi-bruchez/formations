using System.Data;
using Microsoft.Data.SqlClient;

// Configuration de la connexion de base de données avec Always Encrypted
string connectionString = @"Data Source=localhost; Initial Catalog=PachadataFormation; 
    Integrated Security=true; Column Encryption Setting=enabled; Trust Server Certificate=true";

using var cn = new SqlConnection(connectionString);

using var cmdInsert = cn.CreateCommand();

cmdInsert.CommandText = @"INSERT INTO Contact.AccesExtranet (ContactId, MotDePasse, PermissionLecture, PermissionEcriture) 
    VALUES (1, @mdp, 1, 0);";

cmdInsert.CommandType = CommandType.Text;

var mdp = new SqlParameter("@mdp", "RenardCendre456");
mdp.SqlDbType = SqlDbType.NVarChar;
mdp.Size = 50;
mdp.Direction = ParameterDirection.Input;

cmdInsert.Parameters.Add(mdp);

cn.Open();

cmdInsert.ExecuteNonQuery();

cn.Close();
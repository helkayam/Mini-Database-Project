using Npgsql;
using System;
using System.Data;
 
namespace BakeryManagementSystem 
{
    // create connection between my server in pgadmin and between the wpt
    public static class DatabaseHelper
    {
        private static string connectionString = "Host=metro.proxy.rlwy.net; Port=37843; Username=postgres; Password=PfjlMnFtlWSRXlMzIAMILViEOHmBqUSe; Database=railray_copy";

        public static NpgsqlConnection GetConnection()
        {
            return new NpgsqlConnection(connectionString);
        }
    }
}
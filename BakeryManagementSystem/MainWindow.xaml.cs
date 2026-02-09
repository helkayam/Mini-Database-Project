using Npgsql;
using System;
using System.Windows;

namespace BakeryManagementSystem
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        private void btnLogin_Click(object sender, RoutedEventArgs e)
        {
            string inputId = txtEmployeeId.Text;
            lblStatus.Text = "מתחבר...";

            try
            {
                using (var conn = DatabaseHelper.GetConnection())
                {
                    conn.Open();
                    // שליפת השם והתפקיד
                    string query = "SELECT first_name, role FROM employee WHERE employee_id = @id";

                    using (var cmd = new NpgsqlCommand(query, conn))
                    {
                        if (int.TryParse(inputId, out int empId))
                        {
                            cmd.Parameters.AddWithValue("id", empId);

                            using (var reader = cmd.ExecuteReader())
                            {
                                if (reader.Read())
                                {
                                    // 1. שליפת הנתונים (אופציונלי, לשימוש עתידי)
                                    string name = reader.GetString(0);
                                    string role = reader.GetString(1);

                                    // 2. יצירת החלון הראשי
                                    MainMenuWindow menu = new MainMenuWindow();

                                    // 3. הצגת החלון הראשי
                                    menu.Show();

                                    // 4. סגירת חלון הכניסה הנוכחי
                                    this.Close();
                                }
                                else
                                {
                                    lblStatus.Text = "שגיאה: מספר עובד לא נמצא.";
                                }
                            }
                        }
                        else
                        {
                            lblStatus.Text = "אנא הזן מספרים בלבד.";
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                lblStatus.Text = "שגיאת התחברות";
                MessageBox.Show("פרטי השגיאה:\n" + ex.Message);
            }
        }
    }
}
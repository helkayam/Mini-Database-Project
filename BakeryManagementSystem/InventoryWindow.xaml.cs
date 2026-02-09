using Npgsql;
using System;
using System.Data;
using System.Windows;
using System.Windows.Controls;
using System.Xml.Linq;

namespace BakeryManagementSystem
{
    public partial class InventoryWindow : Window
    {
        // --- שינוי 1: משתנה גלובלי (כאן מגדירים אותו כדי שכולם יכירו אותו) ---
        private DataTable dtIngredients;
        public InventoryWindow()
        {
            InitializeComponent();
            LoadData(); // טעינת הנתונים מיד כשהחלון נפתח
        }

        // פונקציה לטעינת הנתונים לטבלה
        private void LoadData()
        {
            try
            {
                using (var conn = DatabaseHelper.GetConnection())
                {
                    conn.Open();
                    string query = "SELECT * FROM ingredient ORDER BY ingredient_id";

                    NpgsqlDataAdapter da = new NpgsqlDataAdapter(query, conn);

                    // כאן השינוי: אנחנו ממלאים את המשתנה הגלובלי
                    dtIngredients = new DataTable();
                    da.Fill(dtIngredients);

                    // קישור לטבלה במסך
                    dgIngredients.ItemsSource = dtIngredients.DefaultView;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("שגיאה בטעינת נתונים: " + ex.Message);
            }
        }

        // כפתור הוספה
        private void btnAdd_Click(object sender, RoutedEventArgs e)
        {
            // בדיקת תקינות קלט בסיסית
            if (string.IsNullOrWhiteSpace(txtName.Text) || cmbUnit.SelectedItem == null || string.IsNullOrWhiteSpace(txtCost.Text))
            {
                MessageBox.Show("נא למלא את כל השדות");
                return;
            }

            try
            {
                using (var conn = DatabaseHelper.GetConnection())
                {
                    conn.Open();
                    string query = "INSERT INTO ingredient (name, unit, cost_per_unit, allergen_flag) VALUES (@n, @u, @c, @a)";

                    using (var cmd = new NpgsqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("n", txtName.Text);
                        cmd.Parameters.AddWithValue("u", (cmbUnit.SelectedItem as ComboBoxItem).Content.ToString());
                        cmd.Parameters.AddWithValue("c", decimal.Parse(txtCost.Text)); // המרה למספר עשרוני

                        // ברירת מחדל לאלרגן היא NO אם לא נבחר
                        string allergen = "NO";
                        if (cmbAllergen.SelectedItem != null)
                            allergen = (cmbAllergen.SelectedItem as ComboBoxItem).Content.ToString();

                        cmd.Parameters.AddWithValue("a", allergen);

                        cmd.ExecuteNonQuery(); // ביצוע ההוספה
                    }
                }

                // ניקוי השדות ורענון הטבלה
                txtName.Clear();
                txtCost.Clear();
                LoadData();
                MessageBox.Show("נוסף בהצלחה!");
            }
            catch (Exception ex)
            {
                MessageBox.Show("שגיאה בהוספה: " + ex.Message);
            }
        }

        // כפתור מחיקה
        private void btnDelete_Click(object sender, RoutedEventArgs e)
        {
            // בדיקה אם נבחרה שורה
            if (dgIngredients.SelectedItem == null)
            {
                MessageBox.Show("נא לבחור שורה למחיקה");
                return;
            }

            // המרה של השורה שנבחרה לאובייקט שאפשר לקרוא ממנו
            DataRowView row = (DataRowView)dgIngredients.SelectedItem;
            int id = (int)row["ingredient_id"]; // שליפת ה-ID

            if (MessageBox.Show("האם למחוק את פריט מספר " + id + "?", "אישור מחיקה", MessageBoxButton.YesNo) == MessageBoxResult.Yes)
            {
                try
                {
                    using (var conn = DatabaseHelper.GetConnection())
                    {
                        conn.Open();
                        string query = "DELETE FROM ingredient WHERE ingredient_id = @id";
                        using (var cmd = new NpgsqlCommand(query, conn))
                        {
                            cmd.Parameters.AddWithValue("id", id);
                            cmd.ExecuteNonQuery();
                        }
                    }
                    LoadData(); // רענון אחרי מחיקה
                }
                catch (Exception ex)
                {
                    MessageBox.Show("לא ניתן למחוק פריט זה (אולי הוא משויך למתכון קיים?)\n" + ex.Message);
                }
            }
        }

        private void btnRefresh_Click(object sender, RoutedEventArgs e)
        {
            LoadData();
        }

        private void btnBack_Click(object sender, RoutedEventArgs e)
        {
            this.Close(); // סגירת החלון הנוכחי
        }

        // פונקציה שמופעלת כשבוחרים שורה בטבלה
        private void dgIngredients_SelectionChanged(object sender, System.Windows.Controls.SelectionChangedEventArgs e)
        {
            if (dgIngredients.SelectedItem == null) return;

            // המרת השורה שנבחרה לאובייקט שאפשר לקרוא
            DataRowView row = (DataRowView)dgIngredients.SelectedItem;

            // מילוי השדות למעלה בנתונים מהשורה
            txtName.Text = row["name"].ToString();
            txtCost.Text = row["cost_per_unit"].ToString();

            // בחירת הערך הנכון ב-ComboBox של היחידות
            string unit = row["unit"].ToString();
            foreach (ComboBoxItem item in cmbUnit.Items)
            {
                if (item.Content.ToString() == unit)
                {
                    cmbUnit.SelectedItem = item;
                    break;
                }
            }

            // בחירת הערך הנכון באלרגנים
            string allergen = row["allergen_flag"].ToString();
            foreach (ComboBoxItem item in cmbAllergen.Items)
            {
                if (item.Content.ToString() == allergen)
                {
                    cmbAllergen.SelectedItem = item;
                    break;
                }
            }
        }

        private void btnUpdate_Click(object sender, RoutedEventArgs e)
        {
            // 1. בדיקה שנבחרה שורה לעדכון
            if (dgIngredients.SelectedItem == null)
            {
                MessageBox.Show("יש לבחור שורה בטבלה כדי לעדכן אותה");
                return;
            }

            // 2. שליפת ה-ID של השורה המסומנת (כדי שנדע את מי לעדכן)
            DataRowView row = (DataRowView)dgIngredients.SelectedItem;
            int idToUpdate = (int)row["ingredient_id"];

            try
            {
                using (var conn = DatabaseHelper.GetConnection())
                {
                    conn.Open();
                    // שאילתת SQL לעדכון
                    string query = "UPDATE ingredient SET name=@n, unit=@u, cost_per_unit=@c, allergen_flag=@a WHERE ingredient_id=@id";

                    using (var cmd = new NpgsqlCommand(query, conn))
                    {
                        // הזנת הפרמטרים מתיבות הטקסט (המעודכנות)
                        cmd.Parameters.AddWithValue("n", txtName.Text);
                        cmd.Parameters.AddWithValue("u", (cmbUnit.SelectedItem as ComboBoxItem).Content.ToString());
                        cmd.Parameters.AddWithValue("c", decimal.Parse(txtCost.Text));

                        string allergen = "NO";
                        if (cmbAllergen.SelectedItem != null)
                            allergen = (cmbAllergen.SelectedItem as ComboBoxItem).Content.ToString();
                        cmd.Parameters.AddWithValue("a", allergen);

                        // ה-ID המקורי (כדי לא לעדכן את כל הטבלה בטעות!)
                        cmd.Parameters.AddWithValue("id", idToUpdate);

                        cmd.ExecuteNonQuery();
                    }
                }

                // ניקוי ורענון
                MessageBox.Show("המוצר עודכן בהצלחה!");
                LoadData(); // טוען מחדש את הטבלה כדי לראות את השינוי

                // ניקוי השדות
                txtName.Clear();
                txtCost.Clear();
                cmbUnit.SelectedIndex = -1;
                cmbAllergen.SelectedIndex = -1;
            }
            catch (Exception ex)
            {
                MessageBox.Show("שגיאה בעדכון: " + ex.Message);
            }
        }

        // אירוע שמופעל בכל פעם שמקלידים אות בתיבת החיפוש
        private void txtSearch_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (dtIngredients == null) return;

            // שליפת הטקסט שהוקלד
            string searchText = txtSearch.Text;

            // סינון התצוגה (DataView)
            // השורה הזו אומרת: תציג רק שורות שהעמודה 'name' מכילה את הטקסט שהוקלד
            dtIngredients.DefaultView.RowFilter = $"name LIKE '%{searchText}%'";
        }
    }
}
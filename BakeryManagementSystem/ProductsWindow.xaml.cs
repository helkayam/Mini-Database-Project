using Npgsql;
using System;
using System.Data;
using System.Windows;
using System.Windows.Controls;
using System.Xml.Linq;

namespace BakeryManagementSystem
{
    public partial class ProductsWindow : Window
    {
        // משתנה גלובלי לחיפוש
        private DataTable dtProducts;

        public ProductsWindow()
        {
            InitializeComponent();
            LoadData();
        }

        // טעינת נתונים + הכנה לחיפוש
        private void LoadData()
        {
            try
            {
                using (var conn = DatabaseHelper.GetConnection())
                {
                    conn.Open();
                    string query = "SELECT * FROM product ORDER BY product_id";
                    NpgsqlDataAdapter da = new NpgsqlDataAdapter(query, conn);

                    dtProducts = new DataTable();
                    da.Fill(dtProducts);

                    dgProducts.ItemsSource = dtProducts.DefaultView;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("שגיאה בטעינת מוצרים: " + ex.Message);
            }
        }

        // חיפוש בזמן אמת
        private void txtSearch_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (dtProducts == null) return;
            string searchText = txtSearch.Text;
            dtProducts.DefaultView.RowFilter = $"name LIKE '%{searchText}%'";
        }

        // הוספת מוצר חדש
        private void btnAdd_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrWhiteSpace(txtName.Text) || cmbCategory.SelectedItem == null || string.IsNullOrWhiteSpace(txtPrice.Text))
            {
                MessageBox.Show("נא למלא את כל השדות");
                return;
            }

            try
            {
                using (var conn = DatabaseHelper.GetConnection())
                {
                    conn.Open();
                    string query = "INSERT INTO product (name, category, price) VALUES (@n, @c, @p)";
                    using (var cmd = new NpgsqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("n", txtName.Text);
                        cmd.Parameters.AddWithValue("c", (cmbCategory.SelectedItem as ComboBoxItem).Content.ToString());
                        cmd.Parameters.AddWithValue("p", decimal.Parse(txtPrice.Text));
                        cmd.ExecuteNonQuery();
                    }
                }

                // ניקוי ורענון
                txtName.Clear();
                txtPrice.Clear();
                LoadData();
                MessageBox.Show("המוצר נוסף בהצלחה!");
            }
            catch (Exception ex) { MessageBox.Show("שגיאה בהוספה: " + ex.Message); }
        }

        // עדכון מוצר קיים
        private void btnUpdate_Click(object sender, RoutedEventArgs e)
        {
            if (dgProducts.SelectedItem == null)
            {
                MessageBox.Show("יש לבחור מוצר לעדכון");
                return;
            }

            DataRowView row = (DataRowView)dgProducts.SelectedItem;
            int idToUpdate = (int)row["product_id"];

            try
            {
                using (var conn = DatabaseHelper.GetConnection())
                {
                    conn.Open();
                    string query = "UPDATE product SET name=@n, category=@c, price=@p WHERE product_id=@id";
                    using (var cmd = new NpgsqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("n", txtName.Text);
                        cmd.Parameters.AddWithValue("c", (cmbCategory.SelectedItem as ComboBoxItem).Content.ToString());
                        cmd.Parameters.AddWithValue("p", decimal.Parse(txtPrice.Text));
                        cmd.Parameters.AddWithValue("id", idToUpdate);
                        cmd.ExecuteNonQuery();
                    }
                }

                LoadData();
                MessageBox.Show("המוצר עודכן בהצלחה!");

                // ניקוי שדות
                txtName.Clear();
                txtPrice.Clear();
                cmbCategory.SelectedIndex = -1;
            }
            catch (Exception ex) { MessageBox.Show("שגיאה בעדכון: " + ex.Message); }
        }

        // בחירת שורה מהטבלה ומילוי השדות למעלה
        private void dgProducts_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (dgProducts.SelectedItem == null) return;

            DataRowView row = (DataRowView)dgProducts.SelectedItem;
            txtName.Text = row["name"].ToString();
            txtPrice.Text = row["price"].ToString();

            string category = row["category"].ToString();
            foreach (ComboBoxItem item in cmbCategory.Items)
            {
                if (item.Content.ToString() == category)
                {
                    cmbCategory.SelectedItem = item;
                    break;
                }
            }
        }

        // מחיקה
        private void btnDelete_Click(object sender, RoutedEventArgs e)
        {
            if (dgProducts.SelectedItem == null)
            {
                MessageBox.Show("נא לבחור מוצר למחיקה");
                return;
            }

            DataRowView row = (DataRowView)dgProducts.SelectedItem;
            int id = (int)row["product_id"];

            if (MessageBox.Show("למחוק את מוצר מס' " + id + "?", "אישור מחיקה", MessageBoxButton.YesNo) == MessageBoxResult.Yes)
            {
                try
                {
                    using (var conn = DatabaseHelper.GetConnection())
                    {
                        conn.Open();
                        string query = "DELETE FROM product WHERE product_id = @id";
                        using (var cmd = new NpgsqlCommand(query, conn))
                        {
                            cmd.Parameters.AddWithValue("id", id);
                            cmd.ExecuteNonQuery();
                        }
                    }
                    LoadData();
                }
                catch (Exception ex) { MessageBox.Show("לא ניתן למחוק (ייתכן שהמוצר משויך למתכון קיים)\n" + ex.Message); }
            }
        }

        private void btnRefresh_Click(object sender, RoutedEventArgs e) { LoadData(); }
        private void btnBack_Click(object sender, RoutedEventArgs e) { this.Close(); }
    }
}

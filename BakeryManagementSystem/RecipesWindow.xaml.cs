using Npgsql;
using System;
using System.Data;
using System.Windows;
using System.Windows.Controls;

namespace BakeryManagementSystem
{
    public partial class RecipesWindow : Window
    {
        private int currentRecipeId = -1;

        public RecipesWindow()
        {
            InitializeComponent();
            LoadProducts();
            LoadIngredients();
        }

        // טעינת מוצרים
        private void LoadProducts()
        {
            try
            {
                using (var conn = DatabaseHelper.GetConnection())
                {
                    conn.Open();
                    string query = "SELECT product_id, name FROM product ORDER BY name";
                    NpgsqlDataAdapter da = new NpgsqlDataAdapter(query, conn);
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    cmbProducts.ItemsSource = dt.DefaultView;
                }
            }
            catch (Exception ex) { MessageBox.Show("שגיאה בטעינת מוצרים: " + ex.Message); }
        }

        // טעינת חומרי גלם
        private void LoadIngredients()
        {
            try
            {
                using (var conn = DatabaseHelper.GetConnection())
                {
                    conn.Open();
                    string query = "SELECT ingredient_id, name FROM ingredient ORDER BY name";
                    NpgsqlDataAdapter da = new NpgsqlDataAdapter(query, conn);
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    cmbIngredients.ItemsSource = dt.DefaultView;
                }
            }
            catch (Exception ex) { MessageBox.Show("שגיאה בטעינת חומרי גלם: " + ex.Message); }
        }

        // בחירת מוצר
        private void cmbProducts_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (cmbProducts.SelectedValue == null) return;
            int productId = (int)cmbProducts.SelectedValue;
            FindOrCreateRecipe(productId);
        }

        // מציאת או יצירת מתכון
        private void FindOrCreateRecipe(int productId)
        {
            try
            {
                using (var conn = DatabaseHelper.GetConnection())
                {
                    conn.Open();
                    string query = "SELECT recipe_id FROM recipe WHERE product_id = @pid ORDER BY version_no DESC LIMIT 1";

                    using (var cmd = new NpgsqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("pid", productId);
                        object result = cmd.ExecuteScalar();

                        if (result != null)
                        {
                            currentRecipeId = (int)result;
                            lblRecipeStatus.Text = "✅ עורך מתכון קיים";
                        }
                        else
                        {
                            string insertQuery = @"INSERT INTO recipe (product_id, version_no, created_date, yield_units) 
                                                   VALUES (@pid, 1.0, CURRENT_DATE, 10) RETURNING recipe_id";
                            using (var insertCmd = new NpgsqlCommand(insertQuery, conn))
                            {
                                insertCmd.Parameters.AddWithValue("pid", productId);
                                currentRecipeId = (int)insertCmd.ExecuteScalar();
                            }
                            lblRecipeStatus.Text = "✨ נוצר מתכון חדש (גרסה 1.0)";
                        }
                    }
                }
                LoadRecipeItems();
            }
            catch (Exception ex) { MessageBox.Show("שגיאה בניהול מתכון: " + ex.Message); }
        }

        // טעינת רשימת רכיבים
        private void LoadRecipeItems()
        {
            if (currentRecipeId == -1) return;

            try
            {
                using (var conn = DatabaseHelper.GetConnection())
                {
                    conn.Open();
                    string query = @"SELECT ri.recipe_id, ri.ingredient_id, i.name as ingredient_name, ri.quantity, ri.unit 
                                     FROM recipeitem ri
                                     JOIN ingredient i ON ri.ingredient_id = i.ingredient_id
                                     WHERE ri.recipe_id = @rid";

                    using (var cmd = new NpgsqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("rid", currentRecipeId);
                        NpgsqlDataAdapter da = new NpgsqlDataAdapter(cmd);
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        dgRecipeItems.ItemsSource = dt.DefaultView;
                    }
                }
            }
            catch (Exception ex) { MessageBox.Show("שגיאה בטעינת רכיבים: " + ex.Message); }
        }

        // הוספת רכיב
        private void btnAddIngredient_Click(object sender, RoutedEventArgs e)
        {
            if (currentRecipeId == -1) { MessageBox.Show("אנא בחר מוצר קודם"); return; }
            if (cmbIngredients.SelectedValue == null || string.IsNullOrWhiteSpace(txtQuantity.Text) || cmbUnit.SelectedItem == null)
            {
                MessageBox.Show("נא למלא את כל פרטי הרכיב");
                return;
            }

            try
            {
                int ingredientId = (int)cmbIngredients.SelectedValue;
                decimal quantity = decimal.Parse(txtQuantity.Text);
                string unit = (cmbUnit.SelectedItem as ComboBoxItem).Content.ToString();

                using (var conn = DatabaseHelper.GetConnection())
                {
                    conn.Open();
                    string query = "INSERT INTO recipeitem (recipe_id, ingredient_id, quantity, unit) VALUES (@rid, @iid, @qty, @u)";
                    using (var cmd = new NpgsqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("rid", currentRecipeId);
                        cmd.Parameters.AddWithValue("iid", ingredientId);
                        cmd.Parameters.AddWithValue("qty", quantity);
                        cmd.Parameters.AddWithValue("u", unit);
                        cmd.ExecuteNonQuery();
                    }
                }
                LoadRecipeItems();
                txtQuantity.Clear();
                MessageBox.Show("הרכיב נוסף בהצלחה!");
            }
            catch (Exception ex) { MessageBox.Show("שגיאה (אולי הרכיב כבר קיים?): " + ex.Message); }
        }

        // הסרת רכיב
        private void btnRemove_Click(object sender, RoutedEventArgs e)
        {
            if (dgRecipeItems.SelectedItem == null) { MessageBox.Show("נא לבחור רכיב להסרה מהטבלה"); return; }

            DataRowView row = (DataRowView)dgRecipeItems.SelectedItem;
            int ingredientId = (int)row["ingredient_id"];

            try
            {
                using (var conn = DatabaseHelper.GetConnection())
                {
                    conn.Open();
                    string query = "DELETE FROM recipeitem WHERE recipe_id = @rid AND ingredient_id = @iid";
                    using (var cmd = new NpgsqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("rid", currentRecipeId);
                        cmd.Parameters.AddWithValue("iid", ingredientId);
                        cmd.ExecuteNonQuery();
                    }
                }
                LoadRecipeItems();
            }
            catch (Exception ex) { MessageBox.Show("שגיאה במחיקה: " + ex.Message); }
        }

        // --- הכפתור החדש לחזרה ---
        private void btnBack_Click(object sender, RoutedEventArgs e)
        {
            this.Close();
        }
    }
}
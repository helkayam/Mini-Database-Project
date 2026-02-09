using Npgsql;
using System;
using System.Data;
using System.Windows;
using System.Windows.Controls;

namespace BakeryManagementSystem
{
    public partial class ReportsWindow : Window
    {
        public ReportsWindow()
        {
            InitializeComponent();
        }

        // פונקציית עזר להרצת שאילתות - כדי לא לשכפל קוד
        private void RunReport(string query, string reportName)
        {
            try
            {
                using (var conn = DatabaseHelper.GetConnection())
                {
                    conn.Open();
                    NpgsqlDataAdapter da = new NpgsqlDataAdapter(query, conn);
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    if (dt.Rows.Count == 0)
                    {
                        MessageBox.Show("לא נמצאו נתונים עבור דוח זה.");
                    }

                    dgReports.ItemsSource = null; // איפוס
                    dgReports.ItemsSource = dt.DefaultView;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"שגיאה בהפקת דוח '{reportName}':\n" + ex.Message);
            }
        }

        // --- דוח 1: רווחיות משמרות ---
        private void btnReport1_Click(object sender, RoutedEventArgs e)
        {
            string query = @"
                SELECT
                    s.shift_id,
                    s.shift_date,
                    ROUND(COALESCE(r.total_revenue, 0), 2) AS total_revenue,
                    ROUND(COALESCE(l.total_labor_cost, 0), 2) AS total_labor_cost,
                    ROUND(COALESCE(r.total_revenue, 0) - COALESCE(l.total_labor_cost, 0), 2) AS profit
                FROM shift s
                LEFT JOIN (
                    SELECT pr.shift_id, SUM(pr.quantity_output * p.price) AS total_revenue
                    FROM production pr
                    JOIN product p ON p.product_id = pr.product_id
                    GROUP BY pr.shift_id
                ) r ON r.shift_id = s.shift_id
                LEFT JOIN (
                    SELECT a.work_date, SUM(a.hours_worked * j.base_salary) AS total_labor_cost
                    FROM attendance a
                    JOIN employees e ON e.employee_id = a.employee_id
                    JOIN jobs j ON j.job_id = e.job_id
                    GROUP BY a.work_date
                ) l ON l.work_date = s.shift_date
                ORDER BY s.shift_date DESC;";

            RunReport(query, "רווחיות משמרות");
        }

        // --- דוח 2: בונוסים ועובדים מצטיינים ---
        private void btnReport2_Click(object sender, RoutedEventArgs e)
        {
            string query = @"
                SELECT
                    e.employee_id,
                    e.first_name,
                    e.last_name,
                    b.total_bonus_this_year,
                    COALESCE(lead_prod.led_output, 0) AS led_output_this_year,
                    COALESCE(asg_prod.assigned_output, 0) AS assigned_output_this_year
                FROM employees e
                JOIN (
                    SELECT employee_id, SUM(bonus) AS total_bonus_this_year
                    FROM salaries
                    WHERE EXTRACT(YEAR FROM pay_date) = EXTRACT(YEAR FROM CURRENT_DATE)
                    GROUP BY employee_id
                ) b ON b.employee_id = e.employee_id
                LEFT JOIN (
                    SELECT leader_employee_id AS employee_id, SUM(quantity_output) AS led_output
                    FROM production
                    WHERE EXTRACT(YEAR FROM bake_date) = EXTRACT(YEAR FROM CURRENT_DATE)
                    GROUP BY leader_employee_id
                ) lead_prod ON lead_prod.employee_id = e.employee_id
                LEFT JOIN (
                    SELECT a.employee_id, SUM(pr.quantity_output) AS assigned_output
                    FROM assignment a
                    JOIN production pr ON pr.shift_id = a.shift_id AND pr.station_id = a.station_id
                    WHERE EXTRACT(YEAR FROM pr.bake_date) = EXTRACT(YEAR FROM CURRENT_DATE)
                    GROUP BY a.employee_id
                ) asg_prod ON asg_prod.employee_id = e.employee_id
                ORDER BY b.total_bonus_this_year DESC
                LIMIT 3;";

            RunReport(query, "עובדים מצטיינים");
        }

        // --- דוח 3: סטטוס מלאי ושימוש ---
        private void btnReport3_Click(object sender, RoutedEventArgs e)
        {
            string query = @"
                SELECT 
                    IU.ingredient_name,
                    ROUND(IU.used_amount, 2) AS used_amount,
                    COALESCE(ISK.total_quantity, 0) AS total_quantity,
                    ROUND(COALESCE(ISK.total_quantity, 0) - IU.used_amount, 2) AS remaining_quantity,
                    CASE 
                        WHEN (COALESCE(ISK.total_quantity, 0) - IU.used_amount) < 0 THEN 'חסר במלאי!'
                        WHEN (COALESCE(ISK.total_quantity, 0) - IU.used_amount) < 100 THEN 'מלאי נמוך'
                        ELSE 'תקין'
                    END AS inventory_status
                FROM (
                    SELECT 
                        ri.ingredient_id,
                        i.name AS ingredient_name,
                        SUM(ri.quantity * p.quantity_output) AS used_amount
                    FROM Production p
                    JOIN RecipeItem ri ON p.recipe_id = ri.recipe_id
                    JOIN Ingredient i ON ri.ingredient_id = i.ingredient_id
                    GROUP BY ri.ingredient_id, i.name
                ) AS IU
                LEFT JOIN (
                    SELECT ingredient_id, SUM(quantity_current) AS total_quantity
                    FROM Batch
                    GROUP BY ingredient_id
                ) AS ISK ON IU.ingredient_id = ISK.ingredient_id
                ORDER BY remaining_quantity ASC;";

            RunReport(query, "סטטוס מלאי");
        }

        // --- דוח 4: מה לייצר (תוקף קרוב) ---
        private void btnReport4_Click(object sender, RoutedEventArgs e)
        {
            string query = @"
                WITH lastVersionRecipeProduct AS (
                    SELECT DISTINCT ON (product_id)
                        product_id, recipe_id, version_no, yield_units
                    FROM Recipe
                    ORDER BY product_id, version_no DESC
                )
                SELECT 
                    p.name as product_name,
                    ing.name as ingredient_name,
                    MIN(b.expiry_date) AS earliest_expiry,
                    MIN(b.expiry_date) - CURRENT_DATE AS soonest_expiration_days,
                    FLOOR(SUM(ROUND(b.quantity_current / ri.quantity) * r.yield_units)) AS estimated_product_units_to_save
                FROM Batch b
                JOIN Ingredient ing ON b.ingredient_id = ing.ingredient_id
                JOIN RecipeItem ri ON ri.ingredient_id = ing.ingredient_id
                JOIN lastVersionRecipeProduct r ON r.recipe_id = ri.recipe_id
                JOIN Product p ON r.product_id = p.product_id
                WHERE b.expiry_date <= CURRENT_DATE + 30 
                  AND b.expiry_date > CURRENT_DATE 
                  AND b.quantity_current > 0
                GROUP BY p.product_id, p.name, ing.name
                ORDER BY soonest_expiration_days ASC, estimated_product_units_to_save DESC;";

            RunReport(query, "תוקף קרוב");
        }

        // --- עיצוב ושינוי שמות עמודות אוטומטי ---
        private void dgReports_AutoGeneratingColumn(object sender, DataGridAutoGeneratingColumnEventArgs e)
        {
            // עיצוב תאריכים
            if (e.PropertyType == typeof(DateTime) || e.PropertyType == typeof(DateTime?))
            {
                (e.Column as DataGridTextColumn).Binding.StringFormat = "dd/MM/yyyy";
            }
            // עיצוב מספרים עשרוניים וכסף
            if (e.PropertyType == typeof(decimal) || e.PropertyType == typeof(double))
            {
                // אם העמודה קשורה לכסף, נשים סימן ש"ח, אחרת רק 2 ספרות
                if (e.PropertyName.Contains("revenue") || e.PropertyName.Contains("cost") || e.PropertyName.Contains("profit") || e.PropertyName.Contains("bonus"))
                    (e.Column as DataGridTextColumn).Binding.StringFormat = "C2";
                else
                    (e.Column as DataGridTextColumn).Binding.StringFormat = "N2";
            }

            // תרגום כותרות לעברית
            switch (e.PropertyName)
            {
                case "shift_id": e.Column.Header = "מס' משמרת"; break;
                case "shift_date": e.Column.Header = "תאריך"; break;
                case "total_revenue": e.Column.Header = "הכנסות"; break;
                case "total_labor_cost": e.Column.Header = "עלות עבודה"; break;
                case "profit": e.Column.Header = "רווח נקי"; break;

                case "employee_id": e.Column.Header = "מזהה עובד"; break;
                case "first_name": e.Column.Header = "שם פרטי"; break;
                case "last_name": e.Column.Header = "שם משפחה"; break;
                case "total_bonus_this_year": e.Column.Header = "בונוס שנתי"; break;
                case "led_output_this_year": e.Column.Header = "תפוקה (הובלה)"; break;
                case "assigned_output_this_year": e.Column.Header = "תפוקה (עובד)"; break;

                case "ingredient_name": e.Column.Header = "חומר גלם"; break;
                case "used_amount": e.Column.Header = "כמות בשימוש"; break;
                case "total_quantity": e.Column.Header = "סך במלאי"; break;
                case "remaining_quantity": e.Column.Header = "נותר במלאי"; break;
                case "inventory_status": e.Column.Header = "סטטוס"; break;

                case "product_name": e.Column.Header = "מוצר לייצור"; break;
                case "earliest_expiry": e.Column.Header = "תאריך תוקף"; break;
                case "soonest_expiration_days": e.Column.Header = "ימים לפג תוקף"; break;
                case "estimated_product_units_to_save": e.Column.Header = "מס' יחידות מהמוצר"; break;
            }
        }

        private void btnBack_Click(object sender, RoutedEventArgs e)
        {
            this.Close();
        }
    }
}

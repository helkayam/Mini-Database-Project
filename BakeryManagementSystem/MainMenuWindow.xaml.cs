using System.Data;
using System.Windows;

namespace BakeryManagementSystem
{
    public partial class MainMenuWindow : Window
    {
        public MainMenuWindow()
        {
            InitializeComponent(); // הפקודה הזו טוענת את העיצוב מה-XAML
        }
        private void btnInventory_Click(object sender, RoutedEventArgs e)
        {
            InventoryWindow inv = new InventoryWindow();
            inv.ShowDialog(); // פותח את החלון ומונע חזרה לראשי עד שסוגרים
        }

        private void btnProducts_Click(object sender, RoutedEventArgs e)
        {
            ProductsWindow win = new ProductsWindow();
            win.ShowDialog();
        }

        private void btnRecipes_Click(object sender, RoutedEventArgs e)
        {
            RecipesWindow win = new RecipesWindow();
            win.ShowDialog();
        }

        private void btnReports_Click(object sender, RoutedEventArgs e)
        {
            ReportsWindow reportWin = new ReportsWindow();
            reportWin.ShowDialog();
        }

        private void btnExit_Click(object sender, RoutedEventArgs e)
        {
            // חזרה למסך הכניסה
            MainWindow login = new MainWindow();
            login.Show();
            this.Close();
        }
    }
}

USE bakery;

/* =====================================================
   UPDATE – 3 שאילתות עדכון
   ===================================================== */

---------------------------------------------------------
-- אם חופשה אושרה והיום נמצא בתוך הטווח החופשה מוגדרת כחופשה בפועל 
---------------------------------------------------------
SET SQL_SAFE_UPDATES = 0; #בשביל שהשאילתה תעבוד נריץ את זה


UPDATE Leaves
SET status = 'Ongoing'
WHERE status = 'Approved'
  AND CURDATE() BETWEEN start_date AND end_date;

SET SQL_SAFE_UPDATES = 1; #נבטל בסוף ונחזיר למצב בטוח


---------------------------------------------------------
-- השאילתה מעדכנת את מנהל כל מחלקה בהתאם לעובד הוותיק ביותר והפעיל במחלקה.
---------------------------------------------------------
SET SQL_SAFE_UPDATES = 0; #בשביל שהשאילתה תעבוד נריץ את זה

UPDATE Departments d
JOIN (
    SELECT 
        department_id,
        MIN(hire_date) AS first_hire
        # מוצאים את תאריך ההעסקה הכי מוקדם (הוותיק ביותר)
    FROM Employees
    WHERE department_id IS NOT NULL
      AND status = 'Active'   # רק עובדים פעילים נחשבים למועמדים לניהול
    GROUP BY department_id    # לכל מחלקה מחזירים תאריך קליטה ראשון
) AS x                            
    ON d.department_id = x.department_id    # מצרפים את המחלקות לנתוני תאריך הקליטה הראשון של כל מחלקה
JOIN Employees e 
    ON e.department_id = d.department_id   # מצרפים שוב לטבלת העובדים כדי למצוא מי העובד במחלקה הזו
   AND e.hire_date = x.first_hire  # העובד שהתקבל בתאריך ההעסקה המוקדם ביותר
   AND e.status = 'Active'   # לוודא שוב שהעובד פעיל (לא Inactive)
SET d.manager_id = e.employee_id; # מגדירים את העובד הוותיק והפעיל ביותר בתור מנהל המחלקה


SET SQL_SAFE_UPDATES = 1; #נבטל בסוף ונחזיר למצב בטוח

---------------------------------------------------------
-- הוספה של 250 שקל למשכורת הסופית לכל מי שהיא אישה
---------------------------------------------------------
SET SQL_SAFE_UPDATES = 0; #בשביל שהשאילתה תעבוד נריץ את זה

UPDATE Salaries s
JOIN Employees e ON s.employee_id = e.employee_id
SET 
    s.total_salary = s.total_salary + 250
WHERE e.gender = 'Female';

SET SQL_SAFE_UPDATES = 1; #נבטל בסוף ונחזיר למצב בטוח

#עוזר לבדיקה של לפני ואחרי לראות שהתעדכן
SELECT 
    s.employee_id,
    e.first_name,
    e.last_name,
    e.gender,
    s.bonus,
    s.total_salary
FROM Salaries s
JOIN Employees e ON s.employee_id = e.employee_id
WHERE e.gender = 'Female';

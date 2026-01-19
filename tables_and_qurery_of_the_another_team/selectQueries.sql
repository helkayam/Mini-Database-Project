USE bakery;

---------------------------------------------------------
-- 1) השאילתה מציגה רשימת עובדים מלאה הכוללת פרטי עובד, שם המחלקה ושם התפקיד שלו.
---------------------------------------------------------
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    d.department_name,
    j.job_title,
    e.hire_date
FROM Employees e
JOIN Departments d ON e.department_id = d.department_id
JOIN Jobs j        ON e.job_id = j.job_id
ORDER BY d.department_name, e.last_name, e.first_name;


---------------------------------------------------------
-- 2) השאילתה מחזירה דוח כספי חודשי לכל מחלקה בארגון.
---------------------------------------------------------
SELECT 
    d.department_name,
    YEAR(s.pay_date)  AS pay_year, #מוציא את השנה לפי תאריך התשלום
    MONTH(s.pay_date) AS pay_month, #מוציא את החודש לפי תאריך התשלום
    COUNT(DISTINCT e.employee_id) AS num_employees_paid, #סופר כמה עובדים שונים קיבלו שכר באותו מחלקה ובאותו החודש
    SUM(s.total_salary)          AS total_payroll, #סוכם את השכר עבור כל העובדים באותו המחלקה ובאותו החודש
    AVG(s.total_salary)          AS avg_salary #מחשב את ממוצע השכר עבור כל העובדים באותה מחלקה ובאותו החודש
FROM Salaries s
JOIN Employees e ON s.employee_id = e.employee_id #שירשור בין 3 טבלאות
JOIN Departments d ON e.department_id = d.department_id
GROUP BY d.department_name, pay_year, pay_month #איחוד המחלקות לפי שנה, מחלקה וחודש
ORDER BY pay_year DESC, pay_month DESC, total_payroll DESC; #מיון לפי הסדר שכתוב


--Post-integration optimized query 
--2)
SELECT 
    d.department_name,
    EXTRACT(YEAR  FROM s.pay_date)  AS pay_year,
    EXTRACT(MONTH FROM s.pay_date)  AS pay_month,
    COUNT(DISTINCT e.employee_id)   AS num_employees_paid, 
    SUM(s.total_salary)             AS total_payroll,
    AVG(s.total_salary)             AS avg_salary 
FROM salaries s
JOIN employees e   ON s.employee_id = e.employee_id
JOIN departments d ON e.department_id = d.department_id
GROUP BY 
    d.department_name,
    pay_year,
    pay_month
ORDER BY 
    pay_year DESC,
    pay_month DESC,
    total_payroll DESC;

---------------------------------------------------------
-- 3)  .מי עושה שעות נוספות? שעות עבודה יומיות לעובד, מי עושה מעל 8 שעות

---------------------------------------------------------
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    YEAR(a.work_date)  AS work_year,
    MONTH(a.work_date) AS work_month,
    SUM(a.hours_worked) AS total_hours
FROM Employees e
JOIN Attendance a ON e.employee_id = a.employee_id
GROUP BY e.employee_id, full_name, work_year, work_month
HAVING total_hours > 8
ORDER BY total_hours DESC;

--Post-integration optimized query
--3)
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    EXTRACT(YEAR  FROM a.work_date)  AS work_year,
    EXTRACT(MONTH FROM a.work_date)  AS work_month,
    SUM(a.hours_worked)              AS total_hours
FROM employees e
JOIN attendance a 
    ON e.employee_id = a.employee_id
GROUP BY 
    e.employee_id,
    full_name,
    work_year,
    work_month
HAVING 
    SUM(a.hours_worked) > 8
ORDER BY 
    total_hours DESC;


---------------------------------------------------------
-- 4) SELECT – עובדים שנמצאים כרגע בחופשה מאושרת
---------------------------------------------------------
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    l.leave_type,
    l.start_date,
    l.end_date,
    l.status
FROM Leaves l
JOIN Employees e ON l.employee_id = e.employee_id
WHERE l.status = 'Approved'
  AND CURDATE() BETWEEN l.start_date AND l.end_date; # בדיקה מי נמצא בחופשה בתאריך הזה


---Post-integration optimized query
--4)
'''
The query “Employees currently on approved leave” returned empty, since the data provided does not contain any approved leaves whose end date covers the current date in the system.
For demonstration purposes, an alternative query was performed based on the date ranges available in the data.
'''
WITH max_dates AS (
  SELECT MAX(end_date) AS max_end
  FROM public.leaves
  WHERE status = 'Approved'
)
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    l.leave_type,
    l.start_date,
    l.end_date,
    l.status
FROM public.leaves l
JOIN public.employees e
  ON l.employee_id = e.employee_id
CROSS JOIN max_dates
WHERE l.status = 'Approved'
  AND l.end_date >= max_dates.max_end - INTERVAL '30 days'
ORDER BY l.end_date DESC;






---------------------------------------------------------
-- 5)  עובדים שמעולם לא קיבלו בונוס 
---------------------------------------------------------
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    e.status
FROM Employees e
WHERE NOT EXISTS ( #תחזיר את מי שלא מתקיים עבורו התנאי
    SELECT 1 #בדיקה האם יש תוצאה או אין
    FROM Salaries s
    WHERE s.employee_id = e.employee_id
      AND s.bonus > 0 #עבור כל עובד בטבלת שכר נבדוק האם יש לו בונוס גדול מ-0
);


---------------------------------------------------------
-- 6) שלושת העובדים עם הבונוס המצטבר הכי גבוה השנה
---------------------------------------------------------
SELECT 
    e.employee_id, #שדה של תעודת זהות של העובד
    CONCAT(e.first_name, ' ', e.last_name) AS full_name, #מחבר שם פרטי עם שם משפחה ושם בעמודה חדשה
    SUM(s.bonus) AS total_bonus #סך הבונסים לעובד מסוים
FROM Employees e
JOIN Salaries s ON e.employee_id = s.employee_id #צירוף טבעי בין טבלת משכורות לטבלת עובדים
WHERE YEAR(s.pay_date) = YEAR(CURDATE()) #מסנן שורות לפי מי שתאריך התשלום שלו היה בשנה הנוכחית 
GROUP BY e.employee_id, full_name #מקבץ לפי תעודת זהות ושם מלא
ORDER BY total_bonus DESC #ממיין את העובדים לפי הבונוס מהגדול לקטן
LIMIT 3; #לוקח רק ה3 הראשונים

---Post-integration optimized query
--)
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    SUM(s.bonus) AS total_bonus
FROM employees e
JOIN salaries s 
    ON e.employee_id = s.employee_id
WHERE EXTRACT(YEAR FROM s.pay_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY e.employee_id, full_name
ORDER BY total_bonus DESC
LIMIT 3;

---------------------------------------------------------
-- 7) השאילתה מציגה דוח הכולל את כל המחלקות בארגון, את שם המנהל של כל מחלקה (באמצעות צירוף לטבלת Employees), ואת מספר העובדים השייכים לכל מחלקה.

---------------------------------------------------------
SELECT 
    d.department_id,
    d.department_name,
    d.manager_id,
    CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
    COUNT(e.employee_id) AS num_employees
FROM Departments d
LEFT JOIN Employees m ON d.manager_id = m.employee_id    -- המנהל
LEFT JOIN Employees e ON d.department_id = e.department_id  -- עובדי המחלקה
GROUP BY d.department_id, d.department_name, d.manager_id, manager_name
ORDER BY d.department_name;

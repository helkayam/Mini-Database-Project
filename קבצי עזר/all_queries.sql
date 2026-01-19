-- our queries

--complex level queries


--Post-integration optimized query
--1)
WITH above_prod AS (
  SELECT shift_id, station_id
  FROM public.production
  WHERE quantity_output > (SELECT AVG(quantity_output) FROM public.production)
)
SELECT DISTINCT e.first_name, e.last_name, e.role
FROM above_prod p
JOIN public.assignment a
  ON a.shift_id = p.shift_id
 AND a.station_id = p.station_id
JOIN public.employees e
  ON e.employee_id = a.employee_id;


-- 2) Inventory usage report
SELECT 
    IU.ingredient_id,
    IU.ingredient_name,
    IU.used_amount,
    ISK.total_quantity,
    (ISK.total_quantity - IU.used_amount) AS remaining_quantity
FROM (
    -- שימוש אמיתי בחומרי גלם לפי כל ההפקות
    SELECT 
        ri.ingredient_id,
        i.name AS ingredient_name,
        SUM(ri.quantity * p.quantity_output) AS used_amount
    FROM Production p
    JOIN RecipeItem ri
      ON p.recipe_id = ri.recipe_id
    JOIN Ingredient i
      ON ri.ingredient_id = i.ingredient_id
    GROUP BY ri.ingredient_id, i.name
) AS IU
LEFT JOIN (
    -- כמה יש במלאי מתוך באצ'ים
    SELECT 
        ingredient_id,
        SUM(quantity_current) AS total_quantity
    FROM Batch
    GROUP BY ingredient_id
) AS ISK
  ON IU.ingredient_id = ISK.ingredient_id
ORDER BY IU.used_amount DESC;


-- 3) Station revenue report
SELECT 
    s.station_id,s.name AS station_name,
    COALESCE(SUM(pr.quantity_output * p.price), 0) AS total_revenue
FROM Station s
LEFT JOIN Production pr
  ON pr.station_id = s.station_id
LEFT JOIN Product p
  ON pr.product_id = p.product_id
GROUP BY s.station_id, s.name
ORDER BY total_revenue DESC;



--Post-integration optimized query
--4)
SELECT 
    p.product_id,
    p.name AS product_name,
    p.price AS sell_price,
    ROUND(SUM(ri.quantity * i.cost_per_unit) / r.yield_units,2) AS cost_per_unit,
    ROUND(p.price - SUM(ri.quantity * i.cost_per_unit) / r.yield_units,2) AS profit_per_unit,
    ROUND(((p.price - SUM(ri.quantity * i.cost_per_unit) / r.yield_units) / p.price) * 100, 2)
      AS profit_margin_percent
FROM public.product p
JOIN public.recipe r 
  ON r.product_id = p.product_id
JOIN public.recipeitem ri 
  ON ri.recipe_id = r.recipe_id
JOIN public.ingredient i
  ON i.ingredient_id = ri.ingredient_id
GROUP BY p.product_id, p.name, p.price, r.yield_units
ORDER BY profit_per_unit DESC;



--5) Products that can be made from ingredients nearing expiration in the next 30 days

CREATE VIEW lastVersionRecipeProduct AS
SELECT DISTINCT ON (product_id)
	product_id, recipe_id, version_no,yield_units
FROM Recipe
ORDER BY product_id,version_no DESC;

SELECT p.product_id as product_id,
       p.name as product_name,
	   ing.name as integredient_name,
	   MIN(b.expiry_date) AS earliest_expiry,
	   MIN(b.expiry_date) - CURRENT_DATE AS soonest_expiration_days,
	   FLOOR(SUM(ROUND(b.quantity_current / ri.quantity)*r.yield_units)) AS estimated_product_units_to_save
FROM Batch b
JOIN Ingredient ing
ON b.ingredient_id=ing.ingredient_id
JOIN RecipeItem ri
ON ri.ingredient_id=ing.ingredient_id
JOIN lastVersionRecipeProduct r
ON r.recipe_id=ri.recipe_id
JOIN Product p
ON r.product_id=p.product_id
WHERE b.expiry_date<=CURRENT_DATE+30 and b.expiry_date>CURRENT_DATE and b.quantity_current>0
GROUP BY p.product_id,p.name,ing.name
ORDER BY
    soonest_expiration_days ASC,
    estimated_product_units_to_save DESC;



-- Intermediate level queries

-- 1) Top 10 busy stations
SELECT  
    s.station_id,
    s.name,
    SUM(p.quantity_output) AS total_amount_produced
FROM Station s
JOIN Production p
  ON s.station_id = p.station_id
GROUP BY s.station_id, s.name
ORDER BY total_amount_produced DESC
Limit 10;


--2)The average hourly output for each station id in each shift id
SELECT 
    st.station_id,
    s.shift_id,
    SUM(p.quantity_output) 
      / ABS(s.end_hour - s.start_hour) AS avg_output_per_hour
FROM public.production p
JOIN public.shift s
  ON p.shift_id = s.shift_id
JOIN public.station st
  ON p.station_id = st.station_id
GROUP BY 
    st.station_id,
    s.shift_id,
    s.start_hour,
    s.end_hour
ORDER BY st.station_id, s.shift_id;



-- 3) The total amount of output produced at each station,
-- broken down by the role of the worker who led the production batch.
SELECT
    s.name AS station_name,
    e.role AS leader_role,
    ROUND(SUM(p.quantity_output)) AS total_output_units
FROM 
    production p
JOIN 
    station s ON p.station_id = s.station_id
JOIN 
    employee e ON p.leader_employee_id = e.employee_id
GROUP BY
    s.name,
    e.role
ORDER BY
    s.name,
    total_output_units DESC;




             



-- their queries

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

---Post-integration optimized query
--6)
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


USE bakery;

---------------------------------------------------------
-- DELETE  מחיקת רשומות נוכחות ישנות של לפני שנה
---------------------------------------------------------
SET SQL_SAFE_UPDATES = 1; #בדיקה מה צריך להימחק

SELECT attendance_id, work_date
FROM Attendance
WHERE YEAR(work_date) = 2024;

SET SQL_SAFE_UPDATES = 0; #מחיקה

DELETE FROM Attendance
WHERE YEAR(work_date) = 2024;



---------------------------------------------------------
-- DELETE   מחיקת בקשות חופשה שנדחו לפני יותר משנה
---------------------------------------------------------
SET SQL_SAFE_UPDATES = 1; #בדיקה מה צריך להימחק

SELECT *
FROM Leaves
WHERE status = 'Rejected'
  AND end_date < DATE_SUB(CURDATE(), INTERVAL 1 YEAR);

SET SQL_SAFE_UPDATES = 0;#מחיקה

DELETE FROM Leaves
WHERE status   = 'Rejected'
  AND end_date < DATE_SUB(CURDATE(), INTERVAL 1 YEAR);




---------------------------------------------------------
-- DELETE  מחיקת משכורות של עובדים שמסומנים כ-"Fired"
---------------------------------------------------------
SELECT * #מחיקה מה צריך להימחק
FROM Salaries
WHERE employee_id IN (
    SELECT employee_id
    FROM Employees
    WHERE status = 'Fired'
);

DELETE FROM Salaries #מחיקה
WHERE employee_id IN (
    SELECT employee_id
    FROM Employees
    WHERE status = 'Fired'
);



--query on db after integration
'''
1) פער תכנון מול ביצוע (Assignment vs Attendance)

מי שובץ למשמרת אבל בפועל לא הגיע / הגיע חלקית (לפי date_work מול shift_date).
תועלת: בקרה על אי־התאמות, משמעת, ותכנון מחדש.

2) עלות שכר מול תפוקת ייצור לפי משמרת

לכל shift: סה״כ תפוקה (production.quantity_output) מול עלות שכר של העובדים שעבדו באותו יום (attendance.worked_hours × wage משוער/סלרי).
תועלת: רווחיות תפעולית לפי משמרת.


3) תפוקה לשעת עבודה לפי עובד (Productivity KPI)

תפוקה כוללת של משמרות בהן העובד השתתף / סה״כ שעות עבודה שלו באותם ימים.
תועלת: זיהוי מצטיינים/צווארי בקבוק.

4) איתור שעות נוספות + עומס משמרות

עובדים שעברו סף שעות בחודש (כמו אצלם), אבל עם חתך: באילו stations/shift_types זה קורה.
תועלת: ניהול עומסים ושחיקה.

5) “סיכון כשל תפעולי” לעמדות

Stations עם ייצור גבוה אבל עם הרבה חוסרים בנוכחות/החלפות עובדים (פערי assignment/attendance).
תועלת: זיהוי עמדות בעייתיות תפעולית.

6) בונוסים מבוססי ביצועים (Salaries bonus ↔ Production)

3 עובדים עם הכי הרבה בונוסים השנה (כמו אצלם) + להוסיף: מה הייתה התרומה שלהם לתפוקה (בהובלה או בשיבוץ להפקות).
תועלת: הצדקת תגמול מול תרומה.

7) “צוות מנצח” – קומבינציות עובדים שמביאות תפוקה גבוהה

מציאת זוגות/שלישיות עובדים שמופיעים יחד באותן משמרות/תחנות שמייצרות מעל הממוצע.
תועלת: אופטימיזציה לשיבוץ צוותים.

8) “מוצר בעייתי” – הרבה ייצור אבל רווחיות נמוכה + עלות עבודה גבוהה

מוצרים עם margin נמוך (מהשאילתה שלכם) ובנוסף דורשים הרבה שעות עבודה/חזרות על station עמוס.
תועלת: החלטה עסקית: לשפר מתכון / להעלות מחיר / להפסיק מוצר.
'''

-- 1) This query compares planned shift assignments with actual attendance to identify employees who either did not show up or worked fewer hours than scheduled.
SELECT
  a.assignment_id,
  e.employee_id,
  e.first_name,
  e.last_name,
  s.shift_id,
  s.shift_date,
  st.name AS station_name,
  a.task_name,  
  COALESCE(att.hours_worked, 0) AS actual_hours,
  CASE
    WHEN s.end_hour >= s.start_hour THEN (s.end_hour - s.start_hour)
    ELSE (24 - s.start_hour + s.end_hour)
  END AS planned_hours,
  CASE
    WHEN att.attendance_id IS NULL THEN 'NO_SHOW'
    WHEN COALESCE(att.hours_worked, 0) <
         CASE
           WHEN s.end_hour >= s.start_hour THEN (s.end_hour - s.start_hour)
           ELSE (24 - s.start_hour + s.end_hour)
         END
    THEN 'PARTIAL'
    ELSE 'FULL'
  END AS status
FROM assignment a
JOIN employees e ON e.employee_id = a.employee_id
JOIN shift s 
	ON s.shift_id = a.shift_id
JOIN station st
    ON st.station_id = a.station_id
LEFT JOIN attendance att
  ON att.shift_id = a.shift_id
 AND att.employee_id = a.employee_id
WHERE att.attendance_id IS NULL
   OR COALESCE(att.hours_worked, 0) <
      CASE
        WHEN s.end_hour >= s.start_hour THEN (s.end_hour - s.start_hour)
        ELSE (24 - s.start_hour + s.end_hour)
      END
ORDER BY s.shift_date DESC, e.last_name;









-- 2) עלות שכר מול תפוקת ייצור ורווח ייצור בכל משמרת
SELECT
    s.shift_id,
    s.shift_date,
    COALESCE(r.total_revenue, 0) AS total_revenue,
    COALESCE(l.total_labor_cost, 0) AS total_labor_cost,
    COALESCE(r.total_revenue, 0) - COALESCE(l.total_labor_cost, 0) AS profit
FROM shift s
LEFT JOIN (
    SELECT
        pr.shift_id,
        SUM(pr.quantity_output * p.price) AS total_revenue
    FROM production pr
    JOIN product p
        ON p.product_id = pr.product_id
    GROUP BY pr.shift_id
) r
    ON r.shift_id = s.shift_id
LEFT JOIN (
    SELECT
        a.shift_id,
        SUM(a.hours_worked * j.base_salary) AS total_labor_cost
    FROM attendance a
    JOIN employees e
        ON e.employee_id = a.employee_id
    JOIN jobs j
        ON j.job_id = e.job_id
    GROUP BY a.shift_id
) l
    ON l.shift_id = s.shift_id
WHERE COALESCE(l.total_labor_cost, 0) <> 0
ORDER BY s.shift_date, s.shift_id;

-- 3) תפוקה לשעת עבודה לפי עובד (Productivity KPI)
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    COALESCE(p.total_output, 0) AS total_output,
    COALESCE(h.total_hours, 0) AS total_hours,
    COALESCE(p.total_output, 0) / NULLIF(COALESCE(h.total_hours, 0), 0) AS output_per_hour
FROM employees e
LEFT JOIN (
    SELECT
        a.employee_id,
        SUM(pr.quantity_output) AS total_output
    FROM assignment ass
    JOIN shift s
        ON s.shift_id = ass.shift_id
    JOIN production pr
        ON pr.shift_id = s.shift_id
    JOIN attendance a
        ON a.employee_id = ass.employee_id
       AND a.work_date = s.shift_date
    GROUP BY a.employee_id
) p
    ON p.employee_id = e.employee_id
LEFT JOIN (
    SELECT
        employee_id,
        SUM(hours_worked) AS total_hours
    FROM attendance
    GROUP BY employee_id
) h
    ON h.employee_id = e.employee_id
ORDER BY output_per_hour DESC NULLS LAST;


--4)
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    m.work_month,
    st.station_id,
    st.name AS station_name,
    s.shift_type,
    SUM(att.hours_worked) AS hours_in_station_type,
    COUNT(*) AS shifts_count
FROM (
    SELECT
        employee_id,
        DATE_TRUNC('month', work_date) AS work_month
    FROM attendance
    GROUP BY employee_id, DATE_TRUNC('month', work_date)
    HAVING SUM(hours_worked) >= 180
) m
JOIN attendance att
    ON att.employee_id = m.employee_id
   AND DATE_TRUNC('month', att.work_date) = m.work_month
JOIN employees e
    ON e.employee_id = att.employee_id
JOIN assignment a
    ON a.employee_id = e.employee_id
JOIN shift s
    ON s.shift_id = a.shift_id
   AND s.shift_date = att.work_date
JOIN station st
    ON st.station_id = a.station_id
GROUP BY
    e.employee_id, e.first_name, e.last_name,
    m.work_month,
    st.station_id, st.name,
    s.shift_type
ORDER BY
    m.work_month DESC,
    e.last_name,
    hours_in_station_type DESC;


--5)
SELECT
    st.station_id,
    st.name AS station_name,
    COALESCE(p.total_output, 0) AS total_output,
    COALESCE(a.total_assignments, 0) AS total_assignments,
    COALESCE(a.missing_attendance, 0) AS missing_attendance
FROM station st
LEFT JOIN (
    SELECT station_id, SUM(quantity_output) AS total_output
    FROM production
    GROUP BY station_id
) p ON p.station_id = st.station_id
LEFT JOIN (
    SELECT
        a.station_id,
        COUNT(*) AS total_assignments,
        SUM(CASE WHEN att.employee_id IS NULL THEN 1 ELSE 0 END) AS missing_attendance
    FROM assignment a
    JOIN shift s ON s.shift_id = a.shift_id
    LEFT JOIN attendance att
      ON att.employee_id = a.employee_id
     AND att.work_date = s.shift_date
    GROUP BY a.station_id
) a ON a.station_id = st.station_id
ORDER BY total_output DESC, missing_attendance DESC;


--6)This query identifies the top three employees who received the highest total bonuses in the current year and presents their contribution to production output, both as production leaders and as assigned workers in production shifts.
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    b.total_bonus_this_year,
    COALESCE(lead_prod.led_output, 0) AS led_output_this_year,
    COALESCE(asg_prod.assigned_output, 0) AS assigned_output_this_year
FROM employees e
JOIN (
    -- סה"כ בונוסים השנה לכל עובד
    SELECT
        employee_id,
        SUM(bonus) AS total_bonus_this_year
    FROM salaries
    WHERE EXTRACT(YEAR FROM pay_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY employee_id
) b
    ON b.employee_id = e.employee_id
LEFT JOIN (
    -- תרומה כתפקיד מוביל: סה"כ תפוקה של הפקות שהעובד הוביל השנה
    SELECT
        leader_employee_id AS employee_id,
        SUM(quantity_output) AS led_output
    FROM production
    WHERE EXTRACT(YEAR FROM bake_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY leader_employee_id
) lead_prod
    ON lead_prod.employee_id = e.employee_id
LEFT JOIN (
    -- תרומה דרך שיבוץ: סה"כ תפוקה בהפקות שהעובד שובץ אליהן (אותו shift + station) השנה
    SELECT
        a.employee_id,
        SUM(pr.quantity_output) AS assigned_output
    FROM assignment a
    JOIN production pr
        ON pr.shift_id = a.shift_id
       AND pr.station_id = a.station_id
    WHERE EXTRACT(YEAR FROM pr.bake_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY a.employee_id
) asg_prod
    ON asg_prod.employee_id = e.employee_id
ORDER BY b.total_bonus_this_year DESC
LIMIT 3;







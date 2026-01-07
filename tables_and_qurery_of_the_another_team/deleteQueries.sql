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
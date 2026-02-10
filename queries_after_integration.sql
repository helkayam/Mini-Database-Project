
-- 1) This query compares planned shift assignments with actual attendance to identify employees who either did not show up or worked fewer hours than scheduled.
WITH ShiftHours AS (
    -- חישוב שעות מתוכננות פעם אחת כדי לא לחזור על הקוד
    SELECT 
        shift_id,
        shift_date,
        CASE 
            WHEN end_hour >= start_hour THEN (end_hour - start_hour)
            ELSE (24 - start_hour + end_hour)
        END AS planned_hours
    FROM shift
)
SELECT
    a.assignment_id,
    e.first_name,
    e.last_name,
    sh.shift_date,
    st.name AS station_name,
    a.task_name,   
    COALESCE(att.hours_worked, 0) AS actual_hours,
    sh.planned_hours,
    -- הסטטוס עכשיו הרבה יותר קריא
    CASE
        WHEN att.attendance_id IS NULL THEN 'NO_SHOW'
        WHEN COALESCE(att.hours_worked, 0) < sh.planned_hours THEN 'PARTIAL'
        ELSE 'FULL'
    END AS status
FROM assignment a
JOIN employees e ON e.employee_id = a.employee_id
JOIN station st ON st.station_id = a.station_id
JOIN ShiftHours sh ON sh.shift_id = a.shift_id -- חיבור לחישוב השעות שעשינו למעלה
LEFT JOIN attendance att ON att.shift_id = a.shift_id AND att.employee_id = a.employee_id
-- סינון של אלו שלא עבדו מספיק או לא הגיעו
WHERE att.attendance_id IS NULL 
   OR COALESCE(att.hours_worked, 0) < sh.planned_hours
ORDER BY sh.shift_date DESC, e.last_name;








-- 2)The query produces a per-shift profitability summary, showing each shift’s date alongside its total revenue, total labor cost, and net profit
-- to clearly indicate which sצhifts were profitable and by how much.
SELECT
    s.shift_id,
    s.shift_date,
    ROUND(COALESCE(r.total_revenue, 0), 2) AS total_revenue,
    ROUND(COALESCE(l.total_labor_cost, 0), 2) AS total_labor_cost,
    ROUND(COALESCE(r.total_revenue, 0) - COALESCE(l.total_labor_cost, 0), 2) AS profit
FROM shift s
LEFT JOIN (
    -- הכנסות לפי משמרת
    SELECT
        pr.shift_id,
        SUM(pr.quantity_output * p.price) AS total_revenue
    FROM production pr
    JOIN product p ON p.product_id = pr.product_id
    GROUP BY pr.shift_id
) r ON r.shift_id = s.shift_id
LEFT JOIN (
    -- עלות עבודה לפי משמרת (מתוקן מ-work_date ל-shift_id)
    SELECT
        a.shift_id,
        SUM(a.hours_worked * j.base_salary) AS total_labor_cost
    FROM attendance a
    JOIN employees e ON e.employee_id = a.employee_id
    JOIN jobs j ON j.job_id = e.job_id
    GROUP BY a.shift_id
) l ON l.shift_id = s.shift_id
ORDER BY s.shift_date, s.shift_id;

-- 3) The query outputs an employee productivity ranking, presenting each employee’s total production, total worked hours, and calculated output per hour,
-- making it easy to identify the most and least efficient workers.
WITH ShiftHeadcount AS (
    -- חישוב כמה עובדים היו בכל משמרת
    SELECT shift_id, COUNT(employee_id) as staff_count
    FROM assignment
    GROUP BY shift_id
),
EmployeeOutput AS (
    -- חלוקת ייצור המשמרת במספר העובדים שהיו בה
    SELECT 
        a.employee_id,
        SUM(p.quantity_output / NULLIF(sh.staff_count, 0)) AS distributed_output
    FROM assignment a
    JOIN production p ON a.shift_id = p.shift_id
    JOIN ShiftHeadcount sh ON a.shift_id = sh.shift_id
    GROUP BY a.employee_id
)
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.role,
    ROUND(COALESCE(eo.distributed_output, 0), 2) AS total_output,
    COALESCE(h.total_hours, 0) AS total_hours,
    ROUND(COALESCE(eo.distributed_output, 0) / NULLIF(COALESCE(h.total_hours, 0), 0), 2) AS output_per_hour
FROM employees e
LEFT JOIN EmployeeOutput eo ON e.employee_id = eo.employee_id
LEFT JOIN (
    SELECT employee_id, SUM(hours_worked) AS total_hours
    FROM attendance
    GROUP BY employee_id
) h ON h.employee_id = e.employee_id
ORDER BY output_per_hour DESC;


--4)
--The query shows, for each month, which employees worked a lot (180+ hours) and breaks down their work by station and shift type, 
--including total hours and number of shifts—so you can quickly see where their time was spent.
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
--The query Shows each station’s production output, number of assignments, and missing attendance, highlighting productivity and staffing issues.
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


--6)This query identifies the top three employees who received the highest total bonuses in the current year and 
--presents their contribution to production output, both as production leaders and as assigned workers in production shifts.
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
BEGIN;

-- 1) בדיקה לפני (כמה מושפעים)
SELECT COUNT(*) AS will_be_ongoing
FROM public.leaves
WHERE status = 'Approved'
  AND CURRENT_DATE BETWEEN start_date AND end_date;

-- 1) ה-UPDATE עצמו
UPDATE public.leaves
SET status = 'Ongoing'
WHERE status = 'Approved'
  AND CURRENT_DATE BETWEEN start_date AND end_date;

-- 1) בדיקה אחרי
SELECT COUNT(*) AS now_ongoing
FROM public.leaves
WHERE status = 'Ongoing'
  AND CURRENT_DATE BETWEEN start_date AND end_date;

ROLLBACK;

BEGIN;

-- מי המנהל "אמור" להיות לכל מחלקה (לפי הכלל)
WITH first_hire AS (
  SELECT department_id, MIN(hire_date) AS first_hire
  FROM public.employees
  WHERE department_id IS NOT NULL AND status = 'Active'
  GROUP BY department_id
),
candidate AS (
  SELECT e.department_id, e.employee_id AS new_manager_id
  FROM public.employees e
  JOIN first_hire f
    ON f.department_id = e.department_id
   AND f.first_hire = e.hire_date
  WHERE e.status = 'Active'
)
SELECT d.department_id, d.manager_id AS current_manager, c.new_manager_id
FROM public.departments d
JOIN candidate c ON c.department_id = d.department_id
WHERE d.manager_id IS DISTINCT FROM c.new_manager_id;

-- ה-UPDATE בפועל (אבל בתוך טרנזקציה)
WITH first_hire AS (
  SELECT department_id, MIN(hire_date) AS first_hire
  FROM public.employees
  WHERE department_id IS NOT NULL AND status = 'Active'
  GROUP BY department_id
),
candidate AS (
  SELECT e.department_id, e.employee_id AS new_manager_id
  FROM public.employees e
  JOIN first_hire f
    ON f.department_id = e.department_id
   AND f.first_hire = e.hire_date
  WHERE e.status = 'Active'
)
UPDATE public.departments d
SET manager_id = c.new_manager_id
FROM candidate c
WHERE d.department_id = c.department_id;

-- כמה מחלקות עוד שונות אחרי ה-UPDATE (אמור להיות 0)
WITH first_hire AS (
  SELECT department_id, MIN(hire_date) AS first_hire
  FROM public.employees
  WHERE department_id IS NOT NULL AND status = 'Active'
  GROUP BY department_id
),
candidate AS (
  SELECT e.department_id, e.employee_id AS new_manager_id
  FROM public.employees e
  JOIN first_hire f
    ON f.department_id = e.department_id
   AND f.first_hire = e.hire_date
  WHERE e.status = 'Active'
)
SELECT COUNT(*) AS still_different
FROM public.departments d
JOIN candidate c ON c.department_id = d.department_id
WHERE d.manager_id IS DISTINCT FROM c.new_manager_id;

ROLLBACK;




BEGIN;

SELECT COUNT(*) AS rows_to_update
FROM public.salaries s
JOIN public.employees e ON e.employee_id = s.employee_id
WHERE e.gender = 'Female';

UPDATE public.salaries s
SET total_salary = total_salary + 250
FROM public.employees e
WHERE e.employee_id = s.employee_id
  AND e.gender = 'Female';

-- בדיקה "אחרי" בתוך הטרנזקציה (רואים שהמספרים השתנו)
SELECT s.employee_id, e.first_name, e.last_name, e.gender, s.bonus, s.total_salary
FROM public.salaries s
JOIN public.employees e ON e.employee_id = s.employee_id
WHERE e.gender = 'Female'
ORDER BY s.employee_id
LIMIT 10;

ROLLBACK;




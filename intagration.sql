INSERT INTO public.employees(
  first_name, last_name,
  id_number, birth_date, gender, phone, email, address, hire_date,
  job_id, department_id, status,
  role
)
SELECT
  first_name, last_name,
  id_number, birth_date, gender, phone, email, address, hire_date,
  job_id, department_id, status,
  NULL
FROM public.employees_hr;

SELECT COUNT(*) FROM public.employees;

INSERT INTO public.employees(first_name, last_name, role)
SELECT e.first_name, e.last_name, e.role
FROM public.employee e
WHERE NOT EXISTS (
  SELECT 1
  FROM public.employees u
  WHERE u.first_name = e.first_name
    AND u.last_name  = e.last_name
);

DROP TABLE IF EXISTS public.hr_employee_map;
CREATE TABLE public.hr_employee_map (
  old_employee_id INTEGER PRIMARY KEY,
  new_employee_id INTEGER NOT NULL UNIQUE
);

INSERT INTO public.hr_employee_map(old_employee_id, new_employee_id)
SELECT hr.employee_id, u.employee_id
FROM public.employees_hr hr
JOIN public.employees u
  ON u.id_number = hr.id_number;

SELECT
  (SELECT COUNT(*) FROM public.employees_hr) AS hr_count,
  (SELECT COUNT(*) FROM public.hr_employee_map) AS mapped_count;

ALTER TABLE public.salaries
ADD COLUMN IF NOT EXISTS employee_id_new INTEGER;

UPDATE public.salaries s
SET employee_id_new = m.new_employee_id
FROM public.hr_employee_map m
WHERE s.employee_id = m.old_employee_id;

ALTER TABLE public.salaries
ADD CONSTRAINT fk_sal_emp_new
FOREIGN KEY (employee_id_new) REFERENCES public.employees(employee_id);


ALTER TABLE public.attendance
ADD COLUMN IF NOT EXISTS employee_id_new INTEGER;

UPDATE public.attendance a
SET employee_id_new = m.new_employee_id
FROM public.hr_employee_map m
WHERE a.employee_id = m.old_employee_id;

ALTER TABLE public.attendance
ADD CONSTRAINT fk_att_emp_new
FOREIGN KEY (employee_id_new) REFERENCES public.employees(employee_id);



ALTER TABLE public.leaves
ADD COLUMN IF NOT EXISTS employee_id_new INTEGER;

UPDATE public.leaves l
SET employee_id_new = m.new_employee_id
FROM public.hr_employee_map m
WHERE l.employee_id = m.old_employee_id;

ALTER TABLE public.leaves
ADD CONSTRAINT fk_leave_emp_new
FOREIGN KEY (employee_id_new) REFERENCES public.employees(employee_id);


ALTER TABLE public.departments
ADD COLUMN IF NOT EXISTS manager_id_new INTEGER;

UPDATE public.departments d
SET manager_id_new = m.new_employee_id
FROM public.hr_employee_map m
WHERE d.manager_id = m.old_employee_id;

ALTER TABLE public.departments
ADD CONSTRAINT fk_department_manager_new
FOREIGN KEY (manager_id_new) REFERENCES public.employees(employee_id);


-- Salaries -> employees
ALTER TABLE public.salaries
ADD COLUMN IF NOT EXISTS employee_id_new INTEGER;

UPDATE public.salaries s
SET employee_id_new = m.new_employee_id
FROM public.hr_employee_map m
WHERE s.employee_id = m.old_employee_id;


-- Attendance -> employees
ALTER TABLE public.attendance
ADD COLUMN IF NOT EXISTS employee_id_new INTEGER;

UPDATE public.attendance a
SET employee_id_new = m.new_employee_id
FROM public.hr_employee_map m
WHERE a.employee_id = m.old_employee_id;


-- Leaves -> employees
ALTER TABLE public.leaves
ADD COLUMN IF NOT EXISTS employee_id_new INTEGER;

UPDATE public.leaves l
SET employee_id_new = m.new_employee_id
FROM public.hr_employee_map m
WHERE l.employee_id = m.old_employee_id;


-- Departments.manager_id -> employees
ALTER TABLE public.departments
ADD COLUMN IF NOT EXISTS manager_id_new INTEGER;

UPDATE public.departments d
SET manager_id_new = m.new_employee_id
FROM public.hr_employee_map m
WHERE d.manager_id = m.old_employee_id;


-- salaries.employee_id_new חייב להצביע לעובד קיים ב-employees
SELECT COUNT(*) AS orphan_salaries_new
FROM public.salaries s
LEFT JOIN public.employees e ON e.employee_id = s.employee_id_new
WHERE e.employee_id IS NULL;

-- attendance.employee_id_new חייב להצביע לעובד קיים ב-employees
SELECT COUNT(*) AS orphan_attendance_new
FROM public.attendance a
LEFT JOIN public.employees e ON e.employee_id = a.employee_id_new
WHERE e.employee_id IS NULL;

-- leaves.employee_id_new חייב להצביע לעובד קיים ב-employees
SELECT COUNT(*) AS orphan_leaves_new
FROM public.leaves l
LEFT JOIN public.employees e ON e.employee_id = l.employee_id_new
WHERE e.employee_id IS NULL;

-- departments.manager_id_new חייב להצביע לעובד קיים ב-employees (רק אם יש manager_id)
SELECT COUNT(*) AS orphan_dept_manager_new
FROM public.departments d
LEFT JOIN public.employees e ON e.employee_id = d.manager_id_new
WHERE d.manager_id IS NOT NULL AND e.employee_id IS NULL;



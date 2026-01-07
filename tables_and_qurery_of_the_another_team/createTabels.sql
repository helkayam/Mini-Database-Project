CREATE DATABASE IF NOT EXISTS bakery;
USE bakery;

---------------------------------------------------------
-- Departments
---------------------------------------------------------
CREATE TABLE Departments (
    department_id   INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(50),
    manager_id      INT NULL
);

---------------------------------------------------------
-- Jobs
---------------------------------------------------------
CREATE TABLE Jobs (
    job_id      INT AUTO_INCREMENT PRIMARY KEY,
    job_title   VARCHAR(50),
    base_salary DECIMAL(10,2),
    description TEXT
);

---------------------------------------------------------
-- Employees
---------------------------------------------------------
CREATE TABLE Employees (
    employee_id   INT AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(50),
    last_name     VARCHAR(50),
    id_number     VARCHAR(20),
    birth_date    DATE,
    gender        VARCHAR(10),
    phone         VARCHAR(15),
    email         VARCHAR(100),
    address       VARCHAR(100),
    hire_date     DATE,
    job_id        INT,
    department_id INT,
    status        VARCHAR(20),

    FOREIGN KEY (job_id)        REFERENCES Jobs(job_id),
    FOREIGN KEY (department_id) REFERENCES Departments(department_id)
);

---------------------------------------------------------
-- Salaries
---------------------------------------------------------
CREATE TABLE Salaries (
    salary_id    INT AUTO_INCREMENT PRIMARY KEY,
    employee_id  INT,
    base_salary  DECIMAL(10,2),
    bonus        DECIMAL(10,2) DEFAULT 0.00,
    pay_date     DATE,
    total_salary DECIMAL(10,2),

    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
);

---------------------------------------------------------
-- Attendance
---------------------------------------------------------
CREATE TABLE Attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id   INT,
    work_date     DATE,
    check_in      TIME,
    check_out     TIME,
    hours_worked  DECIMAL(4,2),

    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
);

---------------------------------------------------------
-- Leaves
---------------------------------------------------------
CREATE TABLE Leaves (
    leave_id    INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,
    start_date  DATE,
    end_date    DATE,
    leave_type  VARCHAR(50),
    status      VARCHAR(20),

    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
);

---------------------------------------------------------
-- Add FK for Department Manager
---------------------------------------------------------
ALTER TABLE Departments
ADD CONSTRAINT fk_department_manager
    FOREIGN KEY (manager_id) REFERENCES Employees(employee_id);
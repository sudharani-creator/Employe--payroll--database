CREATE DATABASE IF NOT EXISTS employee_payroll_db;
USE employee_payroll_db;


-- 1. DEPARTMENTS
CREATE TABLE departments (
    dept_id       INT            AUTO_INCREMENT PRIMARY KEY,
    dept_name     VARCHAR(100)   NOT NULL UNIQUE,
    dept_head     VARCHAR(100),
    location      VARCHAR(100),
    created_at    DATETIME       DEFAULT CURRENT_TIMESTAMP
);
-- 2. DESIGNATIONS
CREATE TABLE designations (
    desig_id      INT            AUTO_INCREMENT PRIMARY KEY,
    title         VARCHAR(100)   NOT NULL UNIQUE,
    grade_level   TINYINT        NOT NULL COMMENT '1=Junior, 2=Mid, 3=Senior, 4=Manager, 5=Director',
    basic_salary  DECIMAL(12,2)  NOT NULL
);

-- 3. EMPLOYEES
CREATE TABLE employees (
    emp_id        INT            AUTO_INCREMENT PRIMARY KEY,
    emp_code      VARCHAR(20)    NOT NULL UNIQUE COMMENT 'e.g. EMP-001',
    first_name    VARCHAR(50)    NOT NULL,
    last_name     VARCHAR(50)    NOT NULL,
    gender        ENUM('Male','Female','Other') NOT NULL,
    dob           DATE           NOT NULL,
    cnic          VARCHAR(20)    NOT NULL UNIQUE COMMENT 'National ID',
    email         VARCHAR(100)   NOT NULL UNIQUE,
    phone         VARCHAR(20),
    address       TEXT,
    dept_id       INT            NOT NULL,
    desig_id      INT            NOT NULL,
    join_date     DATE           NOT NULL,
    emp_status    ENUM('Active','Inactive','Terminated','On Leave') DEFAULT 'Active',
    created_at    DATETIME       DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_emp_dept   FOREIGN KEY (dept_id)  REFERENCES departments(dept_id)  ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_emp_desig  FOREIGN KEY (desig_id) REFERENCES designations(desig_id) ON UPDATE CASCADE ON DELETE RESTRICT
);


-- 4. SALARY STRUCTURE (percentage rules per designation)

CREATE TABLE salary_structure (
    structure_id      INT            AUTO_INCREMENT PRIMARY KEY,
    desig_id          INT            NOT NULL UNIQUE,
    house_rent_pct    DECIMAL(5,2)   NOT NULL DEFAULT 45.00  COMMENT '% of basic salary',
    medical_pct       DECIMAL(5,2)   NOT NULL DEFAULT 10.00,
    conveyance_pct    DECIMAL(5,2)   NOT NULL DEFAULT 5.00,
    provident_fund_pct DECIMAL(5,2)  NOT NULL DEFAULT 8.33   COMMENT 'Deducted from employee',
    eobi_pct          DECIMAL(5,2)   NOT NULL DEFAULT 1.00   COMMENT 'Employees Old-Age Benefits',
    income_tax_pct    DECIMAL(5,2)   NOT NULL DEFAULT 5.00,
    other_deductions  DECIMAL(12,2)  NOT NULL DEFAULT 0.00,

    CONSTRAINT fk_struct_desig FOREIGN KEY (desig_id) REFERENCES designations(desig_id) ON UPDATE CASCADE ON DELETE CASCADE
);


-- 5. ATTENDANCE

CREATE TABLE attendance (
    attend_id     INT            AUTO_INCREMENT PRIMARY KEY,
    emp_id        INT            NOT NULL,
    attend_date   DATE           NOT NULL,
    check_in      TIME,
    check_out     TIME,
    status        ENUM('Present','Absent','Half Day','Leave','Holiday') DEFAULT 'Present',
    remarks       VARCHAR(200),

    UNIQUE KEY uq_emp_date (emp_id, attend_date),
    CONSTRAINT fk_attend_emp FOREIGN KEY (emp_id) REFERENCES employees(emp_id) ON UPDATE CASCADE ON DELETE CASCADE
);


-- 6. LEAVES

CREATE TABLE leaves (
    leave_id      INT            AUTO_INCREMENT PRIMARY KEY,
    emp_id        INT            NOT NULL,
    leave_type    ENUM('Annual','Sick','Casual','Maternity','Unpaid') NOT NULL,
    start_date    DATE           NOT NULL,
    end_date      DATE           NOT NULL,
    total_days    TINYINT        NOT NULL,
    reason        TEXT,
    status        ENUM('Pending','Approved','Rejected') DEFAULT 'Pending',
    approved_by   INT            COMMENT 'emp_id of manager',
    applied_on    DATETIME       DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_leave_emp      FOREIGN KEY (emp_id)      REFERENCES employees(emp_id) ON DELETE CASCADE,
    CONSTRAINT fk_leave_approver FOREIGN KEY (approved_by) REFERENCES employees(emp_id) ON DELETE SET NULL,
    CONSTRAINT chk_leave_dates   CHECK (end_date >= start_date)
);


-- 7. PAYROLL

CREATE TABLE payroll (
    payroll_id        INT            AUTO_INCREMENT PRIMARY KEY,
    emp_id            INT            NOT NULL,
    payroll_month     TINYINT        NOT NULL COMMENT '1-12',
    payroll_year      YEAR           NOT NULL,
    basic_salary      DECIMAL(12,2)  NOT NULL,
    house_rent        DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    medical           DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    conveyance        DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    overtime_pay      DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    bonus             DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    gross_salary      DECIMAL(12,2)  NOT NULL,
    provident_fund    DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    eobi              DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    income_tax        DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    loan_deduction    DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    other_deductions  DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    total_deductions  DECIMAL(12,2)  NOT NULL,
    net_salary        DECIMAL(12,2)  NOT NULL,
    present_days      TINYINT        NOT NULL DEFAULT 0,
    absent_days       TINYINT        NOT NULL DEFAULT 0,
    payment_status    ENUM('Pending','Paid','On Hold') DEFAULT 'Pending',
    payment_date      DATE,
    payment_method    ENUM('Bank Transfer','Cash','Cheque') DEFAULT 'Bank Transfer',
    generated_on      DATETIME       DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_payroll_month (emp_id, payroll_month, payroll_year),
    CONSTRAINT fk_payroll_emp FOREIGN KEY (emp_id) REFERENCES employees(emp_id) ON UPDATE CASCADE ON DELETE RESTRICT
);


-- 8. LOANS

CREATE TABLE loans (
    loan_id       INT            AUTO_INCREMENT PRIMARY KEY,
    emp_id        INT            NOT NULL,
    loan_amount   DECIMAL(12,2)  NOT NULL,
    installments  TINYINT        NOT NULL COMMENT 'Number of monthly installments',
    per_month     DECIMAL(12,2)  NOT NULL COMMENT 'Deduction per month',
    start_month   TINYINT        NOT NULL,
    start_year    YEAR           NOT NULL,
    status        ENUM('Active','Completed','Cancelled') DEFAULT 'Active',
    reason        TEXT,
    approved_by   INT,
    applied_on    DATETIME       DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_loan_emp      FOREIGN KEY (emp_id)      REFERENCES employees(emp_id) ON DELETE CASCADE,
    CONSTRAINT fk_loan_approver FOREIGN KEY (approved_by) REFERENCES employees(emp_id) ON DELETE SET NULL
);
-- 9. TAX SLABS (annual income brackets)
CREATE TABLE tax_slabs (
    slab_id       INT            AUTO_INCREMENT PRIMARY KEY,
    fiscal_year   YEAR           NOT NULL,
    min_income    DECIMAL(12,2)  NOT NULL,
    max_income    DECIMAL(12,2)  COMMENT 'NULL = no upper limit',
    tax_rate_pct  DECIMAL(5,2)   NOT NULL,
    fixed_tax     DECIMAL(12,2)  NOT NULL DEFAULT 0.00 COMMENT 'Fixed amount on min_income bracket',
    UNIQUE KEY uq_slab (fiscal_year, min_income)
);
-- 10. SALARY SLIP LOG
CREATE TABLE salary_slip_log (
    log_id        INT            AUTO_INCREMENT PRIMARY KEY,
    payroll_id    INT            NOT NULL,
    generated_by  INT            COMMENT 'HR emp_id who ran the payroll',
    generated_at  DATETIME       DEFAULT CURRENT_TIMESTAMP,
    remarks       VARCHAR(300),

    CONSTRAINT fk_log_payroll FOREIGN KEY (payroll_id)    REFERENCES payroll(payroll_id)   ON DELETE CASCADE,
    CONSTRAINT fk_log_hr      FOREIGN KEY (generated_by)  REFERENCES employees(emp_id)      ON DELETE SET NULL
);
-- SAMPLE DATA
INSERT INTO departments (dept_name, dept_head, location) VALUES
('Human Resources',  'Ali Hassan',    'Floor 1'),
('Information Technology', 'Sara Khan', 'Floor 2'),
('Finance',          'Usman Malik',   'Floor 1'),
('Marketing',        'Ayesha Noor',   'Floor 3'),
('Operations',       'Bilal Ahmed',   'Floor 2');


INSERT INTO designations (title, grade_level, basic_salary) VALUES
('HR Officer',        1, 45000.00),
('Software Engineer', 2, 70000.00),
('Senior Developer',  3, 110000.00),
('Finance Manager',   4, 130000.00),
('CEO',               5, 250000.00),
('Marketing Executive', 1, 42000.00),
('Operations Manager',  4, 120000.00);

-- 3. SALARY STRUCTURE (per designation)
INSERT INTO salary_structure (desig_id, house_rent_pct, medical_pct, conveyance_pct, provident_fund_pct, eobi_pct, income_tax_pct) VALUES
(1, 45, 10, 5, 8.33, 1, 2),
(2, 45, 10, 5, 8.33, 1, 5),
(3, 45, 10, 5, 8.33, 1, 8),
(4, 45, 10, 5, 8.33, 1, 10),
(5, 45, 10, 5, 8.33, 1, 15),
(6, 45, 10, 5, 8.33, 1, 2),
(7, 45, 10, 5, 8.33, 1, 10);
INSERT INTO employees (emp_code, first_name, last_name, gender, dob, cnic, email, phone, address, dept_id, desig_id, join_date) VALUES
('EMP-001', 'Ali',     'Hassan',  'Male',   '1990-03-15', '42101-1234567-1', 'ali.hassan@company.com',    '0300-1111111', 'House 5, Block A, Karachi',  1, 1, '2020-01-10'),
('EMP-002', 'Sara',    'Khan',    'Female', '1992-07-22', '42101-2345678-2', 'sara.khan@company.com',     '0301-2222222', 'Flat 12, Gulshan, Karachi',  2, 2, '2019-06-01'),
('EMP-003', 'Usman',   'Malik',   'Male',   '1988-11-05', '42101-3456789-3', 'usman.malik@company.com',   '0302-3333333', 'Plot 3, DHA Phase 2, Lahore',3, 4, '2018-03-15'),
('EMP-004', 'Ayesha',  'Noor',    'Female', '1995-01-30', '42101-4567890-4', 'ayesha.noor@company.com',   '0303-4444444', 'Street 7, F-8, Islamabad',   4, 6, '2021-08-20'),
('EMP-005', 'Bilal',   'Ahmed',   'Male',   '1985-09-12', '42101-5678901-5', 'bilal.ahmed@company.com',   '0304-5555555', 'House 99, Johar Town, Lahore',5, 7, '2017-02-01'),
('EMP-006', 'Zara',    'Siddiqui','Female', '1993-04-18', '42101-6789012-6', 'zara.sid@company.com',      '0305-6666666', 'Block B, North Karachi',      2, 3, '2020-11-15'),
('EMP-007', 'Hamza',   'Raza',    'Male',   '1991-12-25', '42101-7890123-7', 'hamza.raza@company.com',    '0306-7777777', 'Flat 4, Bahria Town, RWP',    2, 2, '2022-01-05');
INSERT INTO attendance (emp_id, attend_date, check_in, check_out, status) VALUES
(1, '2025-06-01', '09:00:00', '17:00:00', 'Present'),
(1, '2025-06-02', '09:15:00', '17:10:00', 'Present'),
(1, '2025-06-03', NULL,       NULL,        'Absent'),
(1, '2025-06-04', '09:00:00', '13:00:00', 'Half Day'),
(2, '2025-06-01', '08:55:00', '17:05:00', 'Present'),
(2, '2025-06-02', '09:00:00', '17:00:00', 'Present'),
(2, '2025-06-03', '09:00:00', '17:00:00', 'Present'),
(3, '2025-06-01', '09:30:00', '17:30:00', 'Present'),
(3, '2025-06-02', NULL,       NULL,        'Leave'),
(4, '2025-06-01', '09:00:00', '17:00:00', 'Present'),
(5, '2025-06-01', '08:45:00', '17:15:00', 'Present'),
(6, '2025-06-01', '09:00:00', '17:00:00', 'Present'),
(7, '2025-06-01', NULL,       NULL,        'Absent');
INSERT INTO leaves (emp_id, leave_type, start_date, end_date, total_days, reason, status, approved_by) VALUES
(1, 'Sick',   '2025-06-03', '2025-06-03', 1, 'Fever',             'Approved', 3),
(3, 'Annual', '2025-06-02', '2025-06-02', 1, 'Family function',   'Approved', 5),
(4, 'Casual', '2025-06-10', '2025-06-11', 2, 'Personal work',     'Pending',  NULL),
(7, 'Sick',   '2025-06-01', '2025-06-01', 1, 'Not feeling well',  'Pending',  NULL);
INSERT INTO payroll (
    emp_id, payroll_month, payroll_year,
    basic_salary, house_rent, medical, conveyance, overtime_pay, bonus,
    gross_salary,
    provident_fund, eobi, income_tax, loan_deduction, other_deductions,
    total_deductions, net_salary,
    present_days, absent_days, payment_status, payment_date, payment_method
) VALUES
(1, 5, 2025,
 45000, 20250, 4500, 2250, 0, 0,
 72000,
 3748.50, 450, 900, 0, 0,
 5098.50, 66901.50,
 26, 0, 'Paid', '2025-05-31', 'Bank Transfer'),

(2, 5, 2025,
 70000, 31500, 7000, 3500, 5000, 0,
 117000,
 5831, 700, 3500, 0, 0,
 10031, 106969,
 26, 0, 'Paid', '2025-05-31', 'Bank Transfer'),

(3, 5, 2025,
 130000, 58500, 13000, 6500, 0, 10000,
 218000,
 10829, 1300, 13000, 0, 0,
 25129, 192871,
 25, 1, 'Paid', '2025-05-31', 'Bank Transfer'),

(4, 5, 2025,
 42000, 18900, 4200, 2100, 0, 0,
 67200,
 3498.60, 420, 840, 0, 0,
 4758.60, 62441.40,
 26, 0, 'Paid', '2025-05-31', 'Bank Transfer');


INSERT INTO loans (emp_id, loan_amount, installments, per_month, start_month, start_year, status, reason, approved_by) VALUES
(2, 50000, 5, 10000, 6, 2025, 'Active',    'Medical emergency', 3),
(5, 30000, 3, 10000, 5, 2025, 'Completed', 'House rent',        3);


INSERT INTO tax_slabs (fiscal_year, min_income, max_income, tax_rate_pct, fixed_tax) VALUES
(2025,      0,    600000,  0.00,  0.00),
(2025, 600001,   1200000,  2.50,  0.00),
(2025,1200001,   2400000,  12.50, 15000.00),
(2025,2400001,   3600000,  20.00, 165000.00),
(2025,3600001,   6000000,  25.00, 405000.00),
(2025,6000001,      NULL,  35.00, 1005000.00);



-- QUERY 1: Employee directory with department & designation

SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.gender,
    d.dept_name,
    des.title         AS designation,
    des.basic_salary,
    e.join_date,
    e.emp_status
FROM employees e
JOIN departments  d   ON e.dept_id  = d.dept_id
JOIN designations des ON e.desig_id = des.desig_id
ORDER BY d.dept_name, e.first_name;


-- QUERY 2: Payroll summary (May 2025)

SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    p.payroll_month,
    p.payroll_year,
    p.basic_salary,
    p.gross_salary,
    p.total_deductions,
    p.net_salary,
    p.payment_status
FROM payroll p
JOIN employees e ON p.emp_id = e.emp_id
WHERE p.payroll_month = 5 AND p.payroll_year = 2025
ORDER BY p.net_salary DESC;


-- QUERY 3: Attendance summary (June 2025)

SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    COUNT(CASE WHEN a.status = 'Present'  THEN 1 END) AS present_days,
    COUNT(CASE WHEN a.status = 'Absent'   THEN 1 END) AS absent_days,
    COUNT(CASE WHEN a.status = 'Half Day' THEN 1 END) AS half_days,
    COUNT(CASE WHEN a.status = 'Leave'    THEN 1 END) AS leave_days
FROM attendance a
JOIN employees e ON a.emp_id = e.emp_id
WHERE MONTH(a.attend_date) = 6 AND YEAR(a.attend_date) = 2025
GROUP BY e.emp_id, employee_name
ORDER BY present_days DESC;
-- QUERY 4: All leave requests with approver
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    l.leave_type,
    l.start_date,
    l.end_date,
    l.total_days,
    l.reason,
    l.status,
    CONCAT(mgr.first_name, ' ', mgr.last_name) AS approved_by
FROM leaves l
JOIN employees e ON l.emp_id = e.emp_id
LEFT JOIN employees mgr ON l.approved_by = mgr.emp_id
ORDER BY l.applied_on DESC;
-- QUERY 5: Active loans list
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    lo.loan_amount,
    lo.installments,
    lo.per_month,
    lo.start_month,
    lo.start_year,
    lo.status,
    lo.reason
FROM loans lo
JOIN employees e ON lo.emp_id = e.emp_id
WHERE lo.status = 'Active';

-- QUERY 6: Department-wise payroll cost (May 2025)

SELECT
    d.dept_name,
    COUNT(e.emp_id)          AS total_employees,
    SUM(p.gross_salary)      AS total_gross,
    SUM(p.total_deductions)  AS total_deductions,
    SUM(p.net_salary)        AS total_net_paid
FROM payroll p
JOIN employees   e ON p.emp_id  = e.emp_id
JOIN departments d ON e.dept_id = d.dept_id
WHERE p.payroll_month = 5 AND p.payroll_year = 2025
GROUP BY d.dept_id, d.dept_name
ORDER BY total_net_paid DESC;


SELECT * FROM departments;
SELECT * FROM designations;

-- QUERY 7: Active employees with age & years of service

SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.gender,
    e.dob,
    TIMESTAMPDIFF(YEAR, e.dob, CURDATE())  AS age,
    e.cnic,
    e.email,
    e.phone,
    d.dept_name,
    des.title        AS designation,
    des.basic_salary,
    e.join_date,
    TIMESTAMPDIFF(YEAR, e.join_date, CURDATE()) AS years_of_service,
    e.emp_status
FROM employees e
JOIN departments  d   ON e.dept_id  = d.dept_id
JOIN designations des ON e.desig_id = des.desig_id
WHERE e.emp_status = 'Active'
ORDER BY d.dept_name, e.first_name;


-- QUERY 8: Single employee full profile (by emp_id)

SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.gender, e.dob, e.cnic, e.email, e.phone, e.address,
    d.dept_name,
    des.title        AS designation,
    des.grade_level,
    des.basic_salary,
    e.join_date,
    TIMESTAMPDIFF(MONTH, e.join_date, CURDATE()) AS months_of_service,
    e.emp_status
FROM employees e
JOIN departments  d   ON e.dept_id  = d.dept_id
JOIN designations des ON e.desig_id = des.desig_id
WHERE e.emp_id = 2;
-- QUERY 9: Department-wise gender breakdown

SELECT
    d.dept_name,
    COUNT(e.emp_id)                                          AS total_employees,
    SUM(CASE WHEN e.gender = 'Male'   THEN 1 ELSE 0 END)   AS male_count,
    SUM(CASE WHEN e.gender = 'Female' THEN 1 ELSE 0 END)   AS female_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id AND e.emp_status = 'Active'
GROUP BY d.dept_id, d.dept_name
ORDER BY total_employees DESC;
-- QUERY 10: Recently joined employees (last 6 months)
SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.dept_name,
    des.title AS designation,
    e.join_date
FROM employees e
JOIN departments  d   ON e.dept_id  = d.dept_id
JOIN designations des ON e.desig_id = des.desig_id
WHERE e.join_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
ORDER BY e.join_date DESC;
-- QUERY 11: Senior staff -- 5+ years of service
SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name)        AS employee_name,
    d.dept_name,
    des.title                                       AS designation,
    e.join_date,
    TIMESTAMPDIFF(YEAR, e.join_date, CURDATE())    AS years_of_service
FROM employees e
JOIN departments  d   ON e.dept_id  = d.dept_id
JOIN designations des ON e.desig_id = des.desig_id
WHERE TIMESTAMPDIFF(YEAR, e.join_date, CURDATE()) >= 5
ORDER BY years_of_service DESC;
-- QUERY 12: Daily attendance detail with hours worked (June 2025)

SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    a.attend_date,
    a.check_in,
    a.check_out,
    TIMEDIFF(a.check_out, a.check_in)      AS hours_worked,
    a.status,
    a.remarks
FROM attendance a
JOIN employees e ON a.emp_id = e.emp_id
WHERE MONTH(a.attend_date) = 6 AND YEAR(a.attend_date) = 2025
ORDER BY a.attend_date, e.emp_code;
-- QUERY 13: Monthly attendance summary per employee (June 2025)
SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name)                  AS employee_name,
    COUNT(CASE WHEN a.status = 'Present'  THEN 1 END)       AS present,
    COUNT(CASE WHEN a.status = 'Absent'   THEN 1 END)       AS absent,
    COUNT(CASE WHEN a.status = 'Half Day' THEN 1 END)       AS half_day,
    COUNT(CASE WHEN a.status = 'Leave'    THEN 1 END)       AS on_leave,
    COUNT(CASE WHEN a.status = 'Holiday'  THEN 1 END)       AS holiday,
    COUNT(a.attend_id)                                       AS total_days_recorded
FROM employees e
LEFT JOIN attendance a ON e.emp_id = a.emp_id
    AND MONTH(a.attend_date) = 6
    AND YEAR(a.attend_date)  = 2025
WHERE e.emp_status = 'Active'
GROUP BY e.emp_id, e.emp_code, employee_name
ORDER BY absent DESC;
-- QUERY 14: Late arrivals (after 09:15 AM, June 2025)
SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    a.attend_date,
    a.check_in,
    TIMEDIFF(a.check_in, '09:00:00')       AS late_by
FROM attendance a
JOIN employees e ON a.emp_id = e.emp_id
WHERE a.check_in > '09:15:00'
  AND a.status = 'Present'
  AND MONTH(a.attend_date) = 6
  AND YEAR(a.attend_date)  = 2025
ORDER BY a.attend_date, late_by DESC;
-- QUERY 15: Who's absent/on leave today
SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.dept_name,
    a.status
FROM attendance a
JOIN employees   e ON a.emp_id  = e.emp_id
JOIN departments d ON e.dept_id = d.dept_id
WHERE a.attend_date = CURDATE()
  AND a.status IN ('Absent', 'Leave')
ORDER BY d.dept_name;

-- QUERY 16 [FIXED]: Overtime hours (after 6 PM, June 2025)
-- FIX: original query was missing "YEAR(a.attend_date) = 2025",
-- which meant June of ANY year would match (e.g. June 2024, June 2026).
SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    a.attend_date,
    a.check_out,
    TIMEDIFF(a.check_out, '18:00:00')      AS overtime_hours
FROM attendance a
JOIN employees e ON a.emp_id = e.emp_id
WHERE a.check_out > '18:00:00'
  AND MONTH(a.attend_date) = 6
  AND YEAR(a.attend_date)  = 2025
ORDER BY overtime_hours DESC;
-- QUERY 17: Pending leave requests
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.dept_name,
    l.leave_type,
    l.start_date,
    l.end_date,
    l.total_days,
    l.reason,
    l.status,
    l.applied_on
FROM leaves l
JOIN employees   e ON l.emp_id  = e.emp_id
JOIN departments d ON e.dept_id = d.dept_id
WHERE l.status = 'Pending'
ORDER BY l.applied_on ASC;
-- QUERY 18: Approved leaves starting this month

SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    l.leave_type,
    l.start_date,
    l.end_date,
    l.total_days,
    CONCAT(m.first_name, ' ', m.last_name) AS approved_by
FROM leaves l
JOIN employees e   ON l.emp_id      = e.emp_id
LEFT JOIN employees m ON l.approved_by = m.emp_id
WHERE l.status = 'Approved'
  AND MONTH(l.start_date) = MONTH(CURDATE())
  AND YEAR(l.start_date)  = YEAR(CURDATE());
-- QUERY 19: Leave history for a single employee (emp_id = 1)
SELECT
    l.leave_type,
    l.start_date,
    l.end_date,
    l.total_days,
    l.reason,
    l.status
FROM leaves l
WHERE l.emp_id = 1
ORDER BY l.applied_on DESC;
-- QUERY 20: Leave balance per employee (Annual quota = 15 days/year)
SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name)      AS employee_name,
    COALESCE(SUM(
        CASE WHEN l.leave_type = 'Annual'
             AND l.status = 'Approved'
             AND YEAR(l.start_date) = YEAR(CURDATE())
        THEN l.total_days ELSE 0 END), 0)        AS annual_used,
    15 - COALESCE(SUM(
        CASE WHEN l.leave_type = 'Annual'
             AND l.status = 'Approved'
             AND YEAR(l.start_date) = YEAR(CURDATE())
        THEN l.total_days ELSE 0 END), 0)        AS annual_remaining,
    COALESCE(SUM(
        CASE WHEN l.leave_type = 'Sick'
             AND l.status = 'Approved'
             AND YEAR(l.start_date) = YEAR(CURDATE())
        THEN l.total_days ELSE 0 END), 0)        AS sick_used
FROM employees e
LEFT JOIN leaves l ON e.emp_id = l.emp_id
WHERE e.emp_status = 'Active'
GROUP BY e.emp_id, e.emp_code, employee_name
ORDER BY annual_remaining ASC;
-- QUERY 21: Full payroll detail (May 2025)
SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.dept_name,
    des.title                               AS designation,
    p.basic_salary,
    p.house_rent,
    p.medical,
    p.conveyance,
    p.overtime_pay,
    p.bonus,
    p.gross_salary,
    p.provident_fund,
    p.eobi,
    p.income_tax,
    p.loan_deduction,
    p.other_deductions,
    p.total_deductions,
    p.net_salary,
    p.present_days,
    p.absent_days,
    p.payment_status,
    p.payment_date,
    p.payment_method
FROM payroll p
JOIN employees   e   ON p.emp_id  = e.emp_id
JOIN departments d   ON e.dept_id = d.dept_id
JOIN designations des ON e.desig_id = des.desig_id
WHERE p.payroll_month = 5 AND p.payroll_year = 2025
ORDER BY p.net_salary DESC;
-- QUERY 22: Salary slip for one employee (EMP-002, May 2025)
SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.dept_name,
    des.title               AS designation,
    p.payroll_month,
    p.payroll_year,
    '--- EARNINGS ---'      AS section1,
    p.basic_salary,
    p.house_rent,
    p.medical,
    p.conveyance,
    p.overtime_pay,
    p.bonus,
    p.gross_salary,
    '--- DEDUCTIONS ---'    AS section2,
    p.provident_fund,
    p.eobi,
    p.income_tax,
    p.loan_deduction,
    p.other_deductions,
    p.total_deductions,
    '--- NET ---'           AS section3,
    p.net_salary,
    p.payment_status,
    p.payment_date
FROM payroll p
JOIN employees    e   ON p.emp_id   = e.emp_id
JOIN departments  d   ON e.dept_id  = d.dept_id
JOIN designations des ON e.desig_id = des.desig_id
WHERE e.emp_code = 'EMP-002'
  AND p.payroll_month = 5
  AND p.payroll_year  = 2025;

-- QUERY 23: Department-wise payroll cost summary (May 2025)

SELECT
    d.dept_name,
    COUNT(p.payroll_id)      AS employees_paid,
    SUM(p.basic_salary)      AS total_basic,
    SUM(p.gross_salary)      AS total_gross,
    SUM(p.total_deductions)  AS total_deductions,
    SUM(p.net_salary)        AS total_net,
    AVG(p.net_salary)        AS avg_net_salary
FROM payroll p
JOIN employees   e ON p.emp_id  = e.emp_id
JOIN departments d ON e.dept_id = d.dept_id
WHERE p.payroll_month = 5 AND p.payroll_year = 2025
GROUP BY d.dept_id, d.dept_name
ORDER BY total_net DESC;
-- QUERY 24: Unpaid / on-hold payroll records
SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.dept_name,
    p.payroll_month,
    p.payroll_year,
    p.net_salary,
    p.payment_status
FROM payroll p
JOIN employees   e ON p.emp_id  = e.emp_id
JOIN departments d ON e.dept_id = d.dept_id
WHERE p.payment_status IN ('Pending', 'On Hold')
ORDER BY p.payroll_year, p.payroll_month;

-- QUERY 25: Yearly payroll cost summary
SELECT
    p.payroll_year,
    SUM(p.gross_salary)     AS annual_gross_cost,
    SUM(p.total_deductions) AS annual_deductions,
    SUM(p.net_salary)       AS annual_net_paid,
    COUNT(DISTINCT p.emp_id) AS employees_count
FROM payroll p
GROUP BY p.payroll_year
ORDER BY p.payroll_year DESC;
-- QUERY 26: Top 5 highest-paid employees (May 2025)

SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    des.title                               AS designation,
    d.dept_name,
    p.gross_salary,
    p.net_salary
FROM payroll p
JOIN employees    e   ON p.emp_id   = e.emp_id
JOIN designations des ON e.desig_id = des.desig_id
JOIN departments  d   ON e.dept_id  = d.dept_id
WHERE p.payroll_month = 5 AND p.payroll_year = 2025
ORDER BY p.net_salary DESC
LIMIT 5;

-- QUERY 27: Estimated salary breakdown from salary_structure
-- (theoretical calculation directly from designation % rules,
--  independent of actual stored payroll records)
SELECT
    e.emp_id,
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name)                             AS employee_name,
    des.basic_salary,
    ROUND(des.basic_salary * ss.house_rent_pct    / 100, 2)           AS house_rent,
    ROUND(des.basic_salary * ss.medical_pct       / 100, 2)           AS medical,
    ROUND(des.basic_salary * ss.conveyance_pct    / 100, 2)           AS conveyance,
    ROUND(des.basic_salary * (1 + ss.house_rent_pct/100
        + ss.medical_pct/100 + ss.conveyance_pct/100), 2)             AS gross_salary,
    ROUND(des.basic_salary * ss.provident_fund_pct / 100, 2)          AS provident_fund,
    ROUND(des.basic_salary * ss.eobi_pct           / 100, 2)          AS eobi,
    ROUND(des.basic_salary * ss.income_tax_pct     / 100, 2)          AS income_tax,
    ROUND(des.basic_salary * (ss.provident_fund_pct
        + ss.eobi_pct + ss.income_tax_pct) / 100, 2)                  AS total_deductions,
    ROUND(des.basic_salary * (1 + ss.house_rent_pct/100
        + ss.medical_pct/100 + ss.conveyance_pct/100)
        - des.basic_salary * (ss.provident_fund_pct
        + ss.eobi_pct + ss.income_tax_pct) / 100, 2)                  AS estimated_net
FROM employees e
JOIN designations     des ON e.desig_id = des.desig_id
JOIN salary_structure ss  ON des.desig_id = ss.desig_id
WHERE e.emp_status = 'Active'
ORDER BY estimated_net DESC;
-- QUERY 28: Active loans with approver

SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.dept_name,
    lo.loan_amount,
    lo.installments,
    lo.per_month,
    lo.start_month,
    lo.start_year,
    lo.status,
    lo.reason,
    CONCAT(m.first_name, ' ', m.last_name) AS approved_by
FROM loans lo
JOIN employees   e ON lo.emp_id      = e.emp_id
JOIN departments d ON e.dept_id      = d.dept_id
LEFT JOIN employees m ON lo.approved_by = m.emp_id
WHERE lo.status = 'Active'
ORDER BY lo.loan_amount DESC;


-- QUERY 29 [FIXED]: Loan remaining balance


SELECT
    lo.loan_id,
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    lo.loan_amount,
    lo.installments,
    lo.per_month,
    (lo.installments * lo.per_month) AS total_payable,
    COALESCE((
        SELECT SUM(p.loan_deduction)
        FROM payroll p
        WHERE p.emp_id = lo.emp_id
          AND (p.payroll_year > lo.start_year
               OR (p.payroll_year = lo.start_year AND p.payroll_month >= lo.start_month))
    ), 0) AS amount_paid,
    lo.loan_amount - COALESCE((
        SELECT SUM(p.loan_deduction)
        FROM payroll p
        WHERE p.emp_id = lo.emp_id
          AND (p.payroll_year > lo.start_year
               OR (p.payroll_year = lo.start_year AND p.payroll_month >= lo.start_month))
    ), 0) AS remaining_balance
FROM loans lo
JOIN employees e ON lo.emp_id = e.emp_id
WHERE lo.status = 'Active';


-- QUERY 30: Tax slab reference table (formatted)

SELECT
    fiscal_year,
    FORMAT(min_income, 0)                            AS min_income,
    IFNULL(FORMAT(max_income, 0), 'No Limit')        AS max_income,
    CONCAT(tax_rate_pct, '%')                        AS tax_rate,
    FORMAT(fixed_tax, 0)                             AS fixed_tax_amount
FROM tax_slabs
WHERE fiscal_year = 2025
ORDER BY min_income;
-- QUERY 31 [FIXED]: Progressive (cumulative) annual tax estimate

SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    des.basic_salary,
    des.basic_salary * 12 AS annual_income,
    ROUND(SUM(
        CASE
            -- income fully covers this slab: tax the whole slab width
            WHEN des.basic_salary * 12 > IFNULL(ts.max_income, des.basic_salary * 12)
                THEN (IFNULL(ts.max_income, des.basic_salary * 12) - ts.min_income + 1) * ts.tax_rate_pct / 100
            -- income falls inside this slab: tax only the portion above min_income
            WHEN des.basic_salary * 12 >= ts.min_income
                THEN (des.basic_salary * 12 - ts.min_income + 1) * ts.tax_rate_pct / 100
            ELSE 0
        END
    ), 2) AS estimated_annual_tax,
    ROUND(SUM(
        CASE
            WHEN des.basic_salary * 12 > IFNULL(ts.max_income, des.basic_salary * 12)
                THEN (IFNULL(ts.max_income, des.basic_salary * 12) - ts.min_income + 1) * ts.tax_rate_pct / 100
            WHEN des.basic_salary * 12 >= ts.min_income
                THEN (des.basic_salary * 12 - ts.min_income + 1) * ts.tax_rate_pct / 100
            ELSE 0
        END
    ) / 12, 2) AS monthly_tax_deduction
FROM employees e
JOIN designations des ON e.desig_id = des.desig_id
JOIN tax_slabs ts ON ts.fiscal_year = 2025
    AND des.basic_salary * 12 >= ts.min_income
WHERE e.emp_status = 'Active'
GROUP BY e.emp_id, e.emp_code, employee_name, des.basic_salary
ORDER BY annual_income DESC;


-- QUERY 32: Quick dashboard metrics

SELECT 'Total Employees'      AS metric, COUNT(*)                                                 AS value FROM employees WHERE emp_status = 'Active'
UNION ALL
SELECT 'Male Employees',       COUNT(*) FROM employees WHERE gender = 'Male'   AND emp_status = 'Active'
UNION ALL
SELECT 'Female Employees',     COUNT(*) FROM employees WHERE gender = 'Female' AND emp_status = 'Active'
UNION ALL
SELECT 'Total Departments',    COUNT(*) FROM departments
UNION ALL
SELECT 'Pending Leave Requests', COUNT(*) FROM leaves WHERE status = 'Pending'
UNION ALL
SELECT 'Active Loans',         COUNT(*) FROM loans WHERE status = 'Active';
-- QUERY 33: Salary range distribution
SELECT
    CASE
        WHEN des.basic_salary < 50000                    THEN 'Below 50K'
        WHEN des.basic_salary BETWEEN 50000 AND 100000   THEN '50K - 100K'
        WHEN des.basic_salary BETWEEN 100001 AND 150000  THEN '100K - 150K'
        ELSE 'Above 150K'
    END                                                  AS salary_range,
    COUNT(e.emp_id)                                      AS employee_count
FROM employees e
JOIN designations des ON e.desig_id = des.desig_id
WHERE e.emp_status = 'Active'
GROUP BY salary_range
ORDER BY MIN(des.basic_salary);


-- QUERY 34: Active employees missing this month's payroll

SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.dept_name,
    des.title AS designation
FROM employees e
JOIN departments  d   ON e.dept_id  = d.dept_id
JOIN designations des ON e.desig_id = des.desig_id
WHERE e.emp_status = 'Active'
  AND e.emp_id NOT IN (
      SELECT emp_id FROM payroll
      WHERE payroll_month = MONTH(CURDATE())
        AND payroll_year  = YEAR(CURDATE())
  );


-- QUERY 35: Top 10 most-absent employees this month

SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.dept_name,
    COUNT(a.attend_id)                      AS absent_days
FROM attendance a
JOIN employees   e ON a.emp_id  = e.emp_id
JOIN departments d ON e.dept_id = d.dept_id
WHERE a.status = 'Absent'
  AND MONTH(a.attend_date) = MONTH(CURDATE())
  AND YEAR(a.attend_date)  = YEAR(CURDATE())
GROUP BY e.emp_id, e.emp_code, employee_name, d.dept_name
ORDER BY absent_days DESC
LIMIT 10;


-- QUERY 36: Search employees by department or name

SELECT
    e.emp_code,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.email,
    e.phone,
    d.dept_name,
    des.title AS designation,
    e.emp_status
FROM employees e
JOIN departments  d   ON e.dept_id  = d.dept_id
JOIN designations des ON e.desig_id = des.desig_id
WHERE d.dept_name LIKE '%Technology%'
   OR CONCAT(e.first_name, ' ', e.last_name) LIKE '%Sara%';


-- RAW TABLE DUMPS

SELECT * FROM salary_structure;
SELECT * FROM employees;
SELECT * FROM attendance;
SELECT * FROM leaves;
SELECT * FROM payroll;
SELECT * FROM loans;
SELECT * FROM tax_slabs;
SELECT * FROM salary_slip_log;
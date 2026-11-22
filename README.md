# Employee Payroll Management System 

A MySQL database project for managing employee payroll and HR data of a company. It covers employee records, attendance, leaves, loans, tax slabs and monthly salary calculation, along with 36 ready-made SQL queries for reports.

## 🌟 Features

- Employee, department and designation management
- Daily attendance tracking with check-in and check-out
- Leave requests with approval workflow
- Monthly payroll with earnings and deductions
- Loan management with installment tracking
- Income tax slabs and salary structure rules
- Salary slip log
- 36 SQL queries (employee directory, payroll summary, attendance reports, late arrivals, overtime, leave balance, salary slip, loan balance, tax estimate, dashboard metrics)

## 🛠️ Built With

- MySQL

## 🗂️ Database Tables

| Table | Purpose |
|-------|---------|
| departments | Company departments |
| designations | Job titles, grade level and basic salary |
| employees | Employee personal and job details |
| salary_structure | Allowance and deduction percentages per designation |
| attendance | Daily attendance records |
| leaves | Leave requests and approvals |
| payroll | Monthly salary (gross, deductions, net) |
| loans | Employee loans and installments |
| tax_slabs | Income tax brackets |
| salary_slip_log | Record of generated salary slips |

## 🚀 How to Run

1. Open MySQL Workbench (or any MySQL client).
2. Open the `employee_payroll_db.sql` file.
3. Run the script to create the database, tables and sample data.
4. Run the queries one by one to see the reports.

## 📌 Note

This project uses sample data for educational purposes. Payroll sample data is for May 2025 and attendance sample data is for June 2025.

## 📄 License

This project is created for educational/portfolio purposes.

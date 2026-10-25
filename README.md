# 📚 Library Management System — MySQL

A relational database for running a multi-branch library: who works where, who the members are, which books are on the shelf, what has been issued, and what has come back. I built it in **MySQL** to practise designing a schema and then answering real business questions with SQL — from simple CRUD to joins, CTAS reports and stored procedures.



## 🎯 What This Project Does

A library never really stops moving: books go out, books come back, members join, staff handle the desk. This project models that flow in six linked tables and uses SQL to:

1. **Store** branches, employees, members, books, issue records and return records with proper keys and constraints.
2. **Maintain** the data with insert, update and delete operations.
3. **Report** on it — revenue by category, branch performance, busiest staff, overdue books and fines.
4. **Automate** the desk workflow — issuing and returning a book — with stored procedures that keep a book's availability in sync.

---

## 🛠 Tech Stack

| Tool | Used for |
|------|----------|
| **MySQL 8** | Database engine |
| **MySQL Workbench** | Writing queries and generating the EER diagram |
| **SQL** | DDL, DML, joins, aggregation, CTAS, stored procedures |
| **Git / GitHub** | Version control |

---

## 🗂 Database Schema
<img width="1257" height="853" alt="image" src="https://github.com/user-attachments/assets/d063245c-d518-405d-a72d-3451777b8c43" />


*EER diagram generated from `library_db` in MySQL Workbench.*

### Core tables

| Table | Purpose | Key columns |
|-------|---------|-------------|
| `branch` | Library branches | **`branch_id`** (PK), `manager_id`, `branch_address`, `contact_no` |
| `employees` | Staff working at a branch | **`emp_id`** (PK), `emp_name`, `position`, `salary`, `branch_id` (FK → `branch`) |
| `members` | Registered library members | **`member_id`** (PK), `member_name`, `member_address`, `reg_date` |
| `books` | Catalogue of books and availability | **`isbn`** (PK), `book_title`, `category`, `rental_price`, `status`, `author`, `publisher` |
| `issued_status` | One row per book issued | **`issued_id`** (PK), `issued_member_id` (FK → `members`), `issued_book_name`, `issued_date`, `issued_book_isbn` (FK → `books`), `issued_emp_id` (FK → `employees`) |
| `return_status` | One row per book returned | **`return_id`** (PK), `issued_id` (links to `issued_status`), `return_book_name`, `return_date`, `return_book_isbn` |

### Relationships

- One **branch** has many **employees**.
- One **employee** can process many **issued_status** records.
- One **member** can have many **issued_status** records.
- One **book** can appear in many **issued_status** records (it gets issued again and again).
- One **issued_status** record can have a matching **return_status** record. A book that is issued but has no return row is still out.

### Summary tables created with CTAS

Besides the six core tables, a few tables were generated from query results (they also appear in the diagram):

- `books_count` — how many times each book title has been issued
- a rental-price-threshold table — books priced above a chosen amount
- `branch_reports` and `active_members` — created by the reports below

> 💡 `status` in `books` is `'yes'` when a book is on the shelf and `'no'` when it is out. ISBNs are stored as `VARCHAR` because they contain hyphens.

---

## 📁 Repository Structure

```
library-management-sql/
├── images/
│   └── er_diagram.png        # EER diagram shown above
├── sql/
│   ├── 01_schema.sql         # CREATE DATABASE + CREATE TABLE statements
│   ├── 02_data.sql           # Sample data (INSERT statements)
│   ├── 03_crud.sql           # Create / read / update / delete tasks
│   ├── 04_analysis.sql       # Joins, aggregates, CTAS reports
│   └── 05_procedures.sql     # Stored procedures
└── README.md
```

*(Adjust the file names above to match what is actually in the repo.)*

---

## 🚀 Getting Started

**Prerequisites:** MySQL 8+ (Workbench is optional but handy).

1. **Clone the repo**
   ```bash
   git clone https://github.com/Sumitgupta2005/<your-repo-name>.git
   cd <your-repo-name>
   ```
2. **Create the database and tables**
   ```bash
   mysql -u root -p < sql/01_schema.sql
   ```
3. **Load the sample data**
   ```bash
   mysql -u root -p library_db < sql/02_data.sql
   ```
4. **Run the analysis and procedures**
   ```bash
   mysql -u root -p library_db < sql/04_analysis.sql
   mysql -u root -p library_db < sql/05_procedures.sql
   ```
   Or open the files in MySQL Workbench and run them block by block.

---

## 🧠 SQL Skills Practised

| Area | What I used |
|------|-------------|
| **Schema design** | Primary keys, foreign keys, data types, relationships between six tables |
| **CRUD** | `INSERT`, `SELECT`, `UPDATE`, `DELETE` |
| **Joins** | Inner joins, left joins, and a self join (employee → their branch manager) |
| **Aggregation** | `COUNT`, `SUM`, `GROUP BY`, `HAVING`, `ORDER BY`, `LIMIT` |
| **Subqueries** | `IN (SELECT …)` for filtering members by recent activity |
| **CTAS** | `CREATE TABLE … AS SELECT` for reusable summary tables |
| **Date logic** | `CURDATE()`, `DATEDIFF()`, `INTERVAL` for overdue checks and "recent" filters |
| **Stored procedures** | Parameters, variables, `IF … ELSE`, multi-step transactions-in-one-call |

---

## ❓ Questions the Database Answers

**Managing records**
- Add a new book to the catalogue
- Correct a member's address
- Remove a wrongly entered issue record
- Which books did a particular employee issue?
- Which members have borrowed more than one book?

**Reporting**
- Which books are in a given category?
- How much rental income does each category bring in?
- Which members joined in the last 180 days?
- Who are the employees at each branch, and who manages them?
- Which books have been issued but not returned yet?
- How many times has each book been issued?
- Which books are priced above a given rental price?

**Operations and performance**
- Which members have overdue books (loan period assumed to be 30 days)?
- How is each branch performing — books issued, books returned, revenue?
- Which members have been active in the last two months?
- Which three employees processed the most issues?
- How much fine does each member owe on overdue books?

---

## ⭐ Featured Queries

*All queries below are written for MySQL.*

### 1. Overdue books (30-day loan period)

```sql
SELECT
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    DATEDIFF(CURDATE(), ist.issued_date) - 30 AS days_overdue
FROM issued_status ist
JOIN members m       ON m.member_id = ist.issued_member_id
JOIN books bk        ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL
  AND DATEDIFF(CURDATE(), ist.issued_date) > 30
ORDER BY ist.issued_member_id;
```

The `LEFT JOIN … WHERE rs.return_id IS NULL` pattern keeps only the books that have **no** matching return record.

### 2. Branch performance report (CTAS)

```sql
CREATE TABLE branch_reports AS
SELECT
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id)  AS books_issued,
    COUNT(rs.return_id)   AS books_returned,
    SUM(bk.rental_price)  AS total_revenue
FROM issued_status ist
JOIN employees e           ON e.emp_id = ist.issued_emp_id
JOIN branch b              ON b.branch_id = e.branch_id
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
JOIN books bk              ON bk.isbn = ist.issued_book_isbn
GROUP BY b.branch_id, b.manager_id;
```

### 3. Top 3 employees by books processed

```sql
SELECT
    e.emp_name,
    b.branch_id,
    b.branch_address,
    COUNT(ist.issued_id) AS books_processed
FROM issued_status ist
JOIN employees e ON e.emp_id = ist.issued_emp_id
JOIN branch b    ON b.branch_id = e.branch_id
GROUP BY e.emp_id, e.emp_name, b.branch_id, b.branch_address
ORDER BY books_processed DESC
LIMIT 3;
```

### 4. Overdue fines per member (CTAS, $0.50 per day late)

```sql
CREATE TABLE overdue_fines AS
SELECT
    ist.issued_member_id AS member_id,
    COUNT(*)             AS overdue_books,
    SUM((DATEDIFF(CURDATE(), ist.issued_date) - 30) * 0.50) AS total_fines
FROM issued_status ist
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL
  AND DATEDIFF(CURDATE(), ist.issued_date) > 30
GROUP BY ist.issued_member_id;
```

### 5. Stored procedure — issue a book

Checks availability first. If the book is on the shelf it records the issue and marks the book as unavailable; otherwise it reports that the book is out.

```sql
DELIMITER $$

CREATE PROCEDURE issue_book(
    IN p_issued_id  VARCHAR(10),
    IN p_member_id  VARCHAR(30),
    IN p_isbn       VARCHAR(50),
    IN p_emp_id     VARCHAR(10)
)
BEGIN
    DECLARE v_status VARCHAR(10);
    DECLARE v_title  VARCHAR(80);

    SELECT status, book_title INTO v_status, v_title
    FROM books WHERE isbn = p_isbn;

    IF v_status = 'yes' THEN
        INSERT INTO issued_status
            (issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
        VALUES
            (p_issued_id, p_member_id, v_title, CURDATE(), p_isbn, p_emp_id);

        UPDATE books SET status = 'no' WHERE isbn = p_isbn;
        SELECT CONCAT('Book issued successfully: ', v_title) AS message;
    ELSE
        SELECT CONCAT('Sorry, this book is currently unavailable (ISBN ', p_isbn, ')') AS message;
    END IF;
END$$

DELIMITER ;

CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
```

### 6. Stored procedure — return a book

Records the return and puts the book back on the shelf in one call.

```sql
DELIMITER $$

CREATE PROCEDURE return_book(
    IN p_return_id VARCHAR(10),
    IN p_issued_id VARCHAR(10)
)
BEGIN
    DECLARE v_isbn  VARCHAR(50);
    DECLARE v_title VARCHAR(80);

    SELECT issued_book_isbn, issued_book_name INTO v_isbn, v_title
    FROM issued_status WHERE issued_id = p_issued_id;

    INSERT INTO return_status
        (return_id, issued_id, return_book_name, return_date, return_book_isbn)
    VALUES
        (p_return_id, p_issued_id, v_title, CURDATE(), v_isbn);

    UPDATE books SET status = 'yes' WHERE isbn = v_isbn;
    SELECT CONCAT('Thank you for returning: ', v_title) AS message;
END$$

DELIMITER ;

CALL return_book('RS138', 'IS135');
```

---

## 💡 Key Takeaways

- **Foreign keys protect the data.** An issue record can't point to a member, book or employee that doesn't exist.
- **"Not returned" means "no matching row".** A `LEFT JOIN` plus `IS NULL` is the cleanest way to find missing matches.
- **A self join answers hierarchy questions.** Joining `employees` to itself, through `branch.manager_id`, gives each employee's manager.
- **Procedures keep related changes together.** Issuing or returning a book touches two tables, and a procedure makes sure both are updated every time.
- **CTAS turns a query into a table.** It's a quick way to save a report that dashboards or other queries can reuse.

---

## 🔮 Future Improvements

- Add a `book_quality` / condition column on returns and report on damaged books
- Add a `fines` table and automate fine calculation with a scheduled event
- Wrap the issue/return procedures in transactions with error handling
- Add indexes on frequently joined columns and compare query plans with `EXPLAIN`
- Build a small front end (web or CLI) on top of the database

---

## 🙏 Acknowledgements

Built while following a YouTube SQL project series — *[https://youtu.be/ChIQjGBI3AM]*. The schema, queries and write-up in this repository are my own work and practice.

---

## 👤 Author

**Sumit Gupta**
BCA student, JIMS Engineering Management Technical Campus, Greater Noida

- GitHub: [Sumitgupta2005](https://github.com/Sumitgupta2005)
- LinkedIn: [sumit-gupta005](https://www.linkedin.com/in/sumit-gupta005)
- Email: sumit.gupta260373@gmail.com

⭐ If you found this useful, consider giving the repo a star!

select * from books;
select * from return_status;
select * from issued_status;
select * from employees;
select * from branch;
select * from members;

-- Project Questions

-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
insert into books(isbn, book_title, category, rental_price, status, author, publisher)
values ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
-- Task 2: Update an Existing Member's Address
update members set member_address = '124 Main St' where member_id = 'C101';
-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
delete from issued_status where issued_id = 'IS121';
-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
select * from issued_status where issued_emp_id = 'E101';
-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
select issued_emp_id, count(issued_emp_id) from issued_status group by issued_emp_id having count(issued_emp_id) > 1;

-- CTAS (Create Table As Select)

-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
create table books_count as
select book_title, count(issued_book_isbn) from books b
join issued_status iss 
on b.isbn = iss.issued_book_isbn
group by book_title;

select * from books_count;
-- Task 7: Retrieve All Books in a Specific Category:
select * from books where category = 'Children';
-- Task 8: Find Total Rental Income by Category:
select category, sum(rental_price) from books group by 1;
-- Task 9: List Members Who Registered in the Last 180 Days:
SELECT * FROM members WHERE reg_date >= DATE_SUB(CURDATE(), INTERVAL 180 DAY);
-- Task 10: List Employees with Their Branch Manager's Name and their branch details:
select *
from employees e
join
 branch b 
 on e.branch_id = b.branch_id
 join employees em
 on b.manager_id = em.emp_id;
-- Task 11: Create a Table of Books with Rental Price Above a Certain Threshold 7USD:
create table RentalpriceSeven as
select * from books where rental_price > 7;

select * from RentalpriceSeven;
-- Task 12: Retrieve the List of Books Not Yet Returned
select issued_book_name, issued_emp_id 
from issued_status ist
left join return_status rst
on ist.issued_id = rst.issued_id
where return_date is null;

-- Advanced Queries

/* Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name,
book title, issue date, and days overdue. */

select m.member_id, m.member_name, b.book_title, ist.issued_date, rst.return_date, DATEDIFF(CURRENT_DATE, ist.issued_date) AS daysSinceIssued
from issued_status ist
join books b
on ist.issued_book_isbn = b.isbn
join members m
on ist.issued_member_id = m.member_id
left join return_status rst
on ist.issued_id = rst.issued_id
where rst.return_date is null;

/*Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).*/

UPDATE books b
JOIN issued_status ist
    ON b.isbn = ist.issued_book_isbn
JOIN return_status rs
    ON ist.issued_id = rs.issued_id
SET b.status = 'Yes'
WHERE rs.return_date IS NOT NULL;

/* Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned,
and the total revenue generated from book rentals. */


DELIMITER $$

CREATE PROCEDURE BRANCH_REPORT()
BEGIN
    SELECT
        br.branch_id,
        COUNT(ist.issued_id) AS books_issued,
        COUNT(rst.return_id) AS books_returned,
        SUM(b.rental_price) AS total_revenue
    FROM branch br
    JOIN employees e
        ON br.branch_id = e.branch_id
    JOIN issued_status ist
        ON e.emp_id = ist.issued_emp_id
    JOIN books b
        ON ist.issued_book_isbn = b.isbn
    LEFT JOIN return_status rst
        ON ist.issued_id = rst.issued_id
    GROUP BY br.branch_id;
END $$

DELIMITER ;

call BRANCH_REPORT();

/* Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued
 at least one book in the last 2 months.*/

create table active_member as
select * 
from issued_status ist
join members m
on ist.issued_member_id = m.member_id
where ist.issued_date >= date_sub(current_date, interval 2 month);

select * from active_member;

/* Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name,
 number of books processed, and their branch. */

SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1, 2;

/*Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued books more than twice with the status "damaged" in the books table.
 Display the member name, book title, and the number of times they've issued damaged books.*/
 
 SELECT
    m.member_name,
    b.book_title,
    COUNT(ist.issued_id) AS times_issued
FROM members m
JOIN issued_status ist
    ON m.member_id = ist.issued_member_id
JOIN books b
    ON ist.issued_book_isbn = b.isbn
WHERE b.status = 'damaged'
GROUP BY m.member_id, m.member_name, b.isbn, b.book_title
HAVING COUNT(ist.issued_id) > 2;
 
/*Task 19: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. Description:
 Write a stored procedure that updates the status of a book in the library based on its issuance. 
 The procedure should function as follows: The stored procedure should take the book_id as an input parameter.
 The procedure should first check if the book is available (status = 'yes'). If the book is available, it should be issued, and 
 the status in the books table should be updated to 'no'. If the book is not available (status = 'no'), the procedure should return an
 error message indicating that the book is currently not available.*/


DELIMITER $$

CREATE PROCEDURE ISSUE_BOOK(IN p_book_id INT)
BEGIN
    DECLARE v_status VARCHAR(20);

    SELECT status
    INTO v_status
    FROM books
    WHERE book_id = p_book_id;

    IF v_status = 'yes' THEN
        UPDATE books
        SET status = 'no'
        WHERE book_id = p_book_id;

        SELECT 'Book issued successfully' AS message;
    ELSE
        SELECT 'Book is currently not available' AS message;
    END IF;
END $$

DELIMITER ;

CALL ISSUE_BOOK(1);

/* Task 20: Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate
 fines. Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned 
 within 30 days. The table should include: The number of overdue books. The total fines, with each day's fine calculated at $0.50. 
 The number of books issued by each member. The resulting table should show: Member ID Number of overdue books Total fines */


CREATE TABLE overdue_books_report AS
SELECT
    ist.issued_member_id AS member_id,
    COUNT(
        CASE
            WHEN DATEDIFF(CURRENT_DATE, ist.issued_date) > 30
                 AND rst.return_date IS NULL
            THEN ist.issued_id
        END
    ) AS overdue_books,

    SUM(
        CASE
            WHEN DATEDIFF(CURRENT_DATE, ist.issued_date) > 30
                 AND rst.return_date IS NULL
            THEN (DATEDIFF(CURRENT_DATE, ist.issued_date) - 30) * 0.50
            ELSE 0
        END
    ) AS total_fines,

    COUNT(ist.issued_id) AS total_books_issued

FROM issued_status ist
LEFT JOIN return_status rst
    ON ist.issued_id = rst.issued_id
GROUP BY ist.issued_member_id;




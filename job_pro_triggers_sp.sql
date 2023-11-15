
/** View function for benefits **/
CREATE VIEW title_company_benefits AS 
SELECT jp.title ,name AS company_name,type AS benefits_type
FROM benefits b join job_postings jp on b.job_id = jp.job_id 
JOIN companies c on jp.company_id = c.company_id;
SELECT company_name, count(benefits_type) from title_company_benefits GROUP BY company_name;
SELECT benefits_type,count(company_name) from title_company_benefits GROUP BY benefits_type;


/**Stored Procedure for company info**/
DELIMITER //
CREATE PROCEDURE GetCompInfo(IN company_name_param VARCHAR(100))
BEGIN
    SELECT
        DISTINCT c.name AS Company_name,
        ci.industry,
        ec.employee_count
          FROM companies c
    JOIN company_industries ci ON c.company_id = ci.company_id
    JOIN employee_counts ec ON ci.company_id = ec.company_id
    WHERE c.name = company_name_param;
END;
// 
DELIMITER ;
CALL GetCompInfo('Intertek');

/**Stored Procedure for company details**/
DELIMITER //
CREATE PROCEDURE GetCompanyDetailsByID(IN company_id INT)
BEGIN
    SELECT c.name, c.description, i.industry
    FROM companies c
    LEFT JOIN company_industries i ON c.company_id = i.company_id
    WHERE c.company_id = company_id;
END;
//
DELIMITER ;

CALL GetCompanyDetailsByID(1009);
/** Trigger to Update Employee Count and Follower Count (defaults to 0 for new company) 
in employee_counts Table when a new company is added to the companies table **/

CREATE TABLE employee_count_audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    company_id INT,
    employee_count_after INT,
    time_recorded TIMESTAMP
);

DELIMITER //
CREATE TRIGGER update_employee_follower_count
AFTER INSERT ON companies
FOR EACH ROW
BEGIN
    INSERT INTO employee_counts (company_id, employee_count, time_recorded)
    VALUES (NEW.company_id, NEW.company_size, NOW());

    -- Add the audit log entry
    INSERT INTO employee_count_audit_log (company_id, employee_count_after, time_recorded)
    VALUES (NEW.company_id, NEW.company_size, NOW());
END;
//
DELIMITER ;


INSERT INTO companies (company_id, name, description, company_size, state, country, city, zip_code, address, url)
VALUES (101, 'Sample Company', 'This is a test company', 100, 'California', 'USA', 'San Francisco', '12345', '123 Main St', 'http://www.samplecompany.com');

/** A stored procedure to find avg max salary, avg med salary and avg min salary by passing job title. **/
DELIMITER //

CREATE PROCEDURE CalculateAverageSalaryForJobTitle(IN job_title VARCHAR(255), OUT avg_max_salary DECIMAL(10, 2), OUT avg_med_salary DECIMAL(10, 2), OUT avg_min_salary DECIMAL(10, 2))
BEGIN
    SELECT AVG(max_salary) INTO avg_max_salary
    FROM job_postings
    WHERE title = job_title;

    SELECT AVG(med_salary) INTO avg_med_salary
    FROM job_postings
    WHERE title = job_title;

    SELECT AVG(min_salary) INTO avg_min_salary
    FROM job_postings
    WHERE title = job_title;
END;
//
DELIMITER ;

CALL CalculateAverageSalaryForJobTitle('Software Engineer', @avg_max_salary, @avg_med_salary, @avg_min_salary);
SELECT @avg_max_salary, @avg_med_salary, @avg_min_salary;

/** A trigger that logs changes made to job postings, recording the old and new data in an audit table. **/
CREATE TABLE job_posting_audit (
    action_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    job_id INT,
    title VARCHAR(255),
    old_max_salary DECIMAL(10, 2),
    new_max_salary DECIMAL(10, 2),
    old_med_salary DECIMAL(10, 2),
    new_med_salary DECIMAL(10, 2),
    old_min_salary DECIMAL(10, 2),
    new_min_salary DECIMAL(10, 2),
    timestamp TIMESTAMP
);

DELIMITER //

CREATE TRIGGER JobPostingAuditUpdate
AFTER UPDATE ON job_postings
FOR EACH ROW
BEGIN
    INSERT INTO job_posting_audit (action_type, job_id, title, old_max_salary, new_max_salary, old_med_salary, new_med_salary, old_min_salary, new_min_salary, timestamp)
    VALUES ('INSERT', NEW.job_id, NEW.title, OLD.max_salary, NEW.max_salary, old.med_salary, NEW.med_salary, old.min_salary, NEW.min_salary, NOW());
END;
//
DELIMITER ;
SET SQL_SAFE_UPDATES = 0;
UPDATE job_postings set max_salary = 300000,med_salary=10000,min_salary=1500 where job_id=903408693 and company_id=3894635;

/** A trigger for job salary alerts **/
CREATE TABLE log_table (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    log_message TEXT,
    log_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER SalaryAlert
AFTER INSERT ON job_postings
FOR EACH ROW
BEGIN
    IF NEW.max_salary < 30000 OR NEW.max_salary > 1500000 THEN
        INSERT INTO log_table (log_message)
        VALUES (CONCAT('Salary Alert: Unusual salary range detected for job posting ', NEW.job_id));
    END IF;
END;
//
DELIMITER ;

INSERT INTO job_postings (job_id, company_id, max_salary)
VALUES (993408693, 3894635, 11119999);
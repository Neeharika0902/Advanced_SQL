-- 1. Find the job postings for companies with more than 1000 followers.
SELECT 
    title
FROM
    job_postings
WHERE
    company_id IN (SELECT 
            company_id
        FROM
            employee_counts
        WHERE
            follower_count > 1000);


-- 2. Count the number of job postings for each company.
SELECT 
    c.name AS company_name, COUNT(jp.job_id) AS job_count
FROM
    companies c
        LEFT JOIN
    job_postings jp ON c.company_id = jp.company_id
GROUP BY c.name
ORDER BY job_count DESC;

-- 3. Rank job postings by the number of views within their respective companies and display the companies in ascending order.
SELECT title, company_name, views, view_rank
FROM (
    SELECT jp.title, c.name AS company_name, jp.views, jp.company_id,
           RANK() OVER (PARTITION BY jp.company_id ORDER BY jp.views DESC) AS view_rank
    FROM job_postings jp
    JOIN companies c ON jp.company_id = c.company_id
    WHERE jp.views IS NOT NULL
) AS subquery
ORDER BY company_name, view_rank;

-- 4. Select job postings with above-average salaries within their respective companies
WITH CompanyAverage AS (
    SELECT jp.company_id, AVG(jp.max_salary) AS avg_company_level_salary
    FROM job_postings jp
    GROUP BY jp.company_id
)
SELECT c.name AS company_name, jp.title, jp.max_salary, ca.avg_company_level_salary
FROM job_postings jp
JOIN CompanyAverage ca ON jp.company_id = ca.company_id
JOIN companies c ON jp.company_id = c.company_id
WHERE jp.max_salary > ca.avg_company_level_salary;

-- 5. Retrieve job postings that require a specific skill abbreviation (e.g., "QA").
SELECT 
    jp.title, jp.description
FROM
    job_postings jp
WHERE
    jp.job_id IN (SELECT 
            job_id
        FROM
            job_skills
        WHERE
            skill_abr = 'QA');

-- 6. Find the top 3 job postings with the most views within each company.
SELECT title, company_name, views, view_rank
FROM (
  SELECT jp.title, c.name AS company_name, jp.views, jp.company_id,
         DENSE_RANK() OVER (PARTITION BY jp.company_id ORDER BY jp.views DESC) AS view_rank
  FROM job_postings jp
  JOIN companies c ON jp.company_id = c.company_id
  WHERE jp.views IS NOT NULL
) AS subquery
WHERE view_rank <= 3;

-- 7. Find companies that have more than 5 job postings and are located in a specific state (e.g., "California").
SELECT 
    c.name AS company_name, COUNT(jp.job_id) AS job_count
FROM
    companies c
        LEFT JOIN
    job_postings jp ON c.company_id = jp.company_id
WHERE
    c.state = 'California'
GROUP BY c.name
HAVING job_count > 5;


-- 8. Find the average number of job postings in companies of each size category.
SELECT 
    c.company_size, AVG(job_count) AS avg_job_count
FROM
    (SELECT 
        company_id, COUNT(job_id) AS job_count
    FROM
        job_postings
    GROUP BY company_id) AS jp_count
        JOIN
    companies AS c ON jp_count.company_id = c.company_id
        JOIN
    employee_counts AS ec ON c.company_id = ec.company_id
GROUP BY c.company_size;


-- 9. Get the three companies with the most job postings.
SELECT 
    name, job_count
FROM
    companies
        JOIN
    (SELECT 
        company_id, COUNT(job_id) AS job_count
    FROM
        job_postings
    GROUP BY company_id) AS jp_count ON companies.company_id = jp_count.company_id
ORDER BY job_count DESC
LIMIT 3;

-- 10. Find the top-paying company for each skill abbreviation, considering only job postings that require that specific skill. 
WITH SkillMaxSalaries AS (
    SELECT js.skill_abr, MAX(jp.max_salary) AS max_salary
    FROM job_skills js
    JOIN job_postings jp ON js.job_id = jp.job_id
    GROUP BY js.skill_abr
)
, TopCompanyForSkill AS (
    SELECT js.skill_abr, jp.company_id, jp.max_salary
    FROM job_skills js
    JOIN job_postings jp ON js.job_id = jp.job_id
    WHERE (js.skill_abr, jp.max_salary) IN (
        SELECT skill_abr, max_salary
        FROM SkillMaxSalaries
    )
)
SELECT DISTINCT c.name AS company_name, tcs.skill_abr, tcs.max_salary
FROM TopCompanyForSkill tcs
JOIN companies c ON tcs.company_id = c.company_id;


-- 11. List companies that have job postings with the highest maximum salary and are located in a specific state (e.g., "California").
SELECT 
    c.name AS company_name
FROM
    companies c
WHERE
    c.state = 'California'
        AND c.company_id IN (SELECT 
            jp1.company_id
        FROM
            job_postings jp1
        WHERE
            jp1.max_salary = (SELECT 
                    MAX(jp2.max_salary)
                FROM
                    job_postings jp2
                WHERE
                    jp2.company_id = jp1.company_id));

-- 12. List the jobs that pay above average for similar jobs.
SELECT 
    jp.title, jp.max_salary, ja.avg_salary
FROM
    job_postings jp
        JOIN
    (SELECT 
        title, ROUND(AVG(max_salary), 2) AS avg_salary
    FROM
        job_postings
    GROUP BY title) ja ON jp.title = ja.title
WHERE
    jp.max_salary > ja.avg_salary;

-- 13. List companies with Rank based on difference between follower count according to change in time.
WITH FollowerDifferences AS (
    SELECT
        subquery.company_id,
        subquery.time_recorded,
        MAX(subquery.follower_count - subquery.prev_follower_count) AS max_follower_count_difference
    FROM (
        SELECT
            ec.company_id,
            ec.follower_count,
            ec.time_recorded,
            LAG(ec.follower_count) OVER (PARTITION BY ec.company_id ORDER BY ec.time_recorded) AS prev_follower_count
        FROM
            employee_counts AS ec
    ) AS subquery
    GROUP BY
        subquery.company_id, subquery.time_recorded
)
SELECT
    c.company_id,
    c.name AS company_name,
    fd.time_recorded,
    IFNULL(fd.max_follower_count_difference, 0) AS max_follower_count_difference,
    RANK() OVER (ORDER BY fd.max_follower_count_difference DESC, fd.time_recorded) AS ranks
FROM
    companies AS c
LEFT JOIN
    FollowerDifferences AS fd
ON
    c.company_id = fd.company_id
ORDER BY
    ranks;

 -- 14..List the companies that have 'technology' or 'software' in their descriptions, and how are they categorized by company size, with only one company listed per size category based on alphabetical order of company names
WITH CompaniesWithKeywords AS (
    SELECT name, description, company_size,
           ROW_NUMBER() OVER (PARTITION BY company_size ORDER BY name) AS row_num
    FROM companies
    WHERE description LIKE '%technology%' OR description LIKE '%software%'
)
SELECT name, description, company_size
FROM CompaniesWithKeywords
WHERE row_num = 1;

-- 15.List of formatted_work_type values for companies in California, sorted by company_size, and ranked within each company size category.    
WITH RankedWorkTypes AS (
    SELECT
        c.company_size,
        jp.formatted_work_type,
        RANK() OVER (PARTITION BY c.company_size ORDER BY jp.formatted_work_type) AS work_type_rank
    FROM companies AS c
    JOIN job_postings AS jp ON c.company_id = jp.company_id
    WHERE c.state = 'California'
)
SELECT
    company_size,
    formatted_work_type
FROM RankedWorkTypes
ORDER BY company_size, work_type_rank;

-- 16.List the medical benefits of small scale company(small scale company usually provides medical insurance)
SELECT c.company_id, c.company_size, b.type
FROM companies AS c
JOIN benefits AS b ON c.company_id = b.job_id
WHERE c.company_size = '1';


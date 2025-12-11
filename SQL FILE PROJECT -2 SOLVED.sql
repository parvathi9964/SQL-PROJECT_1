select * from salaries$;


-------1. Employees by company size in 2021
SELECT company_size, COUNT(*) AS employee_count
FROM salaries$
WHERE work_year = 2021
GROUP BY company_size;

-----2. Top 3 highest average salary PT job titles in 2023 (countries with >50 employees)
SELECT TOP 3 job_title, AVG(salary_in_usd) AS avg_salary
FROM salaries$
WHERE employment_type='PT' AND work_year = 2023
GROUP BY job_title
HAVING COUNT(*) > 50
ORDER BY avg_salary DESC;

----3. Countries where mid-level salary is higher than overall mid-level avg in 2023
WITH avg_global AS (
    SELECT AVG(salary_in_usd) AS global_avg
    FROM salaries$
    WHERE experience_level='MI' AND work_year=2023
)
SELECT employee_residence, AVG(salary_in_usd) AS avg_salary
FROM salaries$, avg_global
WHERE experience_level='MI' AND work_year=2023
GROUP BY employee_residence
HAVING AVG(salary_in_usd) > global_avg;

----4. Highest/Lowest avg salary for senior-level employees in 2023
SELECT TOP 1 company_location, AVG(salary_in_usd) AS avg_salary
FROM salaries$
WHERE experience_level='SE' AND work_year=2023
GROUP BY company_location
ORDER BY avg_salary DESC;

SELECT TOP 1 company_location, AVG(salary_in_usd) AS avg_salary
FROM salaries$
WHERE experience_level='SE' AND work_year=2023
GROUP BY company_location
ORDER BY avg_salary ASC;

-------5. Salary growth rate by job title (2023 to 2024)
SELECT t2023.job_title,
       ((t2024.avg_salary - t2023.avg_salary) / t2023.avg_salary) * 100 AS growth_percent
FROM (
    SELECT job_title, AVG(salary_in_usd) AS avg_salary
    FROM salaries$ WHERE work_year=2023 GROUP BY job_title
) t2023
JOIN (
    SELECT job_title, AVG(salary_in_usd) AS avg_salary
    FROM salaries$ WHERE work_year=2024 GROUP BY job_title
) t2024
ON t2023.job_title = t2024.job_title;

-----6. Top 3 countries with highest salary growth for entry-level (2020–2023)
WITH cte AS (
    SELECT employee_residence,
           AVG(CASE WHEN work_year=2020 THEN salary_in_usd END) AS sal_2020,
           AVG(CASE WHEN work_year=2023 THEN salary_in_usd END) AS sal_2023,
           COUNT(*) AS emp_count
    FROM salaries$
    WHERE experience_level='EN'
    GROUP BY employee_residence
)
SELECT TOP 3 employee_residence,
       ((sal_2023 - sal_2020) / sal_2020) * 100 AS growth_percent
FROM cte
WHERE emp_count > 50
ORDER BY growth_percent DESC;

-----7. Update remote ratio for >$90k in US and AU
UPDATE salaries$
SET remote_ratio = 100
WHERE salary_in_usd > 90000
AND employee_residence IN ('US','AU');

--------8. Update salaries by % increase in 2024
UPDATE salaries$
SET salary_in_usd =
    CASE
        WHEN experience_level='SE' THEN salary_in_usd * 1.22
        WHEN experience_level='MI' THEN salary_in_usd * 1.30
        WHEN experience_level='EN' THEN salary_in_usd * 1.15
        ELSE salary_in_usd
    END
WHERE work_year = 2024;

----9. Year with highest avg salary per job title
WITH cte AS (
    SELECT job_title, work_year, AVG(salary_in_usd) AS avg_salary
    FROM salaries$ GROUP BY job_title, work_year
)
SELECT job_title, work_year, avg_salary
FROM cte c
WHERE avg_salary = (
    SELECT MAX(avg_salary)
    FROM cte c2
    WHERE c2.job_title = c.job_title
);

-----10. Percentage of FT/PT by job title
SELECT job_title,
       100.0 * SUM(CASE WHEN employment_type='FT' THEN 1 END) / COUNT(*) AS pct_ft,
       100.0 * SUM(CASE WHEN employment_type='PT' THEN 1 END) / COUNT(*) AS pct_pt
FROM salaries$
GROUP BY job_title;

--------11. Countries offering full remote for managers >$90k
SELECT employee_residence
FROM salaries$
WHERE job_title LIKE '%Manager%'
AND salary_in_usd > 90000
AND remote_ratio = 100
GROUP BY employee_residence;

----12. Top 5 countries with most large companies
SELECT TOP 5 company_location, COUNT(*) AS company_count
FROM salaries$
WHERE company_size='L'
GROUP BY company_location
ORDER BY company_count DESC;

----13. Percentage fully remote earning >$100k
SELECT (100.0 * SUM(CASE WHEN remote_ratio=100 AND salary_in_usd>100000 THEN 1 END) / COUNT(*)) AS pct_remote_highpay
FROM salaries$;

----14. Locations where EN-level avg exceeds global avg
WITH g AS (
    SELECT AVG(salary_in_usd) AS global_avg
    FROM salaries$ WHERE experience_level='EN'
)
SELECT company_location, AVG(salary_in_usd) AS avg_salary
FROM salaries$, g
WHERE experience_level='EN'
GROUP BY company_location
HAVING AVG(salary_in_usd) > global_avg;

----15. Highest paying country per job title
WITH cte AS (
    SELECT job_title, employee_residence, AVG(salary_in_usd) AS avg_salary
    FROM salaries$ GROUP BY job_title, employee_residence
)
SELECT job_title, employee_residence, avg_salary
FROM (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY job_title ORDER BY avg_salary DESC) AS rn
    FROM cte
) A
WHERE rn=1;

-----16. Countries with sustained growth (2021–2023)
WITH cte AS (
    SELECT employee_residence,
           AVG(CASE WHEN work_year=2021 THEN salary_in_usd END) AS s1,
           AVG(CASE WHEN work_year=2022 THEN salary_in_usd END) AS s2,
           AVG(CASE WHEN work_year=2023 THEN salary_in_usd END) AS s3
    FROM salaries$
    GROUP BY employee_residence
)
SELECT employee_residence
FROM cte
WHERE s1 < s2 AND s2 < s3;

---17. Fully remote % by experience level 2021 vs 2024
SELECT experience_level,
       100.0 * SUM(CASE WHEN work_year=2021 AND remote_ratio=100 THEN 1 END) /
           SUM(CASE WHEN work_year=2021 THEN 1 END) AS pct_2021,
       100.0 * SUM(CASE WHEN work_year=2024 AND remote_ratio=100 THEN 1 END) /
           SUM(CASE WHEN work_year=2024 THEN 1 END) AS pct_2024
FROM salaries$
GROUP BY experience_level;

-----18. Avg salary increase % by level & title (2023–2024)
WITH t23 AS (
    SELECT job_title, experience_level, AVG(salary_in_usd) AS avg23
    FROM salaries$ WHERE work_year=2023 GROUP BY job_title, experience_level
),
t24 AS (
    SELECT job_title, experience_level, AVG(salary_in_usd) AS avg24
    FROM salaries$ WHERE work_year=2024 GROUP BY job_title, experience_level
)
SELECT t23.job_title, t23.experience_level,
       ((t24.avg24 - t23.avg23) / t23.avg23) * 100 AS pct_increase
FROM t23 JOIN t24
ON t23.job_title=t24.job_title AND t23.experience_level=t24.experience_level;




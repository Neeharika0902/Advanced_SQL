ALTER TABLE job_postings MODIFY COLUMN company_id BIGINT;
ALTER TABLE job_skills MODIFY COLUMN skill_abr VARCHAR(5);
ALTER TABLE benefits MODIFY COLUMN type VARCHAR(75);
ALTER TABLE company_specialities MODIFY COLUMN speciality VARCHAR(1040);
ALTER TABLE company_industries MODIFY COLUMN industry VARCHAR(100);


SET FOREIGN_KEY_CHECKS=0; -- Since data is already inserted in the tables, disable the check during foreign key creation

-- 1. companies
-- Primary Key
ALTER TABLE companies
ADD PRIMARY KEY (company_id);

-- 2. job_postings
-- Primary Key
ALTER TABLE job_postings
ADD PRIMARY KEY (job_id);
-- Foreign Key
ALTER TABLE job_postings
ADD FOREIGN KEY (company_id) REFERENCES companies(company_id);

-- 3. job_skills
-- Primary Key
ALTER TABLE job_skills
ADD PRIMARY KEY (job_id, skill_abr);
-- Foreign Key
ALTER TABLE job_skills
ADD FOREIGN KEY (job_id) REFERENCES job_postings(job_id);

-- 4. job_industries
-- Primary Key
ALTER TABLE job_industries
ADD PRIMARY KEY (job_id, industry_id);
-- Foreign Key
ALTER TABLE job_industries
ADD FOREIGN KEY (job_id) REFERENCES job_postings(job_id);

-- 5. benefits
-- Primary Key
ALTER TABLE benefits
ADD PRIMARY KEY (job_id, inferred, type);
-- Foreign Key
ALTER TABLE benefits
ADD FOREIGN KEY (job_id) REFERENCES job_postings(job_id);


-- 6. employee_counts
-- Primary Key
ALTER TABLE employee_counts
ADD PRIMARY KEY (company_id, time_recorded);
-- Foreign Key
ALTER TABLE employee_counts
ADD FOREIGN KEY (company_id) REFERENCES companies(company_id);


-- 7. company_specialities
-- Foreign Key
ALTER TABLE company_specialities
ADD FOREIGN KEY (company_id) REFERENCES companies(company_id);


-- 8. company_industries
-- Primary Key
ALTER TABLE company_industries
ADD PRIMARY KEY (company_id, industry);
-- Foreign Key
ALTER TABLE company_industries
ADD FOREIGN KEY (company_id) REFERENCES companies(company_id);

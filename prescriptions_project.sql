-- Prescribers Database
-- For this exericse, you'll be working with a database derived from the Medicare Part D Prescriber Public Use File. 
-- More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.

-- 1.	a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and
-- the total number of claims.
SELECT npi, SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 5 --1881634483 (99707 total claim count)

-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  
-- specialty_description, and the total number of claims.
SELECT p1.nppes_provider_first_name, 
	p1.nppes_provider_last_org_name, 
	p1.specialty_description, 
	p2.total_claim_count
FROM prescriber AS p1
INNER JOIN prescription AS p2 
	ON  p2.npi = p1.npi
ORDER BY total_claim_count DESC
LIMIT 5 -- David Coffey, Family Practice, (4538 total claim count)

-- 2.	a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT p1.specialty_description AS specialty,
    SUM(p2.total_claim_count) AS total_claims
FROM prescriber AS p1
LEFT JOIN prescription AS p2 
    ON p1.npi = p2.npi
WHERE p2.total_claim_count IS NOT NULL
GROUP BY p1.specialty_description
ORDER BY total_claims DESC
LIMIT 5; --Family Practice (9,752,347)

-- b. Which specialty had the most total number of claims for opioids?
SELECT p1.specialty_description AS specialty,
    SUM (p2.total_claim_count) AS claims_for_opioids
FROM prescriber AS p1
INNER JOIN prescription AS p2 
    ON p1.npi = p2.npi
INNER JOIN drug AS d 
    ON d.drug_name = p2.drug_name
WHERE d.opioid_drug_flag = 'Y'
GROUP BY p1.specialty_description
ORDER BY claims_for_opioids DESC
LIMIT 5; --Nurse Practitioner (total claims 900,845)

-- c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated 
-- prescriptions in the prescription table?

-- d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the
-- percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of
-- opioids?

-- 3.	a. Which drug (generic_name) had the highest total drug cost?
SELECT d.generic_name,
    SUM(p.total_drug_cost) AS total_cost
FROM prescription AS p
INNER JOIN drug AS d
    ON d.drug_name = p.drug_name
GROUP BY d.generic_name
ORDER BY total_cost DESC
LIMIT 5; --Insulin Glargine,hum.rec.anlog ($104,264,066.35)



SELECT *
FROM prescription

-- b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2
-- decimal places. Google ROUND to see how this works.
SELECT d.generic_name,
    round(SUM(p.total_drug_cost) / SUM(p.total_day_supply),2) AS avg_daily_cost
FROM drug AS d
INNER JOIN prescription AS p
    ON p.drug_name = d.drug_name
GROUP BY d.generic_name
ORDER BY avg_daily_cost DESC
LIMIT 5; --C1 Esterase Inhibitor ($3,495.22)

-- 4.	a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 
-- 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have
-- antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression
-- for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
SELECT drug_name,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END AS drug_type
FROM drug

-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids
-- or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT 
    CASE 
        WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
    END AS drug_type,
    CAST(SUM(p.total_drug_cost) AS MONEY) AS total_cost
FROM drug AS d
JOIN prescription AS p
    ON d.drug_name = p.drug_name
WHERE d.opioid_drug_flag = 'Y' OR d.antibiotic_drug_flag = 'Y'
GROUP BY drug_type
ORDER BY total_cost DESC; --Opioid ($105,080,626.37)

-- 5.	a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just
-- Tennessee.

SELECT COUNT (*) AS total_cbsa_in_TN
FROM cbsa
WHERE cbsaname LIKE '%TN' -- 33 CBSA's

SELECT *
FROM population
ORDER BY population DESC

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total 
-- population.

SELECT c.cbsa, 
	SUM(p.population) AS combined_population
FROM cbsa AS c
INNER JOIN zip_fips AS z
	ON z.fipscounty = c.fipscounty
INNER JOIN population AS p
	ON p.fipscounty = z.fipscounty
GROUP BY c.cbsa
ORDER BY combined_population DESC
LIMIT 5

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name
-- and population.

-- 6.	a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and
-- the total_claim_count.

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name 
-- associated with each row.

-- 7.	The goal of this exercise is to generate a full list of all pain management specialists in Nashville and 
-- the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management specialists 
-- (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'),
-- where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. 
-- You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or 
-- not the prescriber had any claims. You should report the npi, the drug name, and the number of claims
-- (total_claim_count).

-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 
-- Hint - Google the COALESCE function.
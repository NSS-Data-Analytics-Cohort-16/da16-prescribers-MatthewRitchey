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

SELECT DISTINCT p.specialty_description
FROM prescriber AS p
LEFT JOIN prescription AS pr
    ON p.npi = pr.npi
WHERE pr.npi IS NULL; -- 92 rows

-- d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the
-- percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of
-- opioids?

SELECT p1.specialty_description,
       SUM(p2.total_claim_count) AS total_claims,
       SUM(CASE WHEN d.opioid_drug_flag = 'Y' THEN p2.total_claim_count ELSE 0 END) AS opioid_claims,
       ROUND(
           (SUM(CASE WHEN d.opioid_drug_flag = 'Y' THEN p2.total_claim_count ELSE 0 END) * 100.0) /
           SUM(p2.total_claim_count), 2
       ) AS opioid_percentage
FROM prescriber AS p1
JOIN prescription AS p2 ON p1.npi = p2.npi
JOIN drug AS d ON p2.drug_name = d.drug_name
GROUP BY p1.specialty_description
ORDER BY opioid_percentage DESC;

-- 3.	a. Which drug (generic_name) had the highest total drug cost?

SELECT d.generic_name,
    SUM(p.total_drug_cost) AS total_cost
FROM prescription AS p
INNER JOIN drug AS d
    ON d.drug_name = p.drug_name
GROUP BY d.generic_name
ORDER BY total_cost DESC
LIMIT 5; --Insulin Glargine,hum.rec.anlog ($104,264,066.35)

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
INNER JOIN prescription AS p
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
FROM prescriber
ORDER BY population DESC

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total 
-- population.

--top 5 CBSA's by population
SELECT * FROM (
	SELECT c.cbsa, 
		SUM(p.population) AS combined_population
	FROM cbsa AS c
	INNER JOIN zip_fips AS z
		ON z.fipscounty = c.fipscounty
	INNER JOIN population AS p
		ON p.fipscounty = z.fipscounty
	GROUP BY c.cbsa
	ORDER BY combined_population DESC
	LIMIT 1)
AS top_CBSA

UNION

--bottom 5 CBSA's by population
SELECT * FROM(
	SELECT c.cbsa, 
		SUM(p.population) AS combined_population
	FROM cbsa AS c
	INNER JOIN zip_fips AS z
		ON z.fipscounty = c.fipscounty
	INNER JOIN population AS p
		ON p.fipscounty = z.fipscounty
	GROUP BY c.cbsa
	ORDER BY combined_population ASC
	LIMIT 1)
AS bottom_CBSA-- top CBSA 32820 (population 67,870,189) - bottom CBSA 34100 (1,163,520)

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name
-- and population.

SELECT f.county,
	SUM(p.population) AS total_population
FROM population AS p
LEFT JOIN fips_county AS f
	ON f.fipscounty = p.fipscounty
LEFT JOIN cbsa AS c
	ON c.fipscounty = p.fipscounty
WHERE c.cbsa IS NULL
GROUP BY f.county
ORDER BY total_population DESC
LIMIT 5 -- Sevier (population 95,523)

-- 6.	a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and
-- the total_claim_count.

SELECT drug_name,
	total_claim_count
FROM prescription
WHERE total_claim_count >=3000
ORDER BY total_claim_count DESC-- 9 rows

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT p.drug_name,
	p.total_claim_count,
	CASE 
		WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
        ELSE 'OTHER'
    END AS drug_type
FROM prescription AS p
JOIN drug AS d
	ON d.drug_name = p.drug_name
WHERE total_claim_count >=3000
ORDER BY total_claim_count DESC --2 opioid / 7 non

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name 
-- associated with each row.

SELECT p1.drug_name,
	p1.total_claim_count,
	p2.nppes_provider_last_org_name AS last_name,
	p2.nppes_provider_first_name AS first_name,
	CASE 
		WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
    	ELSE 'OTHER'
	END AS drug_type
FROM prescription AS p1
JOIN drug AS d
	ON d.drug_name = p1.drug_name
JOIN prescriber AS p2
	ON p2.npi = p1.npi
WHERE total_claim_count >=3000
ORDER BY total_claim_count DESC

-- 7.	The goal of this exercise is to generate a full list of all pain management specialists in Nashville and 
-- the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management specialists 
-- (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'),
-- where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. 
-- You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT p1.npi,
       d.drug_name
FROM prescriber AS p1
CROSS JOIN drug AS d
WHERE p1.specialty_description = 'Pain Management'
  AND p1.nppes_provider_city = 'NASHVILLE'
  AND d.opioid_drug_flag = 'Y';

-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or 
-- not the prescriber had any claims. You should report the npi, the drug name, and the number of claims
-- (total_claim_count).

SELECT p1.npi,
       d.drug_name,
	   p2.total_claim_count
FROM prescriber AS p1
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
	ON p2.npi = p1.npi
	AND p2.drug_name = d.drug_name
WHERE p1.specialty_description = 'Pain Management'
  AND p1.nppes_provider_city = 'NASHVILLE'
  AND d.opioid_drug_flag = 'Y';

-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 
-- Hint - Google the COALESCE function.

SELECT p1.npi,
       d.drug_name,
	   COALESCE (p2.total_claim_count, 0) AS total_claim_count
FROM prescriber AS p1
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
	ON p2.npi = p1.npi
	AND p2.drug_name = d.drug_name
WHERE p1.specialty_description = 'Pain Management'
  AND p1.nppes_provider_city = 'NASHVILLE'
  AND d.opioid_drug_flag = 'Y';
-- OPIOID CRISIS IN TN:

-- Question #2: Who are the top opioid prescribers for the state of Tennessee?

WITH docs as (SELECT npi, CONCAT(nppes_provider_last_org_name, ' ', nppes_provider_first_name) as name, nppes_provider_city, nppes_provider_zip5, specialty_description 
			 FROM prescriber
			 WHERE nppes_provider_state = 'TN'),

drug_opioids as (SELECT drug_name, generic_name
				FROM drug
				WHERE opioid_drug_flag = 'Y'),
				
zipcode_TN AS (
	SELECT zip, tot_ratio, fipscounty,
	RANK() OVER(PARTITION BY zip ORDER BY tot_ratio DESC) AS rank_zip
	FROM zip_fips
	--WHERE fipscounty LIKE '47%'
	)
		
SELECT npi, name, nppes_provider_city, nppes_provider_zip5, specialty_description, total_claim_count, generic_name, fipscounty, county 
FROM docs as d
INNER JOIN prescription 
USING (npi)
INNER JOIN drug_opioids
USING (drug_name)
INNER JOIN zipcode_TN as z
ON d.nppes_provider_zip5 = z.zip
INNER JOIN fips_county
USING (fipscounty)
WHERE rank_zip = 1;

-- Code to keep only Rank 1 from total ratio
WITH zipcode_TN AS (
	SELECT zip, tot_ratio,
	RANK() OVER(PARTITION BY zip ORDER BY tot_ratio DESC) AS rank_zip
	FROM zip_fips
	WHERE fipscounty LIKE '47%'
	)
SELECT *
FROM zipcode_TN
WHERE rank_zip = 1;

-- Question #5: Is there any association between a particular type of opioid and number of overdose deaths?

WITH drug_opioids as (SELECT drug_name, generic_name
				FROM drug
				WHERE opioid_drug_flag = 'Y'),

zipcode_TN AS (
	SELECT zip, tot_ratio, fipscounty,
	RANK() OVER(PARTITION BY zip ORDER BY tot_ratio DESC) AS rank_zip
	FROM zip_fips
	WHERE fipscounty LIKE '47%'
	)
	
SELECT generic_name, total_claim_count, population, overdose_deaths, fipscounty--, county 
FROM drug
INNER JOIN prescription
USING (drug_name)
INNER JOIN prescriber
USING (npi)
INNER JOIN zip_fips
ON nppes_provider_zip5 = zip
INNER JOIN zipcode_TN
USING (fipscounty)
INNER JOIN population
USING (fipscounty)
INNER JOIN overdose_deaths
USING (fipscounty)
WHERE rank_zip = 1;

-- get duplicated that need to be taking care of!


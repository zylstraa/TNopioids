/*NOTE Note that some zip codes will be associated with multiple fipscounty 
values in the zip_fips table. To resolve this, use the fipscounty with the 
highest tot_ratio for each zipcode.*/

--MAYBE: drugs that are administered as anti opioids

--Which Tennessee counties had a disproportionately high number of opioid prescriptions?
/* We want...
-the state of TN
-opioid drug names
-number prescribed
-population
-county names*/

WITH opioids AS (SELECT drug_name, generic_name
FROM drug
WHERE opioid_drug_flag = 'Y'),

TNdocs AS (SELECT npi, nppes_provider_zip5
FROM prescriber
WHERE nppes_provider_state = 'TN'),

opioids_prescribed AS (SELECT npi, SUM(total_claim_count) AS number_prescribed, COALESCE(SUM(total_claim_count_ge65),0) AS above65
FROM prescription AS p
JOIN opioids
USING (drug_name)
JOIN opioids AS o
ON o.generic_name = p.drug_name
GROUP BY npi),

opioids_TNdocs AS (SELECT number_prescribed, nppes_provider_zip5, above65
FROM opioids_prescribed
JOIN TNdocs
USING (npi)),

counties AS (SELECT zip, fipscounty, tot_ratio, SUM(number_prescribed) AS number_prescribed, SUM(above65) AS above65,
RANK() OVER(PARTITION BY zip ORDER BY tot_ratio DESC) AS rank_zip
FROM zip_fips AS z
JOIN opioids_TNdocs AS o
ON z.zip = o.nppes_provider_zip5
GROUP BY zip, fipscounty, tot_ratio),

counties2 AS (SELECT county, fipscounty, number_prescribed, above65
FROM fips_county
JOIN counties
USING (fipscounty)
WHERE rank_zip = 1)

SELECT county, number_prescribed, above65, population
FROM population
JOIN counties2
USING (fipscounty);


/*use column total_claim_count_ge65 to see counties that have a larger elderly population possibly inflating the numbers, 
could possibly do some research on reasons elderly use opioids more frequently*/

--Is there an association between rates of opioid prescriptions and overdose deaths by county?
/*What I want...
-overdose_deaths table (has fips county):
	do this for the year 2017 since that's the year these prescription stats are for
	already filtered on TN
-fips_county table (to get county name)
-*/


WITH opioids AS (SELECT drug_name, generic_name
FROM drug
WHERE opioid_drug_flag = 'Y'),

TNdocs AS (SELECT npi, nppes_provider_zip5
FROM prescriber
WHERE nppes_provider_state = 'TN'),

opioids_prescribed AS (SELECT npi, SUM(total_claim_count) AS number_prescribed, COALESCE(SUM(total_claim_count_ge65),0) AS above65
FROM prescription AS p
JOIN opioids
USING (drug_name)
JOIN opioids AS o
ON p.drug_name = o.generic_name
GROUP BY npi),

opioids_TNdocs AS (SELECT number_prescribed, above65, nppes_provider_zip5
FROM opioids_prescribed
JOIN TNdocs
USING (npi)),

counties AS (SELECT zip, fipscounty, SUM(number_prescribed) AS number_prescribed, SUM(above65) AS above65,
			 RANK() OVER(PARTITION BY zip ORDER BY tot_ratio DESC) AS rank_zip
FROM zip_fips AS z
JOIN opioids_TNdocs AS o
ON z.zip = o.nppes_provider_zip5
GROUP BY zip, fipscounty, tot_ratio),

counties2 AS (SELECT county, fipscounty, number_prescribed, above65
FROM fips_county
JOIN counties
USING (fipscounty)
WHERE rank_zip = 1),

overdoses AS (SELECT SUM(overdose_deaths) AS deaths, fipscounty
FROM overdose_deaths
WHERE year = 2017
GROUP BY fipscounty),

overdoses_c AS (SELECT county, deaths, population
FROM fips_county
JOIN overdoses
USING (fipscounty)
JOIN population
USING(fipscounty))

SELECT county, SUM(number_prescribed) AS num_prescribed, SUM(above65) AS above65, deaths, population
FROM overdoses_c
JOIN counties2
USING (county)
GROUP BY county, deaths, population
ORDER BY deaths DESC;

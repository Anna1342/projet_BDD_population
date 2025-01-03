DROP DATABASE IF EXISTS popserieshistorique; -- supprimer la base avant
CREATE DATABASE popserieshistorique;
USE popserieshistorique; -- se connecter à la base
SHOW TABLES; -- y'a des petites merdes qd mm 

-- Liste des populations en 2020 avec le nom de ville, département, région.
-- marche pas
SELECT p.population, c.nomCommune, d.nomDepart, r.nomRegion 
FROM Population p
	JOIN Commune c ON p.nomCommune = c.codeCommune
	JOIN Departement d ON c.code_departement = d.codeDepart
	JOIN Region r ON d.codeRegion = r.codeRegion
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
)
AND p.annee = '2020'
GROUP BY c.nomCommune, d.nomDepart, r.nomRegion;

-- 2. Évolution de la population française de 1968 à 2020.
SELECT p.annee, SUM(p.population) AS population_totale
FROM Population p 
WHERE p.annee BETWEEN 1968 AND 2020
GROUP BY p.annee
ORDER BY p.annee;

-- 3. Liste des populations en 2020 par département / région avec leurs noms (2 requêtes).
-- Par département :
SELECT d.nomDepart, SUM(p.population) AS population_par_dep
FROM Population p
	JOIN Commune c ON c.codeCommune = p.nomCommune
	JOIN Departement d ON c.code_departement= d.codeDepart
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
)
AND p.annee = '2020'
GROUP BY d.nomDepart;

-- Par région :
SELECT r.nomRegion, SUM(p.population) AS population_par_reg
FROM Population p
	JOIN Commune c ON c.codeCommune = p.nomCommune
	JOIN Departement d ON c.code_departement= d.codeDepart
	JOIN Region r ON d.codeRegion = r.codeRegion
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
)
AND p.annee = '2020'
GROUP BY r.nomRegion;

-- 4. Pop de Paris au total et par arrondissement. Quel est le problème? 
-- la population est en double comptage si chque arrondissement enregistré
 -- arr compté une commune distincte avec un codGeo spé,
 -- ville à la x comme entité globale et via ses arrondissements.
 -- =>duplication/incohérence
 -- probleme à corriger dans toutes les autres requetes 
-- 4.1 Pop de Paris au total
SELECT c.nomCommune, SUM(p.population) AS population_paris_total -- au total 
FROM Population p
	JOIN Commune c ON p.nomCommune = c.codeCommune
WHERE c.nomCommune = 'Paris' AND c.codeCommune NOT LIKE '751%' -- exclu les arrondissements de Paris
  AND p.annee = '2020'
GROUP BY c.nomCommune;
-- 4.2 Pop de Paris par arrondissement
-- 21 codegeo pour paris 75056 etant paris et les 20 autres etant les arrondissement
SELECT c.nomCommune, SUM(p.population) AS population_paris_arr -- par arrondissment
FROM Population p
	JOIN Commune c ON p.nomCommune = c.codeCommune
WHERE c.nomCommune LIKE 'Paris %'  -- selectonne tout les arr
AND p.annee = '2020'
AND c.nomCommune != 'Paris' -- verifie bien que Paris est exclu 
GROUP BY c.nomCommune;

-- Vérification somme de tous les arrondissements sont bien égales à la pop de Paris ?
SELECT SUM(p.population) AS population_totale_paris
FROM Population p
JOIN Commune c ON p.nomCommune = c.codeCommune
WHERE c.nomCommune LIKE 'Paris%' -- Sélectionne tous les arrondissements de Paris
AND c.nomCommune != 'Paris'
AND p.annee = 2020;

-- 5.1 Liste des 10 villes ayant cru le plus de 1968 à 2020.
SELECT c.nomCommune, (MAX(p.population) - MIN(p.population)) AS croissance_population
FROM Population p
JOIN Commune c ON p.nomCommune = c.codeCommune
WHERE p.annee BETWEEN 1968 AND 2020
GROUP BY c.nomCommune
ORDER BY croissance_population DESC
LIMIT 10;

-- 5.2 Liste des 10 départements ayant cru le plus de 1968 à 2020.
SELECT d.nomDepart, (MAX(p.population) - MIN(p.population)) AS croissance_population
FROM Population p
JOIN Commune c ON p.nomCommune = c.codeCommune
JOIN Departement d ON c.code_departement = d.codeDepart
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
) -- on voit que sans ce code Paris et en premier alors que non
AND p.annee BETWEEN 1968 AND 2020
GROUP BY d.nomDepart
ORDER BY croissance_population DESC
LIMIT 10;

-- 5.3 Liste des 10 régions ayant cru le plus de 1968 à 2020.
SELECT r.nomRegion, (MAX(p.population) - MIN(p.population)) AS croissance_population
FROM Population p
JOIN Commune c ON p.nomCommune = c.codeCommune
JOIN Departement d ON c.code_departement = d.codeDepart
JOIN Region r ON d.codeRegion = r.codeRegion
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
) 
AND p.annee BETWEEN 1968 AND 2020
GROUP BY r.nomRegion
ORDER BY croissance_population DESC
LIMIT 10;

-- 6.1 Liste des 10 villes où on nait le plus
SELECT c.nomCommune, SUM(e.nombre) AS total_naissances
FROM Commune c
	LEFT JOIN Evenement e ON c.codeCommune = e.nomCommune
WHERE e.categorie = 'Naissance'
AND e.periode IN ('1968-1975', '1975-1982', '1982-1990', '1990-1999', '1999-2009', '2009-2014', '2014-2020') 
GROUP BY c.nomCommune
ORDER BY total_naissances DESC
LIMIT 10;

-- 6.2 Liste des 10 villes où on meurt le plus
SELECT c.nomCommune, SUM(e.nombre) AS total_deces
FROM Commune c
	LEFT JOIN Evenement e ON c.codeCommune = e.nomCommune
WHERE e.categorie = 'Deces'
AND e.periode IN ('1968-1975', '1975-1982', '1982-1990', '1990-1999', '1999-2009', '2009-2014', '2014-2020') 
GROUP BY c.nomCommune
ORDER BY total_deces DESC
LIMIT 10;

-- 6.3 Liste des 10 départements où on nait le plus.
SELECT d.nomDepart, SUM(e.nombre) AS total_naissances
FROM Departement d
	LEFT JOIN Commune c ON d.codeDepart = c.code_departement
	LEFT JOIN Evenement e ON c.codeCommune = e.nomCommune
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
) 
AND e.categorie = 'Naissance'
AND e.periode IN ('1968-1975', '1975-1982', '1982-1990', '1990-1999', '1999-2009', '2009-2014', '2014-2020') 
GROUP BY d.nomDepart
ORDER BY total_naissances DESC
LIMIT 10;

-- 6.4 Liste des 10 départements où on meurt le plus.
SELECT d.nomDepart, SUM(e.nombre) AS total_deces
FROM Departement d
	LEFT JOIN Commune c ON d.codeDepart = c.code_departement
	LEFT JOIN Evenement e ON c.codeCommune = e.nomCommune
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
) 
AND e.categorie = 'Deces'
AND e.periode IN ('1968-1975', '1975-1982', '1982-1990', '1990-1999', '1999-2009', '2009-2014', '2014-2020') 
GROUP BY d.nomDepart
ORDER BY total_deces DESC
LIMIT 10;

-- 7.1 Liste des 10 villes avec la plus grande densité.
SELECT c.nomCommune, (SUM(p.population) / c.superficie) AS densite_population
FROM Commune c
	JOIN Population p ON c.codeCommune = p.nomCommune
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
)
AND c.superficie > 0 -- Évite la division par zéro
AND p.annee = 2020
GROUP BY c.nomCommune
ORDER BY densite_population DESC
LIMIT 10;

-- 7.2 Liste des 10 villes avec la plus petite densité.
SELECT c.nomCommune, (SUM(p.population) / c.superficie) AS densite_population
FROM Commune c
	JOIN Population p ON c.codeCommune = p.nomCommune
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
)
AND c.superficie > 0 -- Évite la division par zéro
AND p.population >0
AND p.annee = 2020
GROUP BY c.nomCommune
ORDER BY densite_population ASC
LIMIT 10;

-- 7.3 Liste des 10 départements avec la plus grande densité.
SELECT d.nomDepart, (SUM(p.population) / SUM(c.superficie)) AS densite_population
FROM Departement d 
	JOIN Commune c ON d.codeDepart = c.code_departement 
	JOIN Population p ON c.codeCommune = p.nomCommune
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
)
AND c.superficie > 0 -- Évite la division par zéro
AND p.annee = 2020
GROUP BY d.nomDepart
ORDER BY densite_population DESC
LIMIT 10;

-- 7.4 Liste des 10 départements avec la plus petite densité.
SELECT d.nomDepart, (SUM(p.population) / SUM(c.superficie)) AS densite_population
FROM Departement d 
	JOIN Commune c ON d.codeDepart = c.code_departement
	JOIN Population p ON c.codeCommune = p.nomCommune
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
)
AND c.superficie > 0 -- Évite la division par zéro
AND p.annee = 2020
GROUP BY d.nomDepart
ORDER BY densite_population ASC
LIMIT 10;

-- 8.1 Comparaison pour 2020 des naissances/décès/mouvements de population par département(Mouvements =(pop1968- pop2020)-(nais-deces)).
WITH pop2020 AS (
    SELECT SUM(p.population) AS pop_2020, d.nomDepart
    FROM Population p
    JOIN Commune c ON p.nomCommune = c.codeCommune
    JOIN Departement d ON c.code_departement = d.codeDepart
    WHERE p.annee = 2020
    GROUP BY d.nomDepart
),
pop1968 AS (
    SELECT SUM(p.population) AS pop_1968, d.nomDepart
    FROM Population p
    JOIN Commune c ON p.nomCommune = c.codeCommune
    JOIN Departement d ON c.code_departement = d.codeDepart
    WHERE p.annee = 1968
    GROUP BY d.nomDepart
)
SELECT 
    d.nomDepart, SUM(CASE WHEN e.categorie = 'Naissance' THEN e.nombre ELSE 0 END) AS Naissance_entre_2014_2020,
    SUM(CASE WHEN e.categorie = 'Deces' THEN e.nombre ELSE 0 END) AS Deces_entre_2014_2020,
    (pop2020.pop_2020 - pop1968.pop_1968) - 
    (SUM(CASE WHEN e.categorie = 'Naissance' THEN e.nombre ELSE 0 END) - 
     SUM(CASE WHEN e.categorie = 'Deces' THEN e.nombre ELSE 0 END)) AS Mouvements_Population_depuis_1968
FROM Departement d
	JOIN Commune c ON d.codeDepart = c.code_departement
	JOIN Evenement e ON c.codeCommune = e.nomCommune
	JOIN pop2020 ON d.nomDepart = pop2020.nomDepart
	JOIN pop1968 ON d.nomDepart = pop1968.nomDepart
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
)
AND e.periode ='2014-2020' 
GROUP BY d.nomDepart
ORDER BY Mouvements_Population DESC;

-- 8.2 Comparaison pour 2020 des naissances/décès/mouvements de population par région(Mouvements =deltapop(1968/2020)-(nais-deces)).
WITH pop2020 AS (
    SELECT SUM(p.population) AS pop_2020, r.nomRegion
    FROM Population p
		JOIN Commune c ON p.nomCommune = c.codeCommune
		JOIN Departement d ON c.code_departement = d.codeDepart
		JOIN Region r ON d.codeRegion = r.codeRegion
    WHERE p.annee = 2020
    GROUP BY r.nomRegion
),
pop1968 AS (
    SELECT SUM(DISTINCT p.population) AS pop_1968, r.nomRegion
    FROM Population p
    JOIN Commune c ON p.nomCommune = c.codeCommune
    JOIN Departement d ON c.code_departement = d.codeDepart
    JOIN Region r ON d.codeRegion = r.codeRegion
    WHERE p.annee = 1968
    GROUP BY r.nomRegion
)
SELECT 
    r.nomRegion, SUM(CASE WHEN e.categorie = 'Naissance' THEN e.nombre ELSE 0 END) AS Naissance_entre_2014_2020,
    SUM(CASE WHEN e.categorie = 'Deces' THEN e.nombre ELSE 0 END) AS Deces_entre_2014_2020,
    (pop2020.pop_2020 - pop1968.pop_1968) - 
    (SUM(CASE WHEN e.categorie = 'Naissance' THEN e.nombre ELSE 0 END) - 
     SUM(CASE WHEN e.categorie = 'Deces' THEN e.nombre ELSE 0 END)) AS Mouvements_Population_depuis_1968
FROM Region r
	JOIN Departement d ON r.codeRegion = d.codeRegion
	JOIN Commune c ON d.codeDepart = c.code_departement
	JOIN Evenement e ON c.codeCommune = e.nomCommune
	JOIN pop2020 ON r.nomRegion = pop2020.nomRegion
	JOIN pop1968 ON r.nomRegion = pop1968.nomRegion
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
)
AND e.periode = '2014-2020'
GROUP BY r.nomRegion
ORDER BY Mouvements_Population DESC;

-- 9. Comparaison par recensement des naissances / décès / mouvements de population de la France.
 WITH pop2020 AS (
    SELECT SUM(population) AS pop_2020
    FROM Population p
    JOIN Commune c ON p.nomCommune = c.codeCommune
    WHERE annee = 2020
),
pop1968 AS (
    SELECT SUM(population) AS pop_1968
    FROM Population p
    JOIN Commune c ON p.nomCommune = c.codeCommune
    WHERE annee = 1968
)
SELECT 'France' AS Pays, SUM(CASE WHEN e.categorie = 'Naissance' THEN e.nombre ELSE 0 END) AS Naissance_entre_2014_2020,
    SUM(CASE WHEN e.categorie = 'Deces' THEN e.nombre ELSE 0 END) AS Deces_entre_2014_2020,
    (pop2020.pop_2020 - pop1968.pop_1968) - 
    (SUM(CASE WHEN e.categorie = 'Naissance' THEN e.nombre ELSE 0 END) - 
     SUM(CASE WHEN e.categorie = 'Deces' THEN e.nombre ELSE 0 END)) AS Mouvements_Population_depuis_1968
FROM Commune c
	JOIN Evenement e ON c.codeCommune = e.nomCommune
    JOIN pop2020 ON 1=1  -- Jointure pour récupérer la population de 2020
    JOIN pop1968 ON 1=1  -- Jointure pour récupérer la population de 1968
WHERE e.periode = '2014-2020'
GROUP BY Pays;

-- Imaginez cinq autres requêtes 
-- 1. Obtenir le taux de renouvellement de la population en 2020
WITH Naissances AS (
    SELECT SUM(e.nombre) AS total_naissances
    FROM Evenement e
    WHERE e.categorie = 'Naissance' 
    AND e.periode ='2014-2020'
),
Deces AS (
    SELECT SUM(e.nombre) AS total_deces
    FROM Evenement e
    WHERE e.categorie = 'Deces'
    AND e.periode = '2014-2020'
),
PopulationTotale AS (
    SELECT SUM(p.population) AS population_totale
    FROM Population p
    WHERE p.annee = 2020
)
SELECT (n.total_naissances - d.total_deces) / p.population_totale AS taux_renouvellement
FROM Naissances n, Deces d, PopulationTotale p;

-- 2. Obtenir le nom des 10 villes les plus peuplées en 2009, ainsi que le nom du département associé
SELECT c.nomCommune, d.nomDepart, p.population
FROM Commune c
	JOIN Departement d ON c.code_departement = d.codeDepart
	JOIN Population p ON p.nomCommune = c.codeCommune
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
)
AND p.annee = 2009
ORDER BY p.population DESC
LIMIT 10;

-- 3. Obtenir la liste des villes qui ont un nom existants plusieurs fois, et trier afin d’obtenir en premier celles dont le nom est le plus souvent utilisé par plusieurs communes
SELECT c.nomCommune, COUNT(*) AS occurrences
FROM Commune c
GROUP BY c.nomCommune -- va afficher le nombre de count pour le nom de chaque commune
HAVING COUNT(*) > 1 -- affiche seulement les communes qui ont un nom existant plusieurs fois 
ORDER BY occurrences DESC
LIMIT 10;

-- 4. Obtenir la liste des villes dont la superficie
-- est 7*supérieur à la superficie moyenne et la population 7*inférieur à la population moyenne
SELECT (c.nomCommune), c.superficie, p.population
FROM Commune c 
	JOIN Population p ON c.codeCommune = p.nomCommune
WHERE c.superficie > 7*(SELECT AVG(superficie) 
					FROM Commune)
AND p.population < (1/7)*(SELECT AVG(population) 
				  FROM Population)
AND p.annee = 2020;

-- 5. Obtenir la liste des départements qui possèdent plus de 2 millions d’habitants en 2020
SELECT d.nomDepart, SUM(p.population) AS population_totale
FROM Population p 
	JOIN Commune c ON p.nomCommune = c.codeCommune
	JOIN Departement d ON c.code_departement = d.codeDepart
WHERE NOT (
    (c.codeCommune BETWEEN '75101' AND '75120') -- Arrondissements de Paris
    OR (c.codeCommune BETWEEN '13201' AND '13216') -- Arrondissements de Marseille
    OR (c.codeCommune BETWEEN '69381' AND '69389') -- Arrondissements de Lyon
)
AND p.annee = '2020'
GROUP BY d.nomDepart
HAVING population_totale > 2000000;



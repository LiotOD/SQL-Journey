/*Les données sont dans le dossier data du repo SQL-Journey. Je travaillerai avec les localités et les limites de commune du Bénin.
Vous pouvez ajouter ces données à une bdd en utilisant qgis, arcgis pro, fme par exemple. Il y a aussi un backup de la base que vous pouvez utiliser directement
Créez une base postgre que vous appelez postgis, ensuite vous faites un restore avec le fichier postgis.backup */

/*--1-Trouver le scr des données*/
select st_srid(geom) as srid 
from localite 
group by srid; -- on peut utilisé limit 1 au lieu du group by, les données sont en epsg 32631

/*--2-calculer la superficie des communes en Km², garder 2 chiffres après la virgule, puis les ordonner par ordre décroissant */
-- dans l'ordre on calcule la superficie quon divise pour l'avoir en km², ensuite on la convertit en un réel ou numeric pour utiliser le round et garder les 2 chiffres après la virgule 
select nom_com, round(cast((st_area(geom)/10000) as decimal),2) as sup_km2 
from commune
order by sup_km2 desc

  
/*--3-Quelles sont les 5 communes avec le plus de densité de population au Km²*/
select nom_com, pop2013,
round(cast((st_area(geom)/10000) as decimal),2) as sup_km2,
cast(pop2013 as numeric)/ round(cast((st_area(geom)/10000) as decimal),2) as dens_km2
from commune
order by dens_km2 desc
limit 5

/* En regardant les données on se rend compte que la colonne pop2013 est en varchar, donc on convertit avant de réaliser l'opération de division
ensuite limit 5 pour garder les 5 first "Cotonou","Porto-novo","Adjarra","Avrankou", "Akpro-Missérété"*/

/*--4-Réaliser une somme cumulative de l'effectif de la population en ordonnant par ordre alphabétique suivant le département, puis la commune*/
 --Pour calculer une somme cumulative, il faut garder en tête les deux fonctions SUM et OVER. Syntaxe : SUM(colonne) OVER (ORDER BY colonne1, col2)

select code_dep, nom_com, pop2013, 
sum(cast(pop2013 as integer)) over(order by code_dep, nom_com) as popcumul
from commune

/*--5- Selectionner les localités du departement 01 */
/* On récupère cette info via une sélection par localisation, le plus simple est de décomposer la requête en deux parties et d'utiliser une cte*/

  With cte_dep01 as ( --creation de la cte
  select st_union(geom) as geom from commune where code_dep = '01' -- je fais une fusion des communes pour avoir une géométrie unique
  )
select localite.nom_loc, localite.commune, localite.geom -- je récupère les attributs qui m'intéressent de la couche localite
from localite
where st_intersects(localite.geom, (select geom from cte_dep01 /* je récupère la geom de la cte */)) -- filtrage selon l'intersection entre les deux couches

















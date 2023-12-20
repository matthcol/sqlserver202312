-- Full text search
-- https://learn.microsoft.com/en-us/sql/relational-databases/search/query-with-full-text-search?view=sql-server-ver16
-- https://learn.microsoft.com/en-us/sql/t-sql/statements/create-fulltext-catalog-transact-sql?view=sql-server-ver16
-- https://learn.microsoft.com/fr-fr/sql/t-sql/statements/create-fulltext-index-transact-sql?view=sql-server-ver16

select count(*) from movie where synopsis is NULL; -- 123

-- création d'un catalogue
CREATE FULLTEXT CATALOG ftCatalog AS DEFAULT;  

-- ajout un index fulltext
-- nb: populate: on/off => remplir apres
create fulltext index on movie(
	synopsis LANGUAGE 1033  -- code langue anglaise
) key index pk_movie;  --warning: no tracking car champs text

select id, title, year, synopsis from movie 
where freetext(synopsis, 'war') 
and id not in (
	select 
		id
		-- , title, year, synopsis 
	from movie where contains(synopsis, 'war') 
)
order by title;



select title, year, synopsis from movie where contains(synopsis, '"peace" and "love"');
select title, year, synopsis from movie where contains(synopsis, 'NEAR((peace,love),2)');
select title, year, synopsis from movie where contains(synopsis, 'NEAR((peace,justice),1)');

select *
from movie m
 join CONTAINSTABLE (movie,  
      synopsis,   
      'peace NEAR love'  
   ) AS KEY_TBL  
   ON m.id = KEY_TBL.[KEY]  
-- WHERE KEY_TBL.RANK > 2  
ORDER BY KEY_TBL.RANK DESC; 

-- TODO: enable fuzzy search
select *
from movie m
 join CONTAINSTABLE (movie,  
      synopsis,   
      'piece'  
   ) AS KEY_TBL  
   ON m.id = KEY_TBL.[KEY]  
-- WHERE KEY_TBL.RANK > 2  
ORDER BY KEY_TBL.RANK DESC;


select title, year, synopsis from movie where contains(synopsis, '"war" and "star"'); -- 3
select title, year, synopsis from movie where freetext(synopsis, '"war" and "star"'); -- 148


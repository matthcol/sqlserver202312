select
	year,
	PERCENTILE_CONT(0.5) within group (order by duration) over (partition by year) as duration_median
from movie
order by year;

select
	title,
	year,
	duration,
	PERCENTILE_CONT(0.5)  within group (order by duration) over() as duration_median
from movie
order by year, title;

select 
	count(title) as nb_titles,
	count(distinct title) as nb_dist_titles,
	count(year) as nb_years,
	count(distinct year) as nb_dist_years
from movie;


ALTER TABLE movie DROP CONSTRAINT uniq_movie;
DROP INDEX idx_title ON movie;

create index idx_title on movie(title); -- non unique, non clustered
select * from movie where title = 'The Terminator'; -- idx used
-- index not used: is null, is not null
select * from movie where title = 'the terminator'; -- idx used car comparaison CI
select * from movie where title like 'The Terminator'; -- idx used
select * from movie where title like 'The T%'; -- idx not used (too much results)
select * from movie where title like 'The Te%'; -- idx used
select * from movie where title like '%tor'; -- idx used ????

select count(distinct year) from movie; -- 106
create index idx_year on movie(year desc);
select * from movie where year = 1984; -- 0.027
-- la pertinence de l'index baisse en fonction du nb de lignes en face 
-- - 1925: 8, 13%
-- - 1915: 1, 50%
-- - 1984: 16 (non choisi)
select * from movie where year = 1915; 
select * from movie where year >= 1984;
select * from movie where year between 1980 and 1989;
select * from movie where year between 1915 and 1917;

select
	year,
	count(*) as nb_movie
from movie
-- where year = 1984
group by year
order by nb_movie;


select * from movie where id in (172495,93773,338751,88247); -- idx pk used (always when no other index used)

-- tri sur director_id avant de chercher chaque réalisateur 1 fois (buffer taille 1) via pk_person
select * 
from 
	movie m 
	join person d on m.director_id = d.id;
select * 
from 
	movie m, 
	person d
where  m.director_id = d.id;

select count (distinct director_id) from movie; -- 543

select top 100 *
from have_genre
order by movie_id;

select 
*
from
	movie m
	join have_genre g on m.id = g.movie_id  -- sans index: les hav_genre sont triés avant jointure
;

select 
	m.id, m.title, m.year,
	string_agg(g.genre, ', ') as genres
from
	movie m
	join have_genre g on m.id = g.movie_id  -- sans index: les hav_genre sont triés avant jointure
where 
	m.year between 1990 and 1999
group by m.id, m.title, m.year;

-- rewrite preceding query (done already by plan optimizer of sql server)
select 
	m.id, m.title, m.year,
	g.genres
from
	movie m
	join (
		select
			movie_id,
			string_agg(genre, ', ') as genres
		from
			have_genre
		group by movie_id
	) g on m.id = g.movie_id  -- sans index: les hav_genre sont triés avant jointure
where 
	m.year between 1990 and 1999
;

with g as (
		select
			movie_id,
			string_agg(genre, ', ') as genres
		from
			have_genre
		group by movie_id
	)
select 
	m.id, m.title, m.year,
	g.genres
from
	movie m
	join g on m.id = g.movie_id  -- sans index: les hav_genre sont triés avant jointure
where 
	m.year between 1990 and 1999
;


select count(distinct genre) from have_genre; -- 23 sur ~3000

with m90 as (
	select 
		* 
	from movie m
	where m.year between 1990 and 1999
)
select 
	hg.movie_id,
	string_agg(hg.genre, ', ') as genres
from 
	m90
	inner join have_genre hg on hg.movie_id = m90.id
group by hg.movie_id, m90.title, m90.year;




create clustered index idx_genre_movie on have_genre(movie_id); -- Heap Table => clustered index table
-- replay preceding queries => plus de tri avant jointure


-- recreate index with composite PK: unicté genre par film
drop index idx_genre_movie on have_genre;
alter table have_genre add constraint pk_have_genre primary key(movie_id, genre);


select
	id,
	name,
	birthdate,
	year(birthdate) as birthyear
from person
where year(birthdate) = 1930;

-- computed columns
-- https://learn.microsoft.com/en-us/sql/relational-databases/indexes/indexes-on-computed-columns?view=sql-server-ver16
-- 1: deterministic, precise
alter table person add birthyear as year(birthdate) persisted;
-- 2: not deterministic, precise
-- alter table person add age as datediff(year, birthdate, getdate()) persisted; -- cannot be persisted because the column is non-deterministic
alter table person add age as datediff(year, birthdate, getdate()); -- recomputed at each query

-- index on computed column
create index idx_birthyear on person (birthyear);
-- preceding query is optimized or rewritten as follow
select
	id,
	name,
	birthdate,
	birthyear
from person
where birthyear = 1930;

select * from person where name = 'Tom Holland';
-- 'Jean Dujardin'; --'Tom Holland';
update person set birthdate = '1996-06-01' where id = 4043618; -- => recompute year

SELECT 
	column_name,
	COLUMNPROPERTY( OBJECT_ID('person'),column_name,'isPrecise') as isPrecise,
	COLUMNPROPERTY( OBJECT_ID('person'),column_name,'isDeterministic') isDeterministic
FROM (VALUES('birthyear'), ('age')) as cols(column_name);

-- multiplication des données par jointure
select 
*
from 
	movie m
	join play p on m.id = p.movie_id -- FK play.movie_id 66547 = nb rows result inner join 
	join person a on p.actor_id = a.id; -- FK play.actor_id 66547 = nb rows result inner join 

select 
*
from 
	movie m
	join play p on m.id = p.movie_id -- FK play.movie_id 66547 = nb rows result inner join 
	join person a on p.actor_id = a.id -- FK play.actor_id 66547 = nb rows result inner join 
	join have_genre g on g.movie_id = m.id; -- FK: g.movie_id => ~ *3

select 
*
from 
	movie m -- with (index (idx_director))
	join play p on m.id = p.movie_id -- FK play.movie_id 66547 = nb rows result inner join 
	join person a on p.actor_id = a.id -- FK play.actor_id 66547 = nb rows result inner join 
	join have_genre g on g.movie_id = m.id -- FK: g.movie_id => ~ *3
	join person d on m.director_id = d.id
-- option (table hint(m, index (idx_director)));
-- plan choisi: 4,57 (défaut) vs 4,81 en passant par idx_director
-- ordre jointures: 
--	person d 
--  JOIN movie (trié par director_id)
--  tri (par movie.id)
-- JOIN have_genre 
-- JOIN  play 
-- JOIN person a

-- nb de real: cost = 0,47
select count(*) from person d where exists(select * from movie m where m.director_id = d.id);
select count(*) from person d where d.id in (select director_id from movie m); -- optimizer ajoute group by
select count(*) from person d where d.id in (select distinct director_id from movie m);
select count(*) from person d join (select distinct director_id from movie) m on m.director_id = d.id;
create index idx_director on movie(director_id);
drop index idx_director on movie; 

-- 1 person join with 1187 movie => idx_director used
select 
	m.title, m.year,
	d.name
from
	movie m
	join person d on m.director_id = d.id
where d.name = 'Steven Spielberg'; -- fait sur person avant jointure par optimizer

select 
	m.year,
	m.title,
	m.duration,
	g.genre,
	d.name as director,
	a.name as actor,
	p.role
from
	person d 
	join movie m on m.director_id = d.id
	join have_genre g on g.movie_id = m.id 
	join play p on m.id = p.movie_id 
	join person a on p.actor_id = a.id 
where
	p.role = 'James Bond'
	and a.name in ('Sean Connery', 'Daniel Craig')
	and d.name in ('Sam Mendes', 'Terence Young')
	and g.genre = 'action'
	and m.duration <= 145
order by m.year;

-- https://learn.microsoft.com/en-us/sql/relational-databases/indexes/reorganize-and-rebuild-indexes?view=sql-server-ver16
-- https://www.mssqltips.com/sqlservertip/6274/types-of-sql-server-indexes/
SELECT t.name AS TableName,i.name AS IndexName,
       ROUND(avg_fragmentation_in_percent,2) AS avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') ips
INNER JOIN sys.tables t on t.[object_id] = ips.[object_id]
INNER JOIN sys.indexes i ON (ips.object_id = i.object_id) AND (ips.index_id = i.index_id)
ORDER BY avg_fragmentation_in_percent DESC;

-- ok online sans verrou
alter index pk_movie on movie reorganize;

-- plus rapide si mode offline
-- si online, pose un verrou
alter index pk_person on person rebuild; 


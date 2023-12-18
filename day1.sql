select @@version;

select 9223372036854775807;
select cast(9223372036854775807 * 4 as bigint);
select cast(0.1 as float) * 0.3;

-- DDL: data definition language
alter table movie add 
	original_title nvarchar(300) NULL
;

-- films réalisés par John Woo
select *
from 
	movie m
	join person d on m.director_id = d.id
where d.name = 'John Woo'
order by m.year;

update movie set original_title = N'喋血雙雄' where id = 97202;

-- les films de moins de 10 ans
select *
from movie m
where m.year >= datepart(year, current_timestamp) - 10
order by m.year;

select *
from movie m
where m.year >= year(getdate()) - 10
order by m.year;

-- since SQL Server 2022: datetrunc
-- NB: (opt) set dateformat ymd; -- ou dmy, mdy 
select 
	datetrunc(day, getdate()) as today,
	datetrunc(month, getdate()) as first_day_of_month,
	cast(datetrunc(month, getdate()) as date) as first_day_of_month2 ,
	convert(date, datetrunc(month, getdate())) as first_day_of_month3,
	dateadd(month, 1, getdate()) as in_a_month,
	datediff(day, cast(getdate() as date), '2023-12-25') as delta_day
;

select 
	12 / 5 as res1,
	12 / 5.0 as res2
;

select 
	title + ' (' + cast(year as varchar) + ')'
from movie
where year = 1984;

select 
	concat(
		title
		,' ('
		,year,
		')'
	) as info
from movie
where year = 1984;

select * from movie where director_id is null;
select * from movie where synopsis is null;

select 
	title,
	duration,
	case 
		when duration < 60 then 'short'
		when duration < 90 then 'medium'
		else 'long'
	end as duration_cat
from movie
where year = 1992;

-- nb de films par année, ordre décroissant de nb
select
	year,
	count(*) as nb_movie
from movie
group by year
order by nb_movie desc;

-- nb de films par réalisateurs, seuil à 10 réal, nb décroissant
-- coeur de requete
select
	director_id,
	count(*) as nb_movie
from movie
group by director_id
;

select
	d.id,
	d.name,
	count(*) as nb_movie
from 
	movie m
	join person d on m.director_id = d.id
group by d.id, d.name
having count(*) >= 10
order by nb_movie desc
;

select 
	d.id,
	d.name,
	nm_by_d.nb_movie
from
	(select
		director_id,
		count(*) as nb_movie
	from movie
	group by director_id
	having count(*) >= 10
	) nm_by_d
	join person d on nm_by_d.director_id = d.id
order by nm_by_d.nb_movie desc
;

-- CTE: Common Table Expression
with nb_movie_by_director as (select
		director_id,
		count(*) as nb_movie
	from movie
	group by director_id
	having count(*) >= 10
	) 
select 
	d.id,
	d.name,
	nm_by_d.nb_movie
from
	nb_movie_by_director nm_by_d
	join person d on nm_by_d.director_id = d.id
order by nm_by_d.nb_movie desc
;




-- nb de films par acteurs, seuil à 10 'roles', nb décroissant
select 
	a.id, a.name,
	count(*) as nb_movie
from 
	-- movie m 
	-- join play p on m.id = p.movie_id
	play p
	join person a on p.actor_id = a.id
group by a.id, a.name
having count(*) >= 10
order by nb_movie desc;

select outerPlay.name, count(*) as nbMovies
from movie
outer apply(
	select  person.name, play.movie_id
	from play
	inner join person
	on play.actor_id = person.id) as outerPlay
where outerPlay.movie_id = movie.id
group by outerPlay.name
having count(*) >= 10
order by nbMovies;

with nb_movie_by_actor as (
	select 
		actor_id,
		count(*) as nb_movie
	from play
	group by actor_id
	having count(*) >= 10
)
select
	a.id, a.name,
	nm_b_a.nb_movie
from 
	nb_movie_by_actor nm_b_a
	join person a on nm_b_a.actor_id = a.id
order by nm_b_a.nb_movie desc;


with  famous_person as (
	select  *
	from person
	where name in (
		'Christopher Nolan',
		'Alfred Hitchcock',
		'Fred Astaire',
		'Quentin Tarantino',
		'Bourvil'
	)
)
select
	d.id, d.name,
	count(m.id) as nb_movie,
	coalesce(sum(m.duration), 0) as total_duration,
	isnull(sum(m.duration), 0) as total_duration2,
	string_agg(m.title, ', ') as titles,
	-- 2 following stats are exclusive
	-- string_agg(m.title, ', ') within group (order by m.year) as titles2,
	string_agg(m.title, ', ') within group (order by m.year desc) as titles3,
	string_agg(
		concat(
			-- cast(m.year as varchar),
			m.year,
			'-',
			m.title), 
		' / '
	) within group (order by m.year desc) as titles3
from
	famous_person d
	left join movie m on m.director_id = d.id
group by d.id, d.name; -- recette: group by left column, stats on right columns

-- Window clause
with  famous_person as (
	select  *
	from person
	where name in (
		'Christopher Nolan',
		'Alfred Hitchcock',
		'Fred Astaire',
		'Quentin Tarantino',
		'Bourvil',
		'Clint Eastwood'
	)
)
select 
	d.id, d.name,
	m.title,
	m.year,
	m.duration,
	m.synopsis,
	count(m.id) over (partition by d.id) as nb_movie,
	coalesce(sum(m.duration) over (partition by d.id), 0) as total_duration,
	min(m.year) over (partition by d.id) as first_year,
	max(m.year) over (partition by d.id) as first_year
from
	famous_person d
	left join movie m on m.director_id = d.id
order by d.id, d.name, m.year desc;
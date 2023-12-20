CREATE PARTITION FUNCTION myRangeDecade (smallint)  
    AS RANGE RIGHT FOR VALUES (
		1920,1930,1940,1950,1960,1970,1980,1990,2000,2010,2020,2030
	) ;  

CREATE PARTITION SCHEME myRangeDecadeScheme  
    AS PARTITION myRangeDecade  
    ALL TO ('PRIMARY') ;  


CREATE TABLE movie2 (
	id int identity not null,
	title varchar(300) not null,
	year smallint not null,
	duration smallint null,
	constraint pk_movie2 PRIMARY KEY (year, id)
) ON myRangeDecadeScheme(year);

SET IDENTITY_INSERT movie2 ON;
insert into movie2 (id, title, year,duration)
select id, title, year,duration from movie;

select * from movie2 where year between 1990 and 1999;
select * from movie where year between 1990 and 1999;

create index idx_title2 on movie2(title);

select * from movie2 where title = 'The Terminator';
select * from movie2 with (index(idx_title2)) where title = 'The Terminator';
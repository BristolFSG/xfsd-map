drop function if exists str_delim;

delimiter $$
create function str_delim
(
	str VARCHAR(255)
)
returns VARCHAR(255)
begin
	declare newstr VARCHAR(255);
	declare oldstr VARCHAR(255);

	set newstr = trim(str);
	
	repeat
		set oldstr = newstr;
		set newstr = replace(oldstr, '  ', ' ');
		until newstr = oldstr
	end repeat;

	return newstr;
end$$
delimiter ;

drop function if exists str_element;

delimiter $$
create function str_element
(
	str VARCHAR(255),
	pos INT
	)
	returns varchar(255)
begin
	declare newstr VARCHAR(255);
	set newstr = str_delim(str);
	
-- return newstr;
 return
 replace(
	substring(
		substring_index(newstr, ' ', pos),
		length(substring_index(newstr, ' ', pos - 1)) + 1
		),
		' ',
		''
		);
 			 
end$$

delimiter ;

insert into xplane_navtypes(id, type) values (99, 'TEMP');

delete from xplane_navaids;

load data infile '/dev/airports.txt'
ignore
into table xplane_navaids
fields terminated by ','
lines terminated by '\r\n'
(@ntype, @icao, @name, @lat, @lon)
set
navtypeid = if (@ntype = 'A', 1, 99), 
lat       = if (@ntype = 'A', @lat, 0.0),
lon       = if (@ntype = 'A', @lon, 0.0),
icao      = if (@ntype = 'A', @icao, ''),
name      = if (@ntype = 'A', @name, '')
;

load data infile '/dev/earth_nav.dat'
ignore
into table xplane_navaids
lines terminated by '\r\n'
ignore 3 lines
(@line)
set
navtypeid = if (locate(' ', @line) = 0, @line, substr(@line, 1, locate(' ',@line))), 
lat       = if (locate(' ', @line) = 0, NULL,  substr(@line, locate(' ',@line) + 1, 12)),
lon       = if (locate(' ', @line) = 0, NULL,  substr(@line, locate(' ',@line) + 14, 13)),
name      = if (locate(' ', @line) = 0, NULL,  str_delim(substr(@line, 29 + if (navtypeid > 9, 1, 0)))),
icao      = if (locate(' ', @line) = 0, '',    str_element(name, 5)),
name      = if (locate(' ', @line) = 0, NULL,  replace(name, substring_index(name, ' ', 5),''))
;

load data infile '/dev/earth_fix.dat'
ignore
into table xplane_navaids
lines terminated by '\r\n'
ignore 3 lines
(@line)
set
navtypeid = if (locate(' ', @line) = 0, 99, 100),
lat       = if (locate(' ', @line) = 0, NULL, substr(@line,  1, 12)),
lon       = if (locate(' ', @line) = 0, NULL, substr(@line, 14, 13)),
icao      = if (locate(' ', @line) = 0, '',   substr(@line, 28,  5)),
name      = if (locate(' ', @line) = 0, NULL, substr(@line, 28,  5))
;

delete from xplane_navaids where navtypeid = 99;
delete from xplane_navtypes where id = 99;

drop function str_delim;
drop function str_element;

optimize table xplane_navaids;

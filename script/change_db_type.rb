#!/usr/bin/env ruby

# Changes the table type of a database table

database = "achilles_development"
if ARGV.length <2
	puts "usage: change_db_type [dbtype (myisam|innodb)] table1 table2..."
else
	table_type=ARGV[0]
	ARGV[1..-1].each do |table|
		statement = "alter table #{table} engine=#{table_type};"
		`sudo mysql -e "use achilles_development; #{statement}"`
	end
end

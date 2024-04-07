
1.Two AWS Postgresql RDS Instance in two different regions (us-east-1 and us-east-2)

2.VPC Peering between two regions in the AWS RDS (us-east-1 and us-east-2)

3.Custom parameter group for Postgresql RDS with below options are enabled 

	rds.enable_pgactive = 1
	rds.custom_dns_resolution = 1
	
4.Create user with full privileges , we can use RDS master user for this 

5.Create sample database ( applicationdb ) in both sides 

	Create database applicationdb;
	
6.Install pgactive extension on appdbserver01 in us-east-1

	CREATE EXTENSION IF NOT EXISTS pgactive;

7.Setup Connection information on appdbserver01 in us-east-1

	CREATE SERVER pgactive_server_pgactivesource
		FOREIGN DATA WRAPPER pgactive_fdw
		OPTIONS (host 'project-pgactive-source.cta8ayagibis.us-east-1.rds.amazonaws.com', dbname 'applicationdb');
	CREATE USER MAPPING FOR postgres
		SERVER pgactive_server_pgactivesource
		OPTIONS (user 'postgres', password 'Adminqwerty');

	-- connection info for appdbserver02
	CREATE SERVER pgactive_server_pgactivetarget
		FOREIGN DATA WRAPPER pgactive_fdw
		OPTIONS (host 'project-pgactive-target.c9s62kao2kpy.us-east-2.rds.amazonaws.com', dbname 'applicationdb');
	CREATE USER MAPPING FOR postgres
		SERVER pgactive_server_pgactivetarget
		OPTIONS (user 'postgres', password 'Adminqwerty');
		
8.Initialize replication group on appdbserver01 in us-east-1

	SELECT pgactive.pgactive_create_group(
		node_name := 'appdbserver01-app',
		node_dsn := 'user_mapping=postgres pgactive_foreign_server=pgactive_server_pgactivesource');
	
9.Verify Replication Group on appdbserver01 in us-east-1

SELECT pgactive.pgactive_wait_for_node_ready();

10.Install pgactive extension on appdbserver01 in us-east-1

	CREATE EXTENSION IF NOT EXISTS pgactive;

11.Setup Connection information on appdbserver02 in us-east-2

	
	CREATE SERVER pgactive_server_pgactivesource
		FOREIGN DATA WRAPPER pgactive_fdw
		OPTIONS (host 'project-pgactive-source.cta8ayagibis.us-east-1.rds.amazonaws.com', dbname 'applicationdb');
	CREATE USER MAPPING FOR postgres
		SERVER pgactive_server_pgactivesource
		OPTIONS (user 'postgres', password 'Adminqwerty');

	-- connection info for appdbserver02
	CREATE SERVER pgactive_server_pgactivetarget
		FOREIGN DATA WRAPPER pgactive_fdw
		OPTIONS (host 'project-pgactive-target.c9s62kao2kpy.us-east-2.rds.amazonaws.com', dbname 'applicationdb');
	CREATE USER MAPPING FOR postgres
		SERVER pgactive_server_pgactivetarget
		OPTIONS (user 'postgres', password 'Adminqwerty');

12.Join the appdbserver02 with active-active replication group

	SELECT pgactive.pgactive_join_group(
		node_name := 'appdbserver02-app',
		node_dsn := 'user_mapping=postgres pgactive_foreign_server=pgactive_server_pgactivetarget',
		join_using_dsn := 'user_mapping=postgres pgactive_foreign_server=pgactive_server_pgactivesource'
	);
	
	SELECT pgactive.pgactive_wait_for_node_ready();
	

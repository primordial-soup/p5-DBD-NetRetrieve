#!/usr/bin/perl

use Test::More;
use DBD::NetRetrieve::DBD_prefix_filter_hack;
BEGIN { use_ok( 'DBI' ); }
require_ok( 'DBI' );

my $dbh;

use WWW::Mechanize;
ok( $dbh = DBI->connect('dbi:NetRetrieve:', '', '',
		{ netret_useragent => WWW::Mechanize->new() }),
	'database connect' );
warn($DBI::errstr) unless defined $dbh;

#use DDP; p $dbh->tables;
for my $sql(split /\n/,
	#" SELECT * FROM google             "                         # fails (no query)
	#" SELECT * FROM google WHERE query=a"                         # NUM_OF_FIELDS = 4
	#" SELECT count(*) FROM google WHERE query=a"                 # NUM_OF_FIELDS = 4 (should be made more efficient since the results of the fields are not used by 'count')
	#" SELECT url,title FROM google     "                         # fails (no query)
	#" SELECT url,title FROM google WHERE mimetype='application/pdf'   "  # fails (no query) (also, 'mimetype' is not a currently defined field - not checked yet)
	#" SELECT url,title FROM google WHERE query='dendritic spines'    "   # NUM_OF_FIELDS = 2
	#" SELECT url,title FROM google WHERE query='dendritic spines' and mimetype='application/pdf'" # NUM_OF_FIELDS = 2 (although 'mimetype' not accepted field)
	#" SELECT * FROM google WHERE query=a LIMIT 20"                         # NUM_OF_FIELDS = 4
	" SELECT * FROM google WHERE query=a LIMIT 20,80"                         # NUM_OF_FIELDS = 4
){
	my $stmt = $dbh->prepare($sql);
	$stmt->execute;
	use DDP; p $stmt->{NUM_OF_FIELDS};
	next unless $stmt->{NUM_OF_FIELDS};
	while (my $row=$stmt->fetch) {
		print "@$row\n";
	}
}

done_testing;

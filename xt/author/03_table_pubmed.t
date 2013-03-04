#!/usr/bin/perl

use Test::More;
done_testing; exit;

BEGIN { use_ok( 'DBD::NetRetrieve::Table::pubmed' ); }
require_ok( 'DBD::NetRetrieve::Table::pubmed' );

BEGIN { use_ok( 'CHI' ); }
require_ok( 'CHI' );
BEGIN { use_ok( 'LWP::UserAgent' ); }
require_ok( 'LWP::UserAgent' );

my $sth_mock = {
  Database => {
    netret_cache => CHI->new(driver => 'Memory', global => 1),
    netret_useragent => LWP::UserAgent->new( agent => 'DBD-NetRetrieve/0.001' ),
    netret_eutil_email => 'zmughal@cpan.org',
  },
  query => 'dendritic spines'
};

ok( my $tbl = DBD::NetRetrieve::Table::pubmed->new(), 'table pubmed' );

# TODO make these tests
use DDP; p $tbl->fetch_row($sth_mock, 0);
#use DDP; p $tbl->fetch_row($sth_mock, 1);
#use DDP; p $tbl->fetch_row($sth_mock, 2);
#use DDP; p $tbl->fetch_row($sth_mock, 100);
#use DDP; p $tbl->fetch_row($sth_mock, 109);
#use DDP; p $tbl->fetch_row($sth_mock, 201);

done_testing;

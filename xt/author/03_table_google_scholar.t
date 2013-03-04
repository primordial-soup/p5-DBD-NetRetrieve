#!/usr/bin/perl

use Test::More;

BEGIN { use_ok( 'DBD::NetRetrieve::Table::google_scholar' ); }
require_ok( 'DBD::NetRetrieve::Table::google_scholar' );

BEGIN { use_ok( 'CHI' ); }
require_ok( 'CHI' );
BEGIN { use_ok( 'LWP::UserAgent' ); }
require_ok( 'LWP::UserAgent' );

my $sth_mock = {
  Database => {
    netret_cache => CHI->new(driver => 'Memory', global => 1),
    netret_useragent => LWP::UserAgent->new( agent => 'DBD-NetRetrieve/0.001' )
  },
  query => 'test'
};

ok( my $tbl = DBD::NetRetrieve::Table::google_scholar->new(), 'table google scholar' );

# TODO make these tests
use DDP; p $tbl->fetch_row($sth_mock, 0);
use DDP; p $tbl->fetch_row($sth_mock, 1);
use DDP; p $tbl->fetch_row($sth_mock, 2);
use DDP; p $tbl->fetch_row($sth_mock, 100);
use DDP; p $tbl->fetch_row($sth_mock, 109);
use DDP; p $tbl->fetch_row($sth_mock, 200);

done_testing;

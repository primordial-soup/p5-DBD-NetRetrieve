#!/usr/bin/perl

use Test::More;
use Test::Deep;

BEGIN { use_ok( 'DBD::NetRetrieve::Page' ); }
require_ok( 'DBD::NetRetrieve::Page' );

ok(my $pc = DBD::NetRetrieve::Page->new( entries_per_page => 100 ), 'page calculator');
is( $pc->first_entry_on_page(0), 0, 'page 0');
is( $pc->last_entry_on_page(0), $pc->entries_per_page - 1, 'page 0');
is( $pc->last_entry_on_page(0) + 1, $pc->first_entry_on_page(1), 'page 1');

is( $pc->nth_entry_on_page(0,0), $pc->first_entry_on_page(0), 'page 0');
is( $pc->nth_entry_on_page(1,0), $pc->first_entry_on_page(1), 'page 1');
is( $pc->nth_entry_on_page(1,5) - $pc->nth_entry_on_page(0,5), $pc->entries_per_page, 'difference');

cmp_deeply( [$pc->nth_entry_page_entry(0)], [0,0] , 'entry test');
cmp_deeply( [$pc->nth_entry_page_entry(1)], [0,1] , 'entry test');
cmp_deeply( [$pc->nth_entry_page_entry(99)], [0,99] , 'entry test');
cmp_deeply( [$pc->nth_entry_page_entry(100)], [1,0] , 'entry test');
cmp_deeply( [$pc->nth_entry_page_entry(101)], [1,1] , 'entry test');
cmp_deeply( [$pc->nth_entry_page_entry(200)], [2,0] , 'entry test');

cmp_deeply( [$pc->page_entries_for_range(50,150)], [0,50,1,50] , 'range test');

done_testing;

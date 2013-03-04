package DBD::NetRetrieve::PageIdxFetchRole;

use strict;
use warnings;
use Moo::Role;
use Scalar::Util qw/blessed/;

has _result_class => ( is => 'ro' );

has _page_calc => ( is => 'ro' );

sub fetch_row {
	my ($self, $sth, $row) = @_;
	my $cache = $sth->{Database}{netret_cache};
	my ($page, $idx) = $self->_page_calc->nth_entry_page_entry($row);
	my $query = $sth->{query};
	# TODO CHI expiration below
	my $row_result = $cache->compute(blessed($self)."$query:$page", '1 hr', sub {
		$self->get_page_results($sth, $query,$page);
	})->[$idx];
}

sub get_page_results {
	my ($self, $sth, $query, $page) = @_;
	my $response = $self->get_page($sth, $query, $page);
	die "Could not retrieve page" unless $response->is_success;
	[ map { $self->build_result($_)  }
		@{$self->_result_class->build_resultset($response)} ];
}

sub get_page {
  my ($self, $sth, $query, $page) = @_;
  my $ua = $sth->{Database}{netret_useragent};
  $ua->get($self->get_page_uri($query, $page));
}

sub get_page_uri {
  my ($self, $query, $page) = @_;
  die "need implementation";
}

sub build_result {
  my ($self, $result) = @_;
  die "need implementation";
}

1;

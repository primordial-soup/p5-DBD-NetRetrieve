package DBD::NetRetrieve::PageGoogleRole;

use strict;
use warnings;
use Moo::Role;
with qw(DBD::NetRetrieve::PageIdxFetchRole);

use constant NUM_ENTRIES => 100; # This is the maximum possible.
has _QUERY_URI => (is => 'ro');

has _page_calc => ( is => 'ro',
	default => sub { DBD::NetRetrieve::Page->new( entries_per_page => NUM_ENTRIES ) } );

sub get_page_uri {
  my ($self, $query, $page) = @_;
  my $start = $self->_page_calc->first_entry_on_page($page);
  my $uri = $self->_QUERY_URI->clone;
  $uri->query_form( q => $query, num => NUM_ENTRIES, start => $start );
  $uri;
}

1;

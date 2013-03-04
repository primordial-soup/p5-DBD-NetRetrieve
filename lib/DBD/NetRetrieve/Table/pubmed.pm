package DBD::NetRetrieve::Table::pubmed;

use strict;
use warnings;
use Moo;
use Set::Scalar;
use DBD::NetRetrieve::Page;
use XML::XPath;
use URI;
with qw(DBD::NetRetrieve::PageIdxFetchRole);

# TODO the E-utilities API can retrieve more, but this is the maximum on the
# web interface. This may need to be dynamic.
use constant NUM_ENTRIES => 10;
#use constant NUM_ENTRIES => 200;

use constant EUTIL_SEARCH_URI => URI->new('http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi');
use constant EUTIL_SUMMARY_URI => URI->new('http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi');
use constant EUTIL_FETCH_URI => URI->new('http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi');

has col_names => ( is => 'ro', default => sub { Set::Scalar->new(qw/query uri title text/) } );
has required_where_cols => ( is => 'ro', default => sub { Set::Scalar->new(qw/query/) } );
has _result_class => ( is => 'ro',
	default => sub { 'DBD::NetRetrieve::Table::pubmed::result' } );
has email => ( is => 'rw' );
has _page_calc => ( is => 'ro',
	default => sub { DBD::NetRetrieve::Page->new( entries_per_page => NUM_ENTRIES ) } );

sub get_page_results {
	my ($self, $sth, $query, $page) = @_;
	my $response = $self->get_page($sth, $query, $page);
	die "Could not retrieve page" unless $response->is_success;
	[ map { $self->build_result($_)  }
		@{$self->_result_class->build_resultset($sth, $response)} ];
}

sub build_result {
	my ($self, $result) = @_;
	return {
		title       => $result->field_title,
		uri         => $result->field_uri,
		text        => $result->field_text,
		author      => $result->field_author,
		cited_count => $result->field_cited_count,
		mime_type   => $result->field_mime_type,
	};
}

sub get_email {
	my ($self, $sth) = @_;
	return $self->email if($self->email);
	for (qw/netret_email netret_eutil_email/) {
		if($sth->{Database}{$_}) {
			$self->email($sth->{Database}{$_});
			return $sth->{Database}{$_};
		}
	}
	die "Need e-mail for E-utilities. Pass in 'netret_eutil_email' or 'netret_email' options to DBI";
	undef;
}

sub get_page {
	my ($self, $sth, $query, $page) = @_;
}

# http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmode=xml&term=dendritic+spines&retmax=200&retstart=0&tool=BioPerl&email=zmughal%40cpan.org
sub get_page_uri {
	my ($self, $sth, $query, $page) = @_;
	my $start = $self->_page_calc->first_entry_on_page($page);
	my $pmid_search_uri = EUTIL_SEARCH_URI->clone;
	$pmid_search_uri->query_form(
		db => 'pubmed',
		retmode => 'xml',
		term => $query,
		retmax => NUM_ENTRIES,
		retstart  => $start);
	$self->add_eutils_default_params($sth, $pmid_search_uri);
	$pmid_search_uri;
}

# http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id=23284619%2C23277570%2C23276632%2C23274838%2C23273725%2C23271035%2C23270857%2C23269840%2C23267328%2C23265310&tool=BioPerl&email=zmughal%40cpan.org&retmode=text&rettype=abstract
sub get_summary_uri {
	my ($self, $sth, $pmid) = @_;
	my @pmids = ref $pmid eq 'ARRAY' ? @$pmid : ( $pmid );
	my $summary_uri = EUTIL_SUMMARY_URI->clone;
	$summary_uri->query_form(
		db => 'pubmed',
		id => (join ",", @pmids),
		retmode => 'xml');
	$self->add_eutils_default_params($sth, $summary_uri);
	$summary_uri;
}

# http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=17284678,9997&retmode=text&rettype=abstract
# http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=23284619%2C23277570%2C23276632%2C23274838%2C23273725%2C23271035%2C23270857%2C23269840%2C23267328%2C23265310&retmode=text&rettype=abstract
sub get_abstract_uri {
	my ($self, $sth, $pmid) = @_;
	my @pmids = ref $pmid eq 'ARRAY' ? @$pmid : ( $pmid );
	my $abstract_fetch_uri = EUTIL_FETCH_URI->clone;
	$abstract_fetch_uri->query_form(
		db => 'pubmed',
		id => (join ",", @pmids),
		retmode => 'text',
		rettype => 'abstract');
	$self->add_eutils_default_params($sth, $abstract_fetch_uri);
	$abstract_fetch_uri;
}

sub join_abstract_pmid {
	my ($pmids, $abstract_text) = @_;
	my %abstracts;
	@abstracts{@$pmids} = split /\n{3}/s, $abstract_text;
	\%abstracts;
}


sub add_eutils_default_params {
	my ($self, $sth, $uri) = @_;
	$uri->query_form( $uri->query_form,
		email => $self->get_email($sth),
		tool => __PACKAGE__ );
}

package DBD::NetRetrieve::Table::pubmed::result;
use Moo;

# perl -MDDP -MLWP::UserAgent -e '&p([split /\n{3}/s, LWP::UserAgent->new->get("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=23284619%2C23277570%2C23276632%2C23274838%2C23273725%2C23271035%2C23270857%2C23269840%2C23267328%2C23265310&retmode=text&rettype=abstract")->decoded_content])'
sub build_resultset {
	my ($class, $sth, $response) = @_;
	# TODO cache by PMID as this is fixed - test that the cache contains any lazy attributes
	[];
}

has pmid => ( is => 'rw' );
has abstract => ( is => 'rw' );
has sth => ( is => 'rw' );


1;

1;

package DBD::NetRetrieve::Table::google_scholar;

use strict;
use warnings;
use Moo;
use Set::Scalar;
use DBD::NetRetrieve::Page;
with qw(DBD::NetRetrieve::PageGoogleRole);

has _QUERY_URI => (is => 'ro',
  default => sub {  URI->new('http://scholar.google.com/scholar') } );
has _result_class => ( is => 'ro',
	default => sub { 'DBD::NetRetrieve::Table::google_scholar::result' } );

use constant COOKIE_CITE_RIS_ID => 2;
use constant COOKIE_CITE_BIBTEX_ID => 4;

has col_names => ( is => 'ro', default => sub { Set::Scalar->new(qw/query uri title text/) } );
has required_where_cols => ( is => 'ro', default => sub { Set::Scalar->new(qw/query/) } );

has header => ( is => 'lazy' );

sub _build_header {
	return [ 'Cookie' => "GSP=ID=@{[unpack('h*',pack('d',rand()))]}:CF=@{[COOKIE_CITE_BIBTEX_ID]}" ];
}

sub get_page {
  my ($self, $sth, $query, $page) = @_;
  my $ua = $sth->{Database}{netret_useragent};
  $ua->get($self->get_page_uri($query, $page), @{$self->header});
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

package DBD::NetRetrieve::Table::google_scholar::result;

use Moo;
use HTML::TreeBuilder 5 -weak;
use HTML::TreeBuilder::XPath;
use URI;
use URI::QueryParam;
with qw(DBD::NetRetrieve::ResultMIMERole);

has _tree => ( is => 'rw', required => 1 );

sub build_resultset {
  my ($class, $response) = @_;
  (my $tree = HTML::TreeBuilder::XPath->new())
    ->parse( $response->decoded_content );
  my @nodes = $tree->findnodes(q{//div[@class="gs_r"]});
  [ map { $class->new( _tree => $_ ) } @nodes ];
}

has field_title => ( is => 'lazy' );
sub _build_field_title {
  my ($self) = @_;
  join ";",
    map { $_->as_text_trimmed }
    $self->_tree->findnodes(q{//h3//a});
}

has field_uri => ( is => 'lazy' );
sub _build_field_uri {
  my ($self) = @_;
  use DDP;
  join ";",
    map { $self->_clean_link(URI->new($_->{href})) }
    $self->_tree->findnodes(q{//h3//a});
}

has field_author => ( is => 'lazy' );
sub _build_field_author {
  my ($self) = @_;
  join ";",
    map { $_->as_text_trimmed }
    $self->_tree->findnodes(q{//div[contains(@class,"gs_a")]});
}

has field_text => ( is => 'lazy' );
sub _build_field_text {
  my ($self) = @_;
  join ";",
    map { $_->as_text_trimmed }
    $self->_tree->findnodes(q{//div[contains(@class,"gs_rs")]});
}

has field_cited_count => ( is => 'lazy' );
sub _build_field_cited_count {
  my ($self) = @_;
  (my $cited_by =
	  $self->_tree->findnodes('//a[contains(text(),"Cited by")]')
	  ->[0]->as_text)
	  =~ s,Cited by ,,g;
  $cited_by || undef;
}

sub _clean_link {
	my ($self, $uri) = @_;
	if( $uri->host eq 'books.google.com' ) {
		$uri->query_param_delete('sig');
	}
	return $uri;
}

1;

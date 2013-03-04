package DBD::NetRetrieve::Table::google;

use strict;
use warnings;
use Moo;
use Set::Scalar;
use URI;
use DBD::NetRetrieve::Page;
with qw(DBD::NetRetrieve::PageGoogleRole);

has _QUERY_URI => (is => 'ro',
	default => sub {  URI->new('https://www.google.com/search') } );

has _result_class => ( is => 'ro',
	default => sub { 'DBD::NetRetrieve::Table::google::result' } );
has col_names => ( is => 'ro',
	default => sub { Set::Scalar->new(qw/query uri title text mime_type/) } );
has required_where_cols => ( is => 'ro',
	default => sub { Set::Scalar->new(qw/query/) } );

sub build_result {
	my ($self, $result) = @_;
	return {
		title     => $result->field_title,
		uri       => $result->field_uri,
		text      => $result->field_text,
		mime_type => $result->field_mime_type,
	};
}

package DBD::NetRetrieve::Table::google::result;

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
  my @nodes = $tree->findnodes(q{//li[@class="g"]});
  [ map { $class->new( _tree => $_ ) } @nodes ];
}

has field_title => ( is => 'lazy' );
sub _build_field_title {
  my ($self) = @_;
  ($self->_tree->findnodes(q{//h3/a[1]}))[0]->as_text_trimmed;
}

has field_uri => ( is => 'lazy' );
sub _build_field_uri {
  my ($self) = @_;
  URI->new(
		($self->_tree->findnodes(q{//h3/a[1]}))[0]
			->{href})
	->query_param('q');
}

has field_text => ( is => 'lazy' );
sub _build_field_text {
	my ($self) = @_;
	($self->_tree->findnodes(q{//span[contains(@class,"st")]}))[0]->as_text;
}



1;

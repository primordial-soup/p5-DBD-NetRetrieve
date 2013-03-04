package DBD::NetRetrieve::ResultMIMERole;

use strict;
use warnings;
use Moo::Role;

has field_uri => ( is => 'ro' );

has field_mime_type => ( is => 'lazy' );
sub _build_field_mime_type {
	my ($self) = @_;
	if($self->field_uri =~ /\.pdf$/) {
		return "application/pdf"
	}
	return "text/html"; # TODO
}

1;

package DBD::NetRetrieve::Page;

use strict;
use warnings;

use Moo;

has entries_per_page => ( is => 'rw', required => 1 );

sub first_entry_on_page {
	my ($self, $page_no) = @_;
	$page_no * $self->entries_per_page;
}

sub last_entry_on_page {
	my ($self, $page_no) = @_;
	$self->first_entry_on_page($page_no+1)-1;
}

sub nth_entry_on_page {
	my ($self, $page_no, $n) = @_;
	return undef if $n < 0 or $n >= $self->entries_per_page;
	$self->first_entry_on_page($page_no) + $n;
}

sub nth_entry_page_entry {
	my ($self, $n) = @_;
	(int($n / $self->entries_per_page), $n % $self->entries_per_page);
}

sub page_entries_for_range {
	my ($self, $begin, $end) = @_;
	( $self->nth_entry_page_entry($begin), $self->nth_entry_page_entry($end) );
}


1;

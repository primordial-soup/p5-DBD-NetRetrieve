package DBD::NetRetrieve::DBD_prefix_filter_hack;

use strict;
use warnings;

BEGIN {
	unshift @INC, sub {
		my ($coderef, $filename) = @_;
		return undef unless $filename eq 'DBI.pm';
		require File::Spec;
		require Scalar::Util;
		my $first;
		for(@INC) {
			my $path = File::Spec->catfile($_,$filename);
			if( -r $path ) {
				open(my $fh, "<", $path) or next;
				return sub {
					return 0 if eof($fh);
					$_ = <$fh>;
					$_ =~ s/$/netret_      => { class => 'DBD::NetRetrieve',},/
						if( $_ =~ /my \$dbd_prefix_registry = {/ );
					return 1;
				};
			}
		}
		undef;
	};
}

1;

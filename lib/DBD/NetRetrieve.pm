# vim: fdm=marker
package DBD::NetRetrieve; #{{{

use strict;
use warnings;

use DBI ();
use parent qw(DBI::DBD::SqlEngine);
use Module::Pluggable
	search_path => ['DBD::NetRetrieve::Table'],
	require => 1,
	sub_name => 'get_table_list';

$DBD::NetRetrieve::db::imp_data_size = 0;
$DBD::NetRetrieve::dr::imp_data_size = 0;
$DBD::NetRetrieve::st::imp_data_size = 0;

$DBD::NetRetrieve::ATTRIBUTION = 'DBD::NetRetrieve - Zakariyya Mughal <zmughal@cpan.org>';

our $drh = undef;

DBI->setup_driver("DBD::NetRetrieve");

sub driver {
	return $drh if $drh; # singleton
	my ($class, $attr) = @_;
	my ($err, $errstr, $state) = (0, "", "");
	$attr //= {};
	$attr = {
		%$attr,
		Name              => 'NetRetrieve',
		Version           => $DBD::NetRetrieve::VERSION,
		Attribution       => $DBD::NetRetrieve::ATTRIBUTION,
		Err               => \$err,
		Errstr            => \$errstr,
		State             => \$state,
		Class             => $class,
		AutoCommit        => 1,
	};
	$drh = $class->SUPER::driver($attr) or return undef;
	$drh;
}

sub CLONE {
	undef $drh;
}

1;#}}}
package DBD::NetRetrieve::dr;#{{{

use strict;
use warnings;

use DBI::DBD::SqlEngine;
use parent -norequire => qw(DBI::DBD::SqlEngine::dr);
use vars qw(@ISA $imp_data_size);

#sub data_sources { "" }

1;#}}}
package DBD::NetRetrieve::db;#{{{

use strict;
use warnings;

use DBI::DBD::SqlEngine;
use CHI;
use LWP::UserAgent;
use parent -norequire => qw(DBI::DBD::SqlEngine::db);
use vars qw(@ISA $imp_data_size);

our $DEFAULT_USER_AGENT = "DBD-NetRetrieve/${DBD::NetRetrieve::VERSION}";

sub set_versions {
	my ($dbh) = @_;
	$dbh->{netret_version} = $DBD::NetRetrieve::VERSION;
	return $dbh->SUPER::set_versions();
}

sub STORE {
	my ($dbh, $attrib, $value) = @_;
	# would normally validate and only store known attributes
	# else pass up to DBI to handle
	( $attrib, $value ) = $dbh->func( $attrib, $value, 'validate_STORE_attr' );
	$attrib or return;
	if ($attrib eq 'AutoCommit') {
		# convert AutoCommit values to magic ones to let DBI
		# know that the driver has 'handled' the AutoCommit attribute
		$value = ($value) ? -901 : -900;
	}
	return $dbh->{$attrib} = $value if $attrib =~ /^netret_/;
	return $dbh->SUPER::STORE($attrib, $value);
}

sub init_valid_attributes {
	my $dbh = $_[0];

	$dbh->{netret_valid_attrs} = {
		netret_version         => 1,   # contains version of this driver
		netret_valid_attrs     => 1,   # contains the valid attributes of foo drivers
		netret_readonly_attrs  => 1,   # contains immutable attributes of foo drivers
		netret_useragent       => 1,   # LWP::UserAgent used to interact with HTTP
		netret_cache           => 1,   # caching of results
		netret_email           => 1,   # e-mail address
		netret_eutils_email    => 1,   # specific e-mail address for E-utilities (e.g. PubMed)
		netret_table_list      => 1,   # list of tables (i.e. sites)
	};
	$dbh->{netret_readonly_attrs} = {
		netret_version         => 1,   # ensure no-one modifies the driver version
		netret_valid_attrs     => 1,   # do not permit to add more valid attributes ...
		netret_readonly_attrs  => 1,   # ... or make the immutable mutable
	};

	$dbh->SUPER::init_valid_attributes();

	return $dbh;
}

sub init_default_attributes {
	my ($dbh, $phase) = @_;

	$dbh->SUPER::init_default_attributes($phase);

	if( 0 == $phase ) {
		# init all attributes which have no knowledge about
		# user settings from DSN or the attribute hash
		$dbh->{netret_table_list} = [map { $_ =~ s/DBD::NetRetrieve::Table:://r }
			DBD::NetRetrieve->get_table_list];
	} elsif( 1 == $phase ) {
		# init phase with more knowledge from DSN or attribute
		# hash
		$dbh->{netret_cache} = CHI->new(driver => 'Memory', global => 1)
			unless $dbh->{netret_cache}; # create CHI::Driver used to store cached results
		$dbh->{netret_useragent} = LWP::UserAgent->new( agent => $DEFAULT_USER_AGENT )
			unless $dbh->{netret_useragent}; # create user agent used to interact with sites
	}

	return $dbh;
}

sub get_avail_tables {
	my ($dbh) = @_;
	my @tables;
	push( @tables, [ undef, undef, $_, "TABLE", "AnyData" ] ) for $dbh->{netret_table_list};
	@tables;
}

sub validate_STORE_attr {
    my ( $dbh, $attrib, $value ) = @_;

    if ( $attrib eq "netret_cache" ) {
				$value->isa('CHI::Driver')
          or return $dbh->set_err( $DBI::stderr, "$attrib is not a CHI::Driver: '$value'" );
				return ($attrib, $value);
    } elsif ( $attrib eq "netret_useragent" ) {
				$value->isa('LWP::UserAgent')
          or return $dbh->set_err( $DBI::stderr, "$attrib is not a LWP::UserAgent: '$value'" );
				return ($attrib, $value);
    }

    return ($attrib, $value) = $dbh->SUPER::validate_STORE_attr( $attrib, $value );
}

sub DESTROY {
	my $dbh = shift;
	$dbh->STORE( 'Active', 0 );
}
#}}}
package DBD::NetRetrieve::st;#{{{

use strict;
use warnings;

use DBI::DBD::SqlEngine;
use parent -norequire => qw(DBI::DBD::SqlEngine::st);
use vars qw(@ISA $imp_data_size);

sub execute {
	#use Data::Dumper; die Dumper(@_);
	die "off with her head!";
}

#sub FETCH {
	#use DDP; &p([@_]);
#}
#sub STORE {
	#use Data::Dumper; my $j = Dumper([@_]); die("Test: $j");
	##warn "STORE not supported";
#}

1;#}}}
package DBD::NetRetrieve::Statement;#{{{

use strict;
use warnings;

use DBI::DBD::SqlEngine;
use List::Util qw/first/;
use parent -norequire => qw(DBI::DBD::SqlEngine::Statement);

sub open_table {
	my ($self, $sth, $table, $createMode, $lockMode) = @_;

	my $class = ref $self;
	$class =~ s/::Statement/::Table/;
	die "Table $table not valid" and return
		unless first { $_ eq $table } @{$sth->{Database}->{netret_table_list}};
	die "Only SELECT command supported" unless $sth->{sql_stmt}{command} eq 'SELECT';

	return $class->new($sth, $table, $createMode, $lockMode);
}

1;#}}}
package DBD::NetRetrieve::Table;#{{{

use strict;
use warnings;

use DBI::DBD::SqlEngine;
use parent -norequire => qw(DBI::DBD::SqlEngine::Table);
use Set::Scalar;
use Data::Visitor::Callback;


sub new {
	my ($class, $sth, $table, $createMode, $lockMode) = @_;
	my $table_class = 'DBD::NetRetrieve::Table::'.$table;
	my $table_obj = $table_class->new();
	my @table_columns = sort $table_obj->col_names->members; # all columns

	my $required_where_cols = $table_obj->required_where_cols;
	my $sth_where_cols = Set::Scalar->new(keys($sth->{sql_stmt}{where_cols} // {}));
	die "Required columns in WHERE clause: $required_where_cols"
		unless ($required_where_cols and $required_where_cols <= $sth_where_cols);

	my @column_defs_cols;
	my $column_visitor = Data::Visitor::Callback->new(
		hash => sub {
			my ($visitor, $data) = @_;
			if(exists $data->{type} and $data->{type} eq 'column') {
				push @column_defs_cols, $data->{value} if exists $data->{value};
			}
			$visitor->visit($_) for values $data; # recurse
		}
	);
	$column_visitor->visit($sth->{sql_stmt}{column_defs});

	my $all_columns = Set::Scalar->new();
	for(@column_defs_cols) {
		if($_ eq '*') {
			$all_columns->insert(@table_columns);
		} else {
			$all_columns->insert($_);
		}
	}

	$sth->{NUM_OF_FIELDS} = $all_columns->size;
	$sth->{sql_stmt}{columns} = [$all_columns->members];
	#$sth->{sql_stmt}{limit_clause} => bless( {
                                            #'limit' => '80',
                                            #'offset' => '20'
                                          #}, 'SQL::Statement::Limit' ),

	#use Data::Dumper; die Dumper(
		##$sth,
		##$sth->{sql_stmt},
		##$sth->{NUM_OF_FIELDS},
		##$sth->{sql_stmt}{columns},
		##$sth->{sql_stmt}{where_cols} // {},
		##$sth->{sql_stmt}{column_defs},
		##\@column_defs_cols,
	#);
	$class->SUPER::new({
		sth => $sth,
		table => $table,
		table_class => $table_obj,
		col_names => \@table_columns,
		#col_nums  => { map { $columns[$_] => $_ } 0..@columns-1 },
			# col_nums :
			#   If this is omitted (does not exist), it will be created from "col_names".
			# - SQL::Eval (/SQL::Eval::Table/)
	});
}

sub fetch_row {
	my($self, $data) = @_;
	die "test";
	use DDP; p $self;
	use DDP; p $data;
	#my $fieldstr = $self->{fh}->getline;
	#return undef unless $fieldstr;
	#chomp $fieldstr;
	#my @fields	= split /:/,$fieldstr;
	#$self->{row} = (@fields ? \@fields : undef);
}

# NOPs {{{
sub push_row {}
sub push_names {}
sub seek {}
sub truncate {}
sub drop {}
# }}}

1;#}}}
# Documentation {{{
__END__

=head1 NAME

DBD::NetRetrieve - Database driver

=head1 SEE ALSO

=over 4

=item L<DBD::Google>

=over 2

a similar module that works with the Google SOAP Search API (L<Net::Google>),
however that API is now
L<deprecated|http://googlecode.blogspot.com/2009/08/well-earned-retirement-for-soap-search.html>.

=back

=item L<WWW::Search>

=over 2

L<Large-Scale Active Middleware|http://www.isi.edu/lsam/> project at ISI

=back

=item L<WWW::Scraper>

=over 2

Test

=back

=back

=cut


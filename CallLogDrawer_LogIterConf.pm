package CallLogDrawer_LogIterConf;

use File::Spec;

our $VERSION = '0.1';
our @EXPORT_OK = qw( callptrs_from_logline );

sub callptrs_from_logline {
    my ($logline) = @_;
    ($logline =~ /e\s+(0x[0-9a-f]+)\s+(0x[0-9a-f]+)/) ? (hex($1), hex($2)) : (0, 0)
}

1;

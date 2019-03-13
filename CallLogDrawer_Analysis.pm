package CallLogDrawer_Analysis;

use File::Spec;

our $VERSION = '0.1';
our @EXPORT_OK = qw( new analyze anacmd );

my $anafuncs = {
    addr2line => sub {
        my ($res) = @_;
        if ($res =~ /\s*([_A-Za-z][_A-Za-z0-9]*)\s*at\s*(.+):([0-9]+)/) {
            return ($1, $2, $3, undef);
        } else {
            return ('#', '#', '#', undef);
        }
    },
    'llvm-symbolizer' => sub {
        my ($res) = @_;
        if ($res =~ /\s*([_A-Za-z][_A-Za-z0-9]*)\s*at\s*(.+):([0-9]+):([0-9]+)/) {
            print "$res $1 $2 $3 $4\n";
            return ($1, File::Spec->abs2rel($2), $3, $4);
        } else {
            return ('#', '#', '#', undef);
        }
    }
};

my $anacmds = {
    addr2line => 'LANG=c addr2line -fps -e ',
    'llvm-symbolizer' => 'LANG=c llvm-symbolizer --pretty-print -obj '
};

sub new {
    my ($class, $adriv) = @_;
    my $r = { anasub => $anafuncs->{$adriv} };
    bless $r, $class;
    $r
}

use Data::Dumper;

sub analyze {
    my ($self, $ana_out, $ana_in, $ptr) = @_;
    print $ana_in sprintf("0x%x\n", $ptr);
    my $res = <$ana_out>;
    print "Match begins: res=$res";
    chomp $res;
    my ($func, $srcfile, $lineno, $column) = $self->{anasub}->($res);
    my $r = { func => $func, srcfile => $srcfile, lineno => $lineno, site => $ptr, column => $column };
    print Dumper($r);
    $r
}

sub anacmd {
    my ($adriv, $bin) = @_;
    $anacmds->{$adriv} . $bin
}

1;

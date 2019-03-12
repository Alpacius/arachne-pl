package CallLogDrawer_Analysis;

our $VERSION = '0.1';
our @EXPORT_OK = qw( new analyze anacmd );

my $anafuncs = {
    addr2line => sub {
        my ($res) = @_;
        if ($res =~ /\s*([_A-Za-z][_A-Za-z0-9]*)\s*at\s*([^:]+?):([0-9]+)/) {
            return ($1, $2, $3);
        } else {
            return ('#', '#', '#');
        }
    }
};

my $anacmds = {
    addr2line => 'LANG=c addr2line -fps -e '
};

sub new {
    my ($class, $adriv) = @_;
    my $r = { anasub => $anafuncs->{$adriv} };
    bless $r, $class;
    $r
}

sub analyze {
    my ($self, $ana_out, $ana_in, $ptr) = @_;
    print $ana_in sprintf("0x%x\n", $ptr);
    my $res = <$ana_out>;
    chomp $res;
    my ($func, $srcfile, $lineno) = $self->{anasub}->($res);
    { func => $func, srcfile => $srcfile, lineno => $lineno, site => $ptr }
}

sub anacmd {
    my ($adriv, $bin) = @_;
    $anacmds->{$adriv} . $bin
}

1;

package CallLogDrawer_LogIter;

use lib '.';
use IPC::Open2;
use CallLogDrawer_LogIterConf;

use overload
    '<>' => log_iterate;

our $VERSION = '0.1';
our @EXPORT_OK = qw( new );

sub new {
    my ($class, $bin, $infpath) = @_;
    my $fh;
    if (not defined $infpath) {
        $fh = STDIN;
    } else {
        open($fh, "<", $infpath) or die "Failed to open $infpath: $!";
    }
    my ($ana_in, $ana_out);
    my $pid = open2($ana_out, $ana_in, "LANG=c addr2line -fps -e $bin");
    my $iter = { in => $fh, bin => $bin, pid => $pid, ana_out => $ana_out, ana_in => $ana_in };
    bless $iter, $class;
    $iter
}

sub funcinfo_from_addr {
    my ($iter, $ptr) = @_;
    my ($chld_out, $chld_in) = ($iter->{ana_out}, $iter->{ana_in});
    print $chld_in sprintf("0x%x\n", $ptr);
    my $res = <$chld_out>;
    chomp $res;
    if ($res =~ /\s*([_A-Za-z][_A-Za-z0-9]*)\s*at\s*([^:]+?):([0-9]+)/) {
        return { func => $1, srcfile => $2, lineno => $3, site => $ptr };
    } else {
        return { func => '#', srcfile => '#', lineno => '#', site => $ptr };
    }
}

sub log_iterate {
    my ($self) = @_;
    my $in = $self->{in};
    my $logline = <$in>;
    if (not defined $logline) {
        close $self->{ana_in};
        return undef;
    }
    chomp $logline;
    my ($calleep, $callsitep) = CallLogDrawer_LogIterConf::callptrs_from_logline($logline);
    return undef if ($calleep == 0 and $callsitep == 0);
    {
        callee => funcinfo_from_addr($self, $calleep),
        caller => funcinfo_from_addr($self, $callsitep)
    }
}

1;

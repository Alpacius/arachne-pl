package CallLogDrawer_LogIter;

use lib '.';
use IPC::Open2;
use CallLogDrawer_LogIterConf;
use CallLogDrawer_Analysis;
use Data::Dumper;

use overload
    '<>' => log_iterate;

our $VERSION = '0.1';
our @EXPORT_OK = qw( new );

sub new {
    my ($class, $bin, $infpath, $adriv) = @_;
    my $fh;
    if (not defined $infpath) {
        $fh = STDIN;
    } else {
        open($fh, "<", $infpath) or die "Failed to open $infpath: $!";
    }
    my ($ana_out, $ana_in);
    #my $pid = open2($ana_out, $ana_in, "LANG=c addr2line -fps -e $bin");
    my $pid = open2($ana_out, $ana_in, CallLogDrawer_Analysis::anacmd($adriv, $bin));
    $ana_out->autoflush;
    $ana_in->autoflush;
    my $iter = { 
        in => $fh, 
        bin => $bin, 
        pid => $pid, 
        ana_out => $ana_out, 
        ana_in => $ana_in, 
        ana_driv => CallLogDrawer_Analysis->new($adriv) 
    };
    bless $iter, $class;
    $iter
}

sub funcinfo_from_addr {
    my ($iter, $ptr) = @_;
    $iter->{ana_driv}->analyze($iter->{ana_out}, $iter->{ana_in}, $ptr)

}

sub log_iterate {
    my ($self) = @_;
    my $in = $self->{in};
    my $logline = <$in>;
    if (not defined $logline) {
        #print "End-of-Input reached. Stop scanning.\n";
        close $self->{ana_in};
        return undef;
    }
    chomp $logline;
    my ($calleep, $callsitep) = CallLogDrawer_LogIterConf::callptrs_from_logline($logline);
    return undef if ($calleep == 0 and $callsitep == 0);
    my $r = {
        callee => funcinfo_from_addr($self, $calleep),
        caller => funcinfo_from_addr($self, $callsitep)
    };
    #print "iterate.r=".Dumper($r);
    $r
}

1;

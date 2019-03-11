#!/usr/bin/env perl

use lib '.';
use Getopt::Long;
use CallLogDrawer_LogIter;
use CallLogDrawer_Graph;
use CallLogDrawer_DotDump;

my $inp = undef;
my $binfile = 'a.out';
my $outformat = 'dot';      # dot | dump

GetOptions(
    "T=s" => \$outformat,
    "e=s" => \$binfile,
    "f=s" => \$inp,
    "h|help" => sub {
        my $helptext = <<END_OF_HELP;
Usage: rtcalls_draw.pl [option(s)]
 Dump a text description of runtime call graph (dot source file by default) to stdout 
 utilizing symbols from binary executable.
 The options are:
  -e BINFILE Use symbols from binary executable BINFILE.
             The default is 'a.out'.
  -T FORMAT  Use the output FORMAT. 
             FORMAT can be 'dot' or 'dump'. The default is 'dot'.
  -f LOGPATH Read the call log from LOGPATH. 
             The default is the standard input.
  -h, --help Display this information.
END_OF_HELP
        print $helptext;
        exit 0;
    }
);


my $output_ops = {
    dot => sub {
        my ($g) = @_;
        print CallLogDrawer_DotDump::do_dump($g);
    },
    dump => sub {
        my ($g) = @_;
        print $g->do_dump;
    }
};

sub just_die {
    my ($msg) = @_;
    print "$msg\n";
    exit 1;
}

just_die "No binary image specified -- aborted." if (not defined $binfile);
just_die "Binary image $binfile does not exist -- aborted." if (not -e $binfile);
just_die "Output format $outformat not supported -- use 'dot' or 'dump'. " if (not exists $output_ops->{$outformat});

my $iter = CallLogDrawer_LogIter->new($binfile, $inp);
my $graph = CallLogDrawer_Graph->new;
while (my $callinfo = <$iter>) {
    $graph->add_callinfo($callinfo->{caller}, $callinfo->{callee});
}

$output_ops->{$outformat}->($graph);

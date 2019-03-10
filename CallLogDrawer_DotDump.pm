package CallLogDrawer_DotDump;

our $VERSION = '0.01';
our @EXPORT_OK = qw( do_dump );

sub dump_edge {
    my ($edge) = @_;
    my ($caller, $callee) = ($edge->{caller}, $edge->{callee});
    sprintf "%s->%s [ label=\"0x%x|%s\\ncount:%d\",fontsize=10 ];",
        $caller->{id},
        $callee->{id},
        $edge->{site},
        $caller->{srcfile} . ':' . $edge->{lineno},
        $edge->{count};
}

sub dump_vertex {
    my ($vertex) = @_;
    sprintf "%s[ shape=box,label=\"%s\",style=filled,fontsize=12 ];",
        $vertex->{id},
        $vertex->{func} . ':' . $vertex->{srcfile};
}

sub do_dump {
    my ($g) = @_;
    my $res = "digraph runtime_calls { \n";
    # Attach edge info: vX -> vY [ label="rawsite|callerpos|count:N",fontsize=F1 ];
    while (my ($vid, $edges) = each %{$g->{v2efidx}}) {
        for my $edge (values %$edges) {
            $res .= '    ' . dump_edge($edge) . "\n";
        }
    }
    # Attach vertex info: vX[ shape=box,label="func: srcfile",style=filled,fontsize=F2 ];
    for my $vertex (values %{$g->{vertices}}) {
        $res .= '    ' . dump_vertex($vertex) . "\n";
    }
    $res . "}\n"
}

1;

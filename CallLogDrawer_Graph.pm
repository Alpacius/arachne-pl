package CallLogDrawer_Graph;

our $VERSION = '0.1';
our @EXPORT_OK = qw ( new add_callinfo do_dump );

sub new {
    my ($class) = @_;
    my $vidxgen = 0;
    my $vidgen = sub { 'v' . $vidxgen++ };
    my $g = {
        edges => {},
        vertices => {},
        vnameidx => {},
        v2efidx => {},
        vidgen => $vidgen
    };
    bless $g, $class;
    $g
}

sub vsign {
    my ($v) = @_;
    '[' . $v->{func} . ':' . $v->{srcfile} . ']'
}

sub esign {
    my ($f, $t) = @_;
    '|' . vsign($f) . '->' . vsign($t) . '@' . sprintf('%x', $f->{site}) . '|'
}

sub funcinfo_eq {
    (my $lhs, $rhs) = @_;
    ($lhs->{func} eq $rhs->{func}) and ($lhs->{srcfile} eq $rhs->{srcfile})
}

sub siteinfo_eq {
    funcinfo_eq @_
}

sub make_callinfo {
    my ($caller, $callee) = @_;
    { caller => $caller, callee => $callee, site => $caller->{site}, lineno => $caller->{lineno}, count => 1 }
}

sub make_funcinfo {
    my ($g, $siteinfo) = @_;
    { id => $g->{vidgen}->(), func => $siteinfo->{func}, srcfile => $siteinfo->{srcfile} }
}

sub contains_funcinfo {
    my ($g, $v) = @_;
    my $vsgn = vsign $v;
    exists $g->{vertices}->{$vsgn}
}

sub fetch_funcinfo {
    my ($g, $v) = @_;
    my $vsgn = vsign $v;
    $g->{vertices}->{$vsgn}
}

sub contains_callinfo {
    my ($g, $caller, $callee) = @_;
    my $site = $caller->{site};
    my $esgn = esign $caller, $callee;
    exists $g->{edges}->{$esgn}
}

sub touch_callinfo {
    my ($g, $caller, $callee) = @_;
    my $site = $caller->{site};
    my $esgn = esign $caller, $callee, $site;
    my $callinfo = $g->{edges}->{$esgn};
    my $count = $callinfo->{count};
    $callinfo->{count} = $count + 1;
}

sub add_callinfo {
    my ($g, $caller, $callee) = @_;
    # Just touch the edge if it exists.
    if ($g->contains_callinfo($caller, $callee)) {
        $g->touch_callinfo($caller, $callee);
        return;
    }
    # We've got a new edge. First, attach it to the edge set.
    my $callinfo = make_callinfo($caller, $callee);
    my $esgn = esign $caller, $callee;
    $g->{edges}->{$esgn} = $callinfo;
    # Add callee to the vertex set & vertex-only indices if necessary.
    if (not $g->contains_funcinfo($callee)) {
        my $v_callee_sgn = vsign $callee;
        my $v_callee = $g->make_funcinfo($callee);
        $g->{vertices}->{$v_callee_sgn} = $v_callee;
        $g->{vnameidx}->{$v_callee->{id}} = $v_callee;
    }
    # Add callee to the vertex set & vertex-only indices if necessary.
    my $call_from = undef;
    if (not $g->contains_funcinfo($caller)) {
        my $v_caller_sgn = vsign $caller;
        my $v_caller = $g->make_funcinfo($caller);
        $g->{vertices}->{$v_caller_sgn} = $v_caller;
        $g->{vnameidx}->{$v_caller->{id}} = $v_caller;
        $call_from = $v_caller;
    } else {
        $call_from = $g->fetch_funcinfo($caller);
    }
    # Add callinfo to forward index if necessary.
    if (not exists $g->{v2efidx}->{$call_from->{id}}) {
        $g->{v2efidx}->{$call_from->{id}} = { $esgn => $callinfo };
    } else {
        my $efidx = $g->{v2efidx}->{$call_from->{id}};
        $efidx->{$esgn} = $callinfo if (not exists $efidx->{$esgn});
    }
    # Update callinfo s.t. it contains the real vertices.
    $callinfo->{caller} = $g->fetch_funcinfo($caller);
    $callinfo->{callee} = $g->fetch_funcinfo($callee);
}

sub dump_funcinfo {
    my ($v) = @_;
    $v->{func} . '@' . $v->{srcfile}
}

sub dump_callinfo {
    my ($e) = @_;
    '[' . 
        dump_funcinfo($e->{caller}) . '->' . dump_funcinfo($e->{callee}) .
        '|' .
        'site:' . sprintf("0x%x", $e->{site}) . '(ln:' . $e->{lineno} . ')' .
        '|' .
        'count:' . $e->{count} .
    ']'
}

sub do_dump {
    my ($g) = @_;
    my $res = '';
    while (my ($vid, $edges) = each %{$g->{v2efidx}}) {
        $res .= sprintf("[vertex %s (%s)] %d call site(s):\n", 
            $vid, 
            dump_funcinfo($g->{vnameidx}->{$vid}),
            scalar values(%$edges));
        for my $edge (values %$edges) {
            $res .= "\t" . dump_callinfo($edge) . "\n";
        }
    }
    $res
}

1;

#!/usr/bin/perl -w
use strict;
use POSIX ();

foreach(2.3, 3.8, -2.3, -3.8) {
    print "floor of $_ is ", floor($_), "\n";
}
foreach(2.3, 3.8, -2.3, -3.8) {
    print "ceil of $_ is ", ceil($_), "\n";
}

sub floor
{
    my $d = shift;
    return $d if index($d, '.') == -1;
    my $fract;
    if($d < 0)
    {
        $d = -$d;
        ($d, $fract) = split('\.', $d);
        $d += 1 if $fract != 0;
        $d = -$d;
    } else {
        ($d) = split('\.', $d);
    }
    return $d;
        
}

sub ceil
{
    my $d = shift;
    return -(floor(-$d));
}
#sub floor
#{
#    return ceil($_[0]) + 1
#}


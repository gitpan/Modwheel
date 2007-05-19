#!/usr/local/bin/perl
use strict;
use warnings;
use FCGI::Modwheel;
use FCGI::Modwheel::Server;
use Getopt::Long;

my $help = 0;
my ($listen, $nproc, $pidfile, $manager, $detach);
GetOptions(
    'nproc|n=i'   => \$nproc,
    'daemon|D'    => \$detach,
    'manager|M=s' => \$manager,
    'pidfile|p=s' => \$pidfile,
    'listen|l=s'  => \$listen,
    'help|?'      => \$help,
);

my $handler = FCGI::Modwheel->new( );
FCGI::Modwheel::Server->run($handler, $listen, {
    detach  => $detach,
    nproc   => $nproc,
    manager => $manager, 
    pidfile => $pidfile,
});


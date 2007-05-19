#!/usr/bin/perl
use strict;
use warnings;
use Modwheel::Session;
use vars qw($TODO);

use Test::More;

plan(skip_all => 'Tests not finished.');

my $t = Modwheel::Object->new( );

print $t->modwheel, "\n";

print $t->db, "\n";

print $t->db->modwheel, "\n";

#$t->init({input => './test.html'});

#print $t->process( );

my $modwheel2 = Modwheel->new({
    prefix => '/opt/modwheel',
    configfile => 'config/modwheelconfig.yml',
});

print $modwheel2, "\n";

$t->db->connect;

my $new_o = $t->fetch({id => 1});
print $new_o->name, "\n";


#!/usr/bin/perl -w
use strict;
use Data::Dumper;
#use Data::Structure::Util qw(has_circular_ref);

use Test::More tests => 8;

BEGIN {
    use lib '/opt/devel/Modwheel/lib';
}

use Modwheel::Session;
use Modwheel::HTML::Tagset;

my $modwheel_config =
{
    prefix          => './',
    configfile      => 't/modwheelconfig.yml',
    site            => 'modwheeltest',
    configcachetype => 'memshare',
    locale          => 'en_EN',
};

my($modwheel, $user, $db, $object, $repository, $template) =
    modwheel_session($modwheel_config, qw(db user object template repository));
$modwheel->debug(0);
$db->connect();

my $args = { };

#$template->init(input => './myfile.html');
#print $template->process($args);
$template->init();

my $tk = $template->tkmodwheel;

print $tk->floor(2.3), "\n";

is($tk->floor(2.3), 2, 'floor(2.3) 2?');
is($tk->floor(3.8), 3, 'floor(3.8) 3?');
is($tk->floor(-2.3), -3, 'floor(-2.3) -3?');
is($tk->floor(-3.8), -4, 'floor(-3.8) -4?');
is($tk->ceil(2.3), 3, 'ceil(2.3) 3?');
is($tk->ceil(3.8), 4, 'ceil(3.8) 4?');
is($tk->ceil(-2.3), -2, 'ceil(-2.3) -2?');
is($tk->ceil(-3.8), -3, 'ceil(-3.8) -3?');

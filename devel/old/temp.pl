#!/usr/bin/perl -w
use strict;

BEGIN {
    use lib '/opt/devel/Modwheel/lib';
}

use Template::Context;
use Modwheel::Session;
use Modwheel::Template::TT;

my $modwheel_config = {
    prefix          => '/opt/devel/modwheel',
    configfile      => 't/modwheeltestcfg.xml',
    site            => 'modwheeltest',
    configcachetype => 'memshare',
    locale          => 'en_EN',
};

my($modwheel, $user, $db, $object, $template) =
    modwheel_session($modwheel_config, qw(db user template object));
$db->connect();

my $config = {
    INCLUDE_PATH => $modwheel->siteconfig->{templatedir},
    INTERPOLATE  => 1,               # expand "$var" in plain text
    POST_CHOMP   => 1,               # cleanup whitespace
    RELATIVE     => 1,
    PLUGINS => {
        Modwheel => 'Modwheel::Template::TT'
    }
};

my $context = Template::Context->new($config);
my $stash   = $context->stash;
my $tkmodwheel = $context->plugin('Modwheel', [$modwheel, $user, $db, $object, $template]);
$stash->set('modwheel', $tkmodwheel);

my $args = { };

my $input = './myfile.html';

print $context->process($input, $args), "\n";

$db->disconnect;

#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Data::Structure::Util qw(has_circular_ref);
#use Devel::LeakTrace;
#use Devel::Leak::Object;
#use Devel::Leak::Object qw(GLOBAL_bless);

BEGIN {
    use lib '/opt/devel/Modwheel/lib';
}

use Modwheel::Session;
use Modwheel::HTML::Tagset;

my $modwheel_config =
{
    prefix          => '/opt/devel/Modwheel',
    configfile      => 't/modwheelconfig.yml',
    site            => 'modwheeltest',
    configcachetype => 'memshare',
    locale          => 'en_EN',
};

my($modwheel, $user, $db, $object, $repository, $template) =
    modwheel_session($modwheel_config, qw(db user object template
repository));
#foreach(($modwheel, $user, $db, $object, $repository, $template)) {
#    Devel::Leak::Object::track($_);
#}
$modwheel->set_debug(0);
$db->connect();

#print $db->build_select_q('object', [qw(type parent)], {id => '?', type =>
#'?', name => '?'});
#print $db->build_select_q('object', [qw(type parent)], [qw(id type name)]);
    my $q = $db->build_select_q('object', '*', {type => q{'article'} },
{limit => 10, offset => 5, order => 'changed DESC'});

print $q, "\n";

    my $q2 = $db->build_update_q('object', [qw(name type changed owner)], ['id']);

print $q2, "\n";

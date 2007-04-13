#!/usr/bin/perl -w
use strict;

BEGIN {
    use lib '/opt/devel/Modwheel/lib';
}

use Modwheel::Session;

my $modwheel_config = {
    prefix          => '/opt/devel/Modwheel',
    configfile      => 't/modwheelconfig.yml',
    site            => 'modwheeltest',
    configcachetype => 'memshare',
    locale          => 'en_EN',
};

my($modwheel, $db, $user, $object, $template) =
    modwheel_session($modwheel_config, qw(db user object template));

$db->connect or exit;

#my $query = $db->build_select_q('object', "active, owner, groupo, sort, mode, template", id => 1);
my $query = $db->build_select_q('object', [qw(active owner groupo sort mode template)], {id => '?'});
my $sth = $db->prepare($query);
$sth->execute(1);
my $values = $db->fetchrow_hash($sth);
$db->query_end($sth);

print $values->{active}, "\n";
print $values->{owner}, "\n";
print $values->{groupo}, "\n";
print $values->{sort}, "\n";
print $values->{template}, "\n";

$object = $object->fetch({ id => 1 });
$object->set_defaults;
print $object->description, "\n";

my $no = Modwheel::Object->new(modwheel => $modwheel, user => $user, db => $db);
$no->set_defaults;
$no->name('This is a test article');
$no->description('Trying out the brand new save function.');
$no->parent(1);
$no->type('article');
print $no->save, "\n";

$db->disconnect;

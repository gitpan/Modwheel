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
    modwheel_session($modwheel_config, qw(db user object template repository));
#foreach(($modwheel, $user, $db, $object, $repository, $template)) {
#    Devel::Leak::Object::track($_);
#}
$modwheel->debug(0);
$db->connect();

print $db->build_delete_q('object', {parent => Modwheel::Object::MW_TREE_TRASH}), "\n";

foreach(($modwheel, $user, $db, $object, $repository, $template)) {
    if(has_circular_ref($_)) {
        print "HAS CIRCULAR REF: ", ref $_, "\n";
    }
}

print $db->create_dsn, "\n";

print $modwheel->config->{shortcuts}{cpanauthor}, "\n";

my $args = { };

#$object->create_tag('linux');
#$object->disconnect_from_tag(6, 10);

my $tags = $object->get_tags_for_object(10);
print "---------------------------------------------------\n";
foreach(@$tags) {
    print "($_->{id}) $_->{name}\n";
}
print "---------------------------------------------------\n";

#print $db->build_select_q({objtagmap => 'm', tags => 't'}, 'DISTINCT(t.name), t.tagid', {'m.objid' => '10', 't.tagid' => 'm.tagid'} ), "\n";
my $tag = 'Programming';
$tag = $db->sqlescape($tag);
my $q = $db->build_select_q(
    {object => 'o', objtagmap => 'm', tags => 't'},
    'o.name',
    {'o.id' => 'm.objid', 't.name' => "\%op=IN\%('$tag')"},
    {group => 'o.id'}
);
my $oname = $db->fetch_singlevar($q);
print "NAME: $oname\n";

    

#print $db->build_update_q('user', {username => 'ask'});

#$user->create(username => 'ask', password => 'fiskfisk', email => 'ask@0x61736b.net', real_name => 'Ask Solem Hoel');
#print($modwheel->error, "\n") if $modwheel->error;
#my $u = $user->get('ask');
#print($modwheel->error, "\n") if $modwheel->error;
#print $u->{email}, "\n";

#my $query = $db->build_select_q('users', undef, {username => 'ask'});
#print $query, "\n";
#print ref $query, "\n";
#print "HEI" if UNIVERSAL::isa($query, 'SCALAR');

#$template->init(input => './myfile.html');
#print $template->process($args);
$template->init();

#my $query2 = $db->build_select_q('object', [qw(id type active)], {parent => '?', 'LOWER(name)' => '?'});
#print "QUERY 2: $query2\n\n\n";

#my $query3 = "SELECT id, type, active FROM object WHERE (LOWER(name) = ?) AND (parent = ?)";
#my $query3 = $db->build_select_q('object', [qw(id type active)], {parent => '?', 'LOWER(name)' => '?'});
#my $sth = $db->prepare($query3);
#$sth->execute('Music', '1');
#print "ROWS: ", $sth->rows, "\n";

my $tkmodwheel = $template->tkmodwheel;
my $tkobj = $tkmodwheel->fetchObject({id => 1});
print $tkobj->name, "\n";
my $string = qq{

<b>hei</b>

og 

hei
};
print $tkmodwheel->esc2($string);
#print $template->tkmodwheel->abbreviatePath("root::temp::Test Of Articles::Programming::Logo::Tips+Tricks"), "\n";

#my $string = "heiheihei [file:1]\n";
#print $template->shortcuts->parse($string), "\n";

my $query = $db->build_select_q('repository', [qw(path)], {id=>'?'});
my $path = $db->fetch_singlevar($query, 1);
print $path, "\n";
my $deleteq = $db->build_delete_q('repository', {id=>'?'});
print $deleteq, "\n";

#my $query = $db->build_select_q('repository', [qw(name parentobj)], {id=>'?'});
#my $entry = $db->fetchonerow_hash($query, 1);
#my $uri = $modwheel->siteconfig->{repositoryurl}. '/'. $entry->{parentobj}. '/'. $entry->{name};
#print $uri, "\n";

#$tkobject = $template->tkmodwheel->createObject({type => 'article'});
#print $tkobject->type, "\n";
#my $objects = $object->fetch({parent => 1, type=>'"article"'});
#if(ref $objects eq 'ARRAY') {
#    foreach(@$objects) {
#        print $_->name, "\n";
#    }
#}

#my $where = $db->internal_build_where_clause({id => 1, parent => 2, name => '%op=LIKE% "ask"'});
#print $where, "\n";

#my $query = $db->build_update_q('object', {type => '"link"', parent => Modwheel::Object::MW_TREE_ROOT}, {parent=>10});
#print $query, "\n";

#my $username = 'ask';
#my $query   = $db->build_select_q('users', ['id', 'password'], {username => '?'});
#print $query, "\n";
#my $a =  $db->fetchonerow_array($query, $username);
#print $a->[1], "\n";
#$query = $db->build_select_q('object', [qw(active owner groupo sort mode template)], {id => '?'});
#my $sth = $db->prepare($query);
#$sth->execute(1);
#my $values = $db->fetchrow_hash($sth);
#$db->query_end($sth);
#print $query, "\n";

#print "---------------------------\n";
#$query = $db->build_select_q('users', ['*'], {},  {order=>'username ASC'});
#print $query, "\n";

#my $tk = $template->tkmodwheel;
#my $objects = $tk->fetchObject({parent => 10});
#$objects = $tk->postSortDirectoriesFirst($objects);
#print $objects, "\n";
#my @sorted = sort { $b->type eq 'directory' } @$objects;
#foreach(@sorted) {
#    print $_->type, "\n";
#}

#$query = $db->build_update_q('object', {parent => Modwheel::Object::MW_TREE_TRASH});
#print $query, "\n";

#sub abbreviate
#{
#    my($string, $maxsize) = @_;
#    $maxsize ||= 25;
#    if(length $string > $maxsize)
#    {
#        $string  = substr($string, 0, $maxsize-3);
#        $string .= '...';
#    }
##    return $string;
#}

#my $searchstr = 'mysql';
#$searchstr = $db->sqlescape($searchstr);
# $query = 'SELECT distinct(name), description, keywords FROM object WHERE name or keywords or description or data like("'. '%'. $searchstr. '%")';
#my $sth = $db->prepare($query);
#$sth->execute();
#my %results;
#while(my $href = $db->fetchrow_hash($sth)) {
#    print abbreviate($href->{description}, 50), "\n";
#}
#$db->query_end($sth);
#
#$db->disconnect();

#!/usr/bin/perl -w
use strict;
use Data::Dumper;
#use Data::Structure::Util qw(has_circular_ref);

use Test::More tests => 34;

BEGIN {
    use lib '/opt/devel/Modwheel/lib';
    use lib './t';
}

use Modwheel::Session;
use Modwheel::HTML::Tagset;
use Test::Modwheel qw( :boolean );
use English qw( -no_match_vars );
use Readonly;

our $THIS_BLOCK_HAS_TESTS;

Readonly my $TEST_PREFIX     => './';
Readonly my $TEST_CONFIGFILE => 't/modwheelconfig.yml';
Readonly my $TEST_SITE       => 'modwheeltest';
Readonly my $TEST_LOCALE     => 'en_EN';
Readonly my $TEST_LOGMODE    => 'off';

my $modwheel_config = {                                               
    prefix               => $TEST_PREFIX,                            
    configfile           => $TEST_CONFIGFILE,                        
    site                 => $TEST_SITE,                              
    locale               => $TEST_LOCALE,                            
    logmode              => $TEST_LOGMODE,                           
};

my $test_modwheel = Test::Modwheel->new({
    config => $modwheel_config,
});

my $DATABASE_AVAILABLE;
my $MISSING_DB_MODULE;
if ($test_modwheel->database_driver) {                                                                                                       
    $DATABASE_AVAILABLE = 1;                                                                                                                 
}

my $modwheel    = Modwheel->new($modwheel_config);
my $db;
if ($DATABASE_AVAILABLE) {
    $db         = Modwheel::DB->new({
       modwheel => $modwheel,
    });
    $MISSING_DB_MODULE = $test_modwheel->db_missing_required_module($db);
}
my $user        = Modwheel::User->new({
    modwheel    => $modwheel,
    db          => $db,
});
my $object      = Modwheel::Object->new({
    modwheel    => $modwheel,
    db          => $db,
    user        => $user,
});

my $repository  = Modwheel::Repository->new({
    modwheel    => $modwheel,
    db          => $db,
    user        => $user,
});
my $template    = Modwheel::Template->new({
    modwheel    => $modwheel,
    db          => $db,
    user        => $user,
    object      => $object,
    repository  => $repository,
});

$modwheel->set_debug(0);

my $args = { };

#$template->init({input => './myfile.html'});
#print $template->process($args);
$template->init({});

my $tk = $template->tkmodwheel;

$object->set_name(       'Test name'       );
$object->set_description('Test description');
$object->set_data(       'Test data'       );

my $proxy = Modwheel::Template::ObjectProxy->new($object);

foreach my $method (keys %Modwheel::Object::attributes) {
    ok($proxy->can($method),     "ObjectProxy->can $method()");
}
foreach my $method (qw(new setObjectValues)) {
    ok($proxy->can($method),     "ObjectProxy->can $method()");
}

is($proxy->name,        'Test name'       );
is($proxy->description, 'Test description');
is($proxy->data,        'Test data'       );

$proxy->setObjectValues({
    name => '#%testname%#',
    type => '#%testtype%#',
    data => '#%testdata%#',
    detach => 0,
    id  => 100,
    changed => q{},
    
});

ok(! $proxy->setObjectValues() );

ok(! $proxy->setObjectValues({
    '!nonExisZting0BjEEEctFiiild!' => 30,
}) );

pass('Skips non-existing fields');

is($proxy->name, '#%testname%#', 'setObjectValues()');
is($proxy->type, '#%testtype%#', 'setObjectValues()');
is($proxy->data, '#%testdata%#', 'setObjectValues()');
is($proxy->id, 100, 'setObjectValues()');
is($proxy->detach, 0, 'setObjectValues()');

my $dummy = DummyObject->new();
$dummy->set_name('Dummy Test Name');
my $dummyproxy = Modwheel::Template::ObjectProxy->new($dummy);
is($dummyproxy->name, 'Dummy Test Name');
$dummyproxy->setObjectValues({
    name => '#%testname%#',
    type => '#%testtype%#',
    data => '#%testdata%#',
    detach => 0,
    id  => 100,

});
is($dummyproxy->name, '#%testname%#', 'setObjectValues()');

# ### Features that require database goes below here.
$THIS_BLOCK_HAS_TESTS = 2;
SKIP:
{
    if ( not $ENV{MODWHEEL_DBTEST} ) {
        my $msg = 'Database test.  Set $ENV{MODWHEEL_DBTEST} to a ' .
                  'true value to run. If you do: be sure to set up a TEST ' .
                  'database in the configuration files in t/*.yml and ' .
                  'to not use a live production database.';
        skip $msg, $THIS_BLOCK_HAS_TESTS;
    }
    if ($DATABASE_AVAILABLE) {                                      # TEST 9
        pass( );
    }
    else {
        skip 'Database not available. This is not an error.',
            $THIS_BLOCK_HAS_TESTS
        ;
        fail( );
    }
    
    if ($MISSING_DB_MODULE) {
       skip "The database driver used in the test configuration " .
             "file ($TEST_CONFIGFILE) requires the external module " .
             "$MISSING_DB_MODULE, " .
             "please install via CPAN or change to another database driver.\n",
            $THIS_BLOCK_HAS_TESTS - 1;
    } 

    $db->connect();

    if ($db->connected) {                                           # TEST 10
        pass( );
    }
    else {
        skip "Could not connect to the database. Please change the"         .
         "database configuration in $TEST_CONFIGFILE to run this test.\n"   ,
            $THIS_BLOCK_HAS_TESTS - 1;
        fail( );
    }

    $db->disconnect() if $db->connected;
}

package DummyObject;

sub new {
    return bless { }, shift;
}

sub name {
    return $_[0]->{_name};
}

sub set_name {
    $_[0]->{_name} = $_[1];
    return;
}

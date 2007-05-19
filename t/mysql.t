#!/usr/bin/perl -w
use strict;
use English qw( -no_match_vars );
use Data::Dumper;
use FindBin qw($Bin);
#use Data::Structure::Util qw(has_circular_ref);

use Test::More;

if ( not $ENV{MODWHEEL_DBTEST} ) {
    my $msg = 'Database test.  Set $ENV{MODWHEEL_DBTEST} to a ' .
        'true value to run. If you do: be sure to set up a TEST ' .
        'database in the configuration files in t/*.yml and ' .
        'to not use a live production database.';
        plan skip_all => $msg;
}

eval 'use Modwheel::DB::MySQL';
if ($EVAL_ERROR) {
    plan skip_all => 'Cannot load Modwheel::DB::MySQL';
}

eval 'use DBD::mysql';
if ($EVAL_ERROR) {
    plan skip_all =>
        'DBD::mysql not installed. If MySQL is the data' .
        'base you want to use, you have to install it.'
}




plan tests => 3;

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

Readonly my $TEST_PREFIX     => $Bin;
Readonly my $TEST_CONFIGFILE => 'mysqlconfig.yml';
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
$modwheel->set_debug(0);

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
        skip "Skip MySQL tests: Could not connect to the database. Change the"         .
         "database configuration in $TEST_CONFIGFILE to run this test.\n"   ,
            $THIS_BLOCK_HAS_TESTS ;
        fail( );
    }

    ok( $db->maintainance( ), 'MySQL Maintainance' );

    $db->disconnect() if $db->connected;
}

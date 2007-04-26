#!/usr/bin/perl -w
use strict;
use English qw( -no_match_vars );
use Data::Dumper;
#use Data::Structure::Util qw(has_circular_ref);

use Test::More;

if ( not $ENV{MODWHEEL_DBTEST} ) {
   my $msg = 'Database test.  Set $ENV{MODWHEEL_DBTEST} to a ' .
       'true value to run. If you do: be sure to set up a TEST ' .
       'database in the configuration files in t/*.yml and ' .
       'to not use a live production database.';
   plan skip_all => $msg;
}

eval 'use Modwheel::DB::PostgreSQL';
plan skip_all => 'Cannot load Modwheel::DB::PostgreSQL' if $EVAL_ERROR;

eval 'use DBD::Pg';
if ($EVAL_ERROR) {
    plan skip_all => 
        'The DBI database driver for PostgreSQL ( DBD::Pg ) ' .
        'is not installed. If you are going to use Postgres, ' .
        'you have to install it.'
}




plan tests => 2;

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
Readonly my $TEST_CONFIGFILE => 't/postgresconfig.yml';
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
    if ($DATABASE_AVAILABLE) {                                      # TEST 9
        pass( );
    }
    else {
        skip 'Database not available. This is not an error.',
            $THIS_BLOCK_HAS_TESTS
        ;
        fail( );
    }

    eval {$db->connect();};

    if (!$EVAL_ERROR && $db->connected) {                                           # TEST 10
        pass( );
    }
    else {
        skip "Skip PostgreSQL tests: Could not connect to the database. Change the"         .
         " database configuration in $TEST_CONFIGFILE to run this test.\n"   ,
            $THIS_BLOCK_HAS_TESTS - 1;
        fail( );
    }

    ok( $db->maintainance( ), 'PostgreSQL Maintainance' );

    $db->disconnect() if $db->connected;
}

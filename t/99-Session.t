# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Modwheel.t'


#########################

use Test::More tests => 5;
BEGIN {
    use lib '/opt/devel/Modwheel/lib';
    use lib './t';
    use_ok('Modwheel');                                               # TEST 1                        
    use_ok('Modwheel::Session');                                      # TEST 2
};

#########################

use strict;
use Readonly;
use Test::Modwheel qw( :boolean );
use English qw( -no_match_vars );

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

my($modwheel, $db, $user, $object, $repository, $template);

if ($DATABASE_AVAILABLE) {    
    ($modwheel, $user, $db, $object, $repository, $template) =
     modwheel_session($modwheel_config, qw(user db object repository template));
    pass('Create Modwheel CGI/Terminal session');                   
    $MISSING_DB_MODULE = $test_modwheel->db_missing_required_module($db);
}
else {
     ($modwheel, $user, undef, $object, $repository, $template) =
     modwheel_session($modwheel_config, qw(user object repository template));
    pass('Create Modwheel CGI/Terminal session');                   
}
    

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
    if ($DATABASE_AVAILABLE) {
        pass( );                                                    # TEST 4
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

    if ($db->connected) {
        pass( );                                                    # TEST 5
    }
    else {
        skip "Could not connect to the database. Please change the"         .
         "database configuration in $TEST_CONFIGFILE to run this test.\n"   ,
            $THIS_BLOCK_HAS_TESTS - 1;
        fail( );
    }

    $db->disconnect() if $db->connected;

}

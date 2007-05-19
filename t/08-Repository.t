#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 765;
use FindBin qw($Bin);

BEGIN {
    use lib $Bin;
    use_ok('Modwheel::Repository');
}

use Modwheel::Session;
use Modwheel::HTML::Tagset;
use Test::Modwheel qw( :boolean );
use English qw( -no_match_vars );
use Params::Util ('_HANDLE', '_ARRAY', '_HASH');
use Readonly;
use Fcntl;

our $THIS_BLOCK_HAS_TESTS;

Readonly my $TEST_PREFIX     => $Bin;
Readonly my $TEST_CONFIGFILE => 'modwheelconfig.yml';
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

my $unix_filename_file = File::Spec->catfile($TEST_PREFIX, 'testfilenames.UNIX');
my $tfn = $repository->safeopen($unix_filename_file, Fcntl::O_RDONLY);

ok( _HANDLE($tfn), 'safeopen returns filehandle' );

my $count_fn = 1;
while( my $filename = <$tfn>) {
    $count_fn++;
    if ($count_fn == 125 ) {
        chomp $filename;
        ok( $repository->_check_filename($filename, 1), "Untaint legal filename: $filename");
        $count_fn = 0;
    }
}

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

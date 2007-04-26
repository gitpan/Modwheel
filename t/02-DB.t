
#########################

use Test::More tests => 45;
BEGIN {
    use lib '/opt/devel/Modwheel/lib';
    use lib './t';
    use_ok('Modwheel');                                             # TEST 1
    use_ok('Modwheel::Session');                                    # TEST 2
};

#########################

use strict;
use Readonly;
use English qw( -no_match_vars );
our $THIS_BLOCK_HAS_TESTS;

use Test::Modwheel  qw( :boolean );

Readonly my $TEST_PREFIX     => './';
Readonly my $TEST_CONFIGFILE => 't/modwheelconfig.yml';
Readonly my $TEST_SITE       => 'modwheeltest';
Readonly my $TEST_LOCALE     => 'en_EN';
Readonly my $TEST_LOGMODE    => 'off';

$THIS_BLOCK_HAS_TESTS = 43;
SKIP:
{

    if ( not $ENV{MODWHEEL_DBTEST} ) {
        my $msg = 'Database test.  Set $ENV{MODWHEEL_DBTEST} to a ' .
                  'true value to run. If you do: be sure to set up a TEST ' .
                  'database in the configuration files in t/*.yml and ' .
                  'to not use a live production database.';
        skip $msg, $THIS_BLOCK_HAS_TESTS;
    }

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
    
    if ($test_modwheel->database_driver) {                          # TEST 3
        pass('Database driver exists.');
    }
    else {
        my $driver_filename =
            $test_modwheel->database_driver_module_filename();
        skip "Could not load the  database backend driver: "          .
             "$driver_filename. It was specified "                    .
             "in the test configuration file ($TEST_CONFIGFILE). "    .
             "Please install it from CPAN or change the driver.\n"    ,
             $THIS_BLOCK_HAS_TESTS;
        fail( );
    }

    # ########## Create a full Modwheel session for the real testing.

                                                                    # TEST 4
    ok( my($modwheel, $user, $db, $object, $template) =         
            modwheel_session($modwheel_config, qw(db user template object)
        ), 'Create Modwheel CGI/Terminal session'
    );
                                                                    # TEST 5
    isa_ok( $db, 'Modwheel::DB::Base',                   
        'Has the db object inherited from Modwheel::Generic?'
    );

                                                                    # TEST 6
    ok( $db->can('driver_requires'),
        'Current database driver has driver_requires method'
    );

    my $module_missing = $test_modwheel->db_missing_required_module($db);
    if ($module_missing) {
        skip "The database driver used in the test configuration "             .
             "file ($TEST_CONFIGFILE) requires the external module "           .
             "$module_missing, "                                               .
             "please install via CPAN or change to another database driver.\n" ,
             $THIS_BLOCK_HAS_TESTS - 4;
    }

    my $dsn = $db->create_dsn;
    ok( defined $db->RaiseError(0), 'Turn off raise error feature.' ); # TEST 7
    ok( defined $db->PrintError(0), 'Turn off error logging.'       ); # TEST 8
    ok( $dsn,                       'Create DBI dsn'                ); # TEST 9

    $db->connect;

    if (! $db->connected) {
        skip "Could not connect to the database. Maybe the database is "    .
         " not available? Please check your db server or change the "       .
         "database configuration in $TEST_CONFIGFILE to run this test.\n"   ,
            $THIS_BLOCK_HAS_TESTS - 7;
    }

    # Test that we cannot create a database driver with a bogus name.
    my $siteconfig = $modwheel->siteconfig( );
    my $old_dbdriver = $siteconfig->{database}{type};
    $siteconfig->{database}{type} = 'SDAS*#(*)&@(&#)(@##%$ADASD';
    ok(! Modwheel::DB->new({
        modwheel => $modwheel,
    }), 'bail on tainted database driver name');
    $siteconfig->{database}{type} = $old_dbdriver;

    my $another_db = Modwheel::DB->new({
        modwheel => $modwheel,
    });
    ok( $another_db->connect( ), 'Simultaneous connections' );
    ok( $another_db->connected );

    $another_db->disconnect( );
    ok(!$another_db->connected, 'disconnect (2nd instance)');

    ok( $another_db->connect_cached( ), 'connect_cached (w/o config hash)');
    ok( $another_db->connected );
    $another_db->disconnect( );
    ok(!$another_db->connected, 'disconnect' );

    ok( $another_db->connect_cached({ BogusPlaceHolder=>1 }),
        'connect_cached (with config hash)'
    );
    ok( $another_db->connected );
    $another_db->disconnect( );
    ok(!$another_db->connected, 'disconnect' );

    ok( $another_db->connect({ cached => 1 }, 'connect({cached => 1})'));
    ok( $another_db->connected );
    $another_db->disconnect;
    ok(!$another_db->connected );
    


    ok( $db->current_timestamp,              'Get current database timestamp');  # TEST 10
    ok( $db->fetch_next_id('users'),         'Get a new user id'              ); # TEST 11
    ok( $db->fetch_next_id('groups'),        'Get a new group id'             ); # TEST 12
    ok( $db->fetch_next_id('objtagmap'),     'Get a new object to tag map id' ); # TEST 13
    ok( $db->fetch_next_id('tags', 'tagid'), 'Get a new tag id'               ); # TEST 14
    ok( $db->fetch_next_id('repository'),    'Get a new repository id.'       ); # TEST 15

    # Create a new object.
    my $newobjid;
                                                                    # TEST 16
    ok( $newobjid = $db->fetch_next_id('object'),
        'Get a new object id'
    );
                                                                    # TEST 17
    my $newobjquery = $db->build_insert_q('object',
        {id => '%d', name => "'%s'", parent => '%d'}
    );
                                                                    # TEST 18
    ok( $newobjquery,
        'Generate object insert query.'
    );
                                                                    # TEST 19
    ok( Modwheel::Object::MW_TREE_TRASH(),
        'MW_TREE_TRASH defined'
    );
                                                                    # TEST 20
    ok( $db->exec_query($newobjquery,
        $newobjid,
        'Test Object!',
        Modwheel::Object::MW_TREE_TRASH),
        'Insert in object table'
    );
   
    # Try to the object we saved previously...
    my $fetch_query = $db->build_select_q('object', 'name', {
        id => '?'},
    );
    my $object_name = $db->fetch_singlevar($fetch_query, $newobjid);
    # ...and check if the name is the same as we saved it as.
                                                                    # TEST 21
    is( $object_name, 'Test Object!',
        'Fetch from object table'
    );

    # Then we try to delete the object
    my $delete_query = $db->build_delete_q('object', {
        id => '?',
    });
                                                                    # TEST 22
    ok( $db->exec_query($delete_query, $newobjid),
        'Delete from object table.'
    );

                                                                    # TEST 23
    ok(! $db->build_delete_q('object'),
        'Bail on build_delete_q without where clause' );
                                                                    # TEST 24
    ok(! $db->build_update_q('object', [qw(id name)]),
        'Bail on build_udpate_q without where clause' );

                                                                    # TEST 25
    is( $db->trim('    trim'), 'trim',  
        'Trim leading spaces with trim()'
    );
                                                                    # TEST 26
    is( $db->trim('mirt    '), 'mirt',
        'Trim spaces at end with trim()'
    );
                                                                    # TEST 27
    is( $db->sqlescape("sql'escape"), "sql''escape",
        "sqlescape() (instance) handles \"'\"?"
    );
                                                                    # TEST 28
    is( $db->sqlescape("sql?escape"), 'sql\?escape',
        "sqlescape() (instance) handles \"?\"?"
    );
                                                                    # TEST 29
    is( Modwheel::DB::Base::sqlescape("sql'escape"), "sql''escape", 
        "sqlescape() (export) handles \"'\"?"
    );
                                                                    # TEST 30
    is( Modwheel::DB::Base::sqlescape("sql?escape"), 'sql\?escape',
        "sqlescape() (export) handles \"?\"?"
    );
                                                                    # TEST 31
    is( $db->quote("'quote'"), "''quote''",
        "quote() handles \"'\"?"
    );

                                                                    # TEST 32
    ok( $db->disconnect,
        'Disconnected from db.'
    );
                                                                    # TEST 33
    ok( !$db->connected,
        'Are we disconnected?'
    );
}

__END__

use strict;
use warnings;
use Test::More tests => 69;
use FindBin qw($Bin);

BEGIN {
    use lib $Bin;
    use_ok('Modwheel::User');
    use_ok('Modwheel::Crypt');
}

use Modwheel::Session;
use Modwheel::HTML::Tagset;
use Test::Modwheel qw( :boolean );
use English qw( -no_match_vars );
use Params::Util ('_HASH', '_ARRAY', '_CODELIKE', '_INSTANCE');
use Readonly;

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
foreach my $method (qw(uid uname)) {
    my $set_method = 'set_' . $method;
    ok( $user->can($method),     "Modwheel::Object->can: $method()"     );
    ok( $user->can($set_method), "Modwheel::Object->can: set_$method()" );
}

my $crypt = Modwheel::Crypt->new({
    require_type => 'One-way',
});

my $new_password = Modwheel::User::mkpasswd(8);
my $hashcookie = $crypt->encipher($new_password);
ok( $crypt->compare($hashcookie, $new_password),
    'hashcookie_compare() with correct key 8 chars'
);
ok(!$crypt->compare($hashcookie, 'B' x 8), 
    'hashcookie_compare() with incorrect key 8 chars'
);
ok(!$crypt->compare($hashcookie, 'B' x 0xffff ), 
    'hashcookie_compare() with incorrect key (overflow)'
);
ok(!$crypt->compare($hashcookie, 'B' x 0), 
    'hashcookie_compare() with incorrect key (nothing)'
);
ok(!$crypt->compare($hashcookie, 'B' x 1), 
    'hashcookie_compare() with incorrect key (less)'
);

my $large_pwd = 'A' x 0xff;
my $large = $crypt->encipher($large_pwd);
ok( $crypt->compare($large, 'A' x 0xff),
    'hashcookie_compare() with correct key 0xff chars'
);
ok(!$crypt->compare($large, 'B' x 0xff), 
    'hashcookie_compare() with incorrect key 8 chars'
);
ok(!$crypt->compare($large, 'B' x 0xffff ), 
    'hashcookie_compare() with incorrect key (overflow)'
);
ok(!$crypt->compare($large, 'B' x 0), 
    'hashcookie_compare() with incorrect key (nothing)'
);
ok(!$crypt->compare($large, 'B' x 1), 
    'hashcookie_compare() with incorrect key (less)'
);

my $small_pwd = 'A' x 1;
my $small = $crypt->encipher($small_pwd);
ok( $crypt->compare($small, 'A' x 1),
    'hashcookie_compare() with correct key 0x1 chars'
);
ok(!$crypt->compare($small, 'B' x 0xff), 
    'hashcookie_compare() with incorrect key 8 chars'
);
ok(!$crypt->compare($small, 'B' x 0xffff ), 
    'hashcookie_compare() with incorrect key (overflow)'
);
ok(!$crypt->compare($small, 'B' x 0), 
    'hashcookie_compare() with incorrect key (nothing)'
);
ok(!$crypt->compare($small, 'B' x 1), 
    'hashcookie_compare() with incorrect key (less)'
);

my $pwd4chr = Modwheel::User::mkpasswd(4);
ok( length $pwd4chr == 4 );
my $pwdlong = Modwheel::User::mkpasswd(0xFEEDF);
ok( length $pwdlong == 0xFEEDF );

# ### Features that require database goes below here.
$THIS_BLOCK_HAS_TESTS = 46;
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

    ok(! $user->uidbyname( ), 'uidbyname bail without name' );
    ok(  $modwheel->catch('user-uidbyname-missing-user') );
    ok(! $user->namebyuid( ), 'namebyuid bail without uid' );
    ok(  $modwheel->catch('user-namebyuid-missing-uid')  );

    my $newusername = 'TESTUSER_DELETE_ASAP';
    ok( Modwheel::User::mkpasswd( ) );
    my $newpassword = Modwheel::User::mkpasswd( 8 );
    # delete stale user
    if (my $staleuid = $user->uidbyname( $newusername) ) {
        $user->delete_user( $staleuid );
    }
    my $newuid = $user->create(
        username => $newusername,
        password => $newpassword
    );
    ok( $newuid, 'create user');
    ok(!$user->create(
        username => $newusername,
        password => $newpassword
    ), 'create bail on existing user' );

    ok(!$user->create( password => $newpassword ),
        'create bail on missing password'
    );

    ok( $user->unametouid($newusername ), 'unametouid' );
    ok(!$user->unametouid('./././zzz#&'), 'unametouid!');
    is( $user->unametouid($newusername), $newuid );
    is( $user->unametouid($newuid),       $newuid );

    ok( $modwheel->catch('user-create-already-exists') );
    
    ok(! $user->create( ), 'create bail without args' );
    ok($modwheel->catch('user-create-missing-field') );
    ok(! $user->create( username => $newusername ) );
    ok($modwheel->catch('user-create-missing-field') );

    ok( _ARRAY($user->list( )), 'list users' );

    ok(!$user->login($newusername, 'The quick brow fox...'),
        'login: fail without correct password.' 
    );
    ok(!$user->login(Modwheel::User::mkpasswd(0xf),
            Modwheel::User::mkpasswd(0xf)),
        'login without existing user'
    );

    ok(!$user->login(undef, '12345678'),
        'login: fail without username but password'
    );    
    ok(!$user->login($newusername),
        'login: fail without password at all'
    );
    ok( $modwheel->catch('user-login-failed') );
    ok( $user->login($newusername, $newpassword),
        'login: ok with correct password'
    );
    ok( $user->login($newusername, $newpassword, '127.0.0.1'),
        'login: ok with correct password and ip'
    );
    ok(!$user->get( ), 'get bail without username/uid' );
    ok( $modwheel->catch('user-get-missing-field') );
    ok(!$user->get('z0#*!^&%*&^%#^&%^*!@#'), 'get bail on nonexisting user' );
    ok(!$user->get(0xfeedface),              'get bail on nonexisting user' );
    ok( $modwheel->catch('user-no-such-user') );
    ok( $user->get($newusername), 'get: by name' );
    my $uh = $user->get( $newuid );
    ok( _HASH($uh), 'get: by uid' );
    is($uh->{last_ip}, '127.0.0.1', 'ip registered correctly');

    ok(!$user->update( ), 'update bail without arguments' );
    ok( $user->update(1, {username => $newusername, password => $newpassword}));
    ok( $user->update(0, {id       => $newuid,      password => $newpassword}));
    ok( $user->update(0, {username => $newusername}) );
    ok( $user->update(1, {id       => $newuid     }) );
    ok( $user->update(1, {id       => $newuid,      password => $newpassword}));

    ok( $user->delete_user( $newuid ), 'delete_user' );
    ok(!$user->delete_user( $newuid ), 'delete_user again should bail not exist' );
    ok(!$user->delete_user(         ), 'delete_user should bail without uid');
    ok(!$user->delete_user('./././.'), 'delete_user not exists' );
    ok(!$user->delete_user(0xfeedfac), 'delete_user not exists' );

    $db->disconnect() if $db->connected;
}

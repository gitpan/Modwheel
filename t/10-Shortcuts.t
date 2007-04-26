#!/usr/bin/perl -w
use strict;
use Data::Dumper;
#use Data::Structure::Util qw(has_circular_ref);

use Test::More tests => 24;

BEGIN {
    use lib '/opt/devel/Modwheel/lib';
    use lib './t';
    use_ok('Modwheel::Repository');
}

use Modwheel::Session;
use Modwheel::HTML::Tagset;
use Test::Modwheel qw( :boolean );
use English qw( -no_match_vars );
use Params::Util ('_HASH', '_ARRAY', '_INSTANCE');
use Readonly;
use Fcntl;

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

my $s = Modwheel::Template::Shortcuts->new( );

ok( $s->parse('The quick brown fox...' ) );

$s = Modwheel::Template::Shortcuts->new({
    blablabla => 'hehehehehe'
});

ok( $s->parse('The quick brown fox...' ) );

$s = Modwheel::Template::Shortcuts->new({
    modwheel => $modwheel,
});

ok( _INSTANCE($s, 'Modwheel::Template::Shortcuts') );

ok(!$s->parse( ) );
is( $s->parse('The quick brown fox...'), 'The quick brown fox...' );
is( $s->parse('[nonExistingShortcut:Blablabla|ThisName]'),
              '[nonExistingShortcut:Blablabla|ThisName]',
              'If none shortcuts found, should return text as-is'
);

is( $s->parse('[http:www.ntnu.no]'),
    '<a href="http://www.ntnu.no">www.ntnu.no</a>',
    'parse: http'
 );
is( $s->parse('[http:www.ntnu.no|NTNU]'),
    '<a href="http://www.ntnu.no">NTNU</a>',
    'parse: http (with name)'
);
is( $s->parse('[https:www.ntnu.no]'),
    '<a href="https://www.ntnu.no">www.ntnu.no</a>',
    'parse: https'
 );
is( $s->parse('[file:1]'), '[file:1]',
    'file: without template'
);
$s = Modwheel::Template::Shortcuts->new({
    modwheel => $modwheel,
    template => $template,
});
is( $s->parse('[https:www.ntnu.no|NTNU]'),
    '<a href="https://www.ntnu.no">NTNU</a>',
    'parse: https (with name)'
);
is( $s->parse('[mail:ASKSH@cpan.org]'),
    '<a href="mailto:ASKSH@cpan.org">ASKSH@cpan.org</a>',
    'parse: mailto'
 );
is( $s->parse('[mail:ASKSH@cpan.org|ASKSH at CPAN . ORG]'),
    '<a href="mailto:ASKSH@cpan.org">ASKSH at CPAN . ORG</a>',
    'parse: mailto (with name)'
);
is( $s->parse('[cpanauthor:ASKSH!!$&*!$&*!$  |ASKSH]'),
    '<a href="http://search.cpan.org/~ASKSH%21%21%24%26%2A%21%24%26%2A%21%24"> |ASKSH</a>',
    'parse: cpanauthor (with name) (with encoding)'
);

is( $s->parse('[test:The quick brown fox|jumps over the lazy frog]'),
'test:<<test>test<quick%20brown%20fox%7Cjumps%20over%20the%20lazy%20frog<quick '.
'brown fox|jumps over the lazy frog>The<The>>'
);

is( $s->parse('[cpanauthor]'), '<a href="http://search.cpan.org/~"></a>');

my $config_keep = $modwheel->config;
$modwheel->set_config({});

$s = Modwheel::Template::Shortcuts->new({
    modwheel => $modwheel,
});

ok( $s->parse('Jumps over the lazy dog.') );
ok( $s->parse('Jumps xver them lafy doc.') );
ok( $s->parse('Jumps ovez tha lazi dog.') );
ok( $s->parse('Jumps over yhe lasy dxg.') );
ok( $s->parse('Jumpz ovah thy lacy log.') );
$modwheel->set_config($config_keep);


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
    my $shortcuts = Modwheel::Template::Shortcuts->new({
        modwheel => $modwheel,
        template => $template,
    });

    # ### XXX: REMEMBER TO INSERT NEW REPOSITORY FILE HERE

    #my $f1= $shortcuts->parse('[file:1]');
    #my $f2 = $shortcuts->parse('[file:1]');

    $db->disconnect() if $db->connected;
}

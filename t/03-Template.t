#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Scalar::Util qw(blessed);

use Test::More tests => 20;
use FindBin qw($Bin);

BEGIN {
    use lib $Bin;
}

use Modwheel::Session;
use Modwheel::HTML::Tagset;
use Test::Modwheel qw( :boolean );
use English qw( -no_match_vars );
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

my $version_file
    = File::Spec->catfile($TEST_PREFIX, 'templates', 'modwheel_version.html');
my $param_file
    = File::Spec->catfile($TEST_PREFIX, 'templates', 'getparam.html');

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
    input       => $version_file,
});

ok( blessed $template );
# check that we cannot create a template object with
# a illegal Template driver name.
my $siteconfig = $modwheel->siteconfig( );
my $old_templatedriver = $siteconfig->{templatedriver};
$siteconfig->{templatedriver} = 'SDAS*#(*)&@(&#)(@##%$ADASD';
ok(! Modwheel::Template->new({
    modwheel => $modwheel,
    db       => $db,
    user     => $user,
    object   => $object,
    repository => $repository,
    input    => $version_file,
}));
$siteconfig->{templatedriver} = $old_templatedriver;

$modwheel->set_debug(0);

my $args = { };

#$template->init({input => './myfile.html'});
#print $template->process($args);
#$template->init({});

my $tk = $template->tkmodwheel;

is( $tk->floor( 2.3),  2,   'floor( 2.3) ==  2?' );                 # TEST 1
is( $tk->floor( 3.8),  3,   'floor( 3.8) ==  3?' );                 # TEST 2
is( $tk->floor(-2.3), -3,   'floor(-2.3) == -3?' );                 # TEST 3
is( $tk->floor(-3.8), -4,   'floor(-3.8) == -4?' );                 # TEST 4
is( $tk->ceil(  2.3),  3,   'ceil(  2.3) ==  3?' );                 # TEST 5
is( $tk->ceil(  3.8),  4,   'ceil(  3.8) ==  4?' );                 # TEST 6
is( $tk->ceil( -2.3), -2,   'ceil( -2.3) == -2?' );                 # TEST 7
is( $tk->ceil( -3.8), -3,   'ceil( -3.8) == -3?' );                 # TEST 8

is( $template->process, $Modwheel::VERSION,
    'Process Template: modwheel_version.html (as argument to new())',
 );
$template->init({ input => $version_file });
is( $template->process, $Modwheel::VERSION,
    'Process Template: modwheel_version.html (as argument to init())',
 );

$template->init({ input => $version_file, parent => 1 });
is( $template->process, $Modwheel::VERSION,
    'Process Template: modwheel_version.html (as argument to init())',
);

my $prev_site = $modwheel->site();
$modwheel->set_site('modwheeltest2');
my $t2 = Modwheel::Template->new({
    modwheel    => $modwheel,
    db          => $db,
    user        => $user,
    object      => $object,
    repository  => $repository,
    input => $version_file,
    parent => 1,
    DontCreateInitialModwheelObject => 1,
});
ok(! blessed $t2->tkmodwheel,
    'new({ DontCreateInitialModwheelObject => 1 })'
);
$modwheel->set_site($prev_site);

$prev_site = $modwheel->site;
$modwheel->set_site('modwheeltest3');
my $tx = Modwheel::Template->new({
    modwheel    => $modwheel,
    db          => $db,
    user        => $user,
    object      => $object,
    repository  => $repository,
    input => $version_file,
    parent => 1,
});
is( $template->process, $Modwheel::VERSION,
    'Process Template: modwheel_version.html (as argument to init())',
);
$modwheel->set_site($prev_site);


$prev_site = $modwheel->site;
my $config = $modwheel->config;
delete $config->{global}{TT};
$modwheel->set_site('modwheeltest3');
$tx = Modwheel::Template->new({
    modwheel    => $modwheel,
    db          => $db,
    user        => $user,
    object      => $object,
    repository  => $repository,
    input => $version_file,
    parent => 1,
});
is( $template->process, $Modwheel::VERSION,
    'Process Template: modwheel_version.html (as argument to init())',
);
$modwheel->set_site($prev_site);


my $mockparam = MockParam->new();
my $t3 = Modwheel::Template->new({
    modwheel    => $modwheel,
    db          => $db,
    user        => $user,
    object      => $object,
    repository  => $repository,
    input => $param_file,
    parent => 1,
    param  => $mockparam,
});
is( $t3->process, 'Cutoff' , 'param object support');




is( $template->uri_escape('&'), '%26', 'uri_escape()');

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
         " database configuration in $TEST_CONFIGFILE to run this test.\n"   ,
            $THIS_BLOCK_HAS_TESTS - 1;
        fail( );
    }

    $db->disconnect() if $db->connected;
}

package MockParam;


sub new {
    return bless { }, shift;
}

sub param {
    my ($self, $param_name) = @_;
    my %params = (
     resonance => 'Cutoff',
    );

    return $params{$param_name};
}

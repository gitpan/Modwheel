#!/usr/bin/perl -w
use strict;
use Data::Dumper;
#use Data::Structure::Util qw(has_circular_ref);

use Test::More tests => 1;
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
Readonly my $TEST_CONFIGFILE => 'config_w_bogus_classes.yml';
Readonly my $TEST_SITE       => 'modwheeltest2';
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
    input       => 'myfile.html',
});

$modwheel->set_debug(0);

pass();

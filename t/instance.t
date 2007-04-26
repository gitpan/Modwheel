#########################

use Test::More tests => 4;
BEGIN {
    use lib '/opt/devel/Modwheel/lib';
    use lib './t';
    use_ok('Modwheel');                                             # TEST 1
    use_ok('Modwheel::Instance');                                    # TEST 2
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

my $modwheel_config = {
    prefix               => $TEST_PREFIX,
    configfile           => $TEST_CONFIGFILE,
    site                 => $TEST_SITE,
    locale               => $TEST_LOCALE,
    logmode              => $TEST_LOGMODE,
};

my $modwheel = Modwheel->new($modwheel_config);

my $tmi = smoke::Test::Modwheel::Instance->new({
    modwheel => $modwheel,
});

$tmi->hello_world();
my $tmi_modwheel = $tmi->modwheel;
isa_ok($tmi_modwheel, 'Modwheel');

$tmi_modwheel->logerror('Everything is just fine.');
like($tmi_modwheel->error(), qr/Everything\s+is\s+just\s+fine/xms);


{
    package smoke::Test::Modwheel::Instance;
    use base qw(Modwheel::Instance);
    sub hello_world {
        my ($self) = @_;
        $modwheel->loginform("Hello world");
    }

1; }

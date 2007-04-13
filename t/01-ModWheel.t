# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Modwheel.t'

BEGIN {
    use lib '/opt/devel/Modwheel/lib';
}

#########################

use Test::More tests => 30;
# 1
BEGIN {
    use_ok('Modwheel');
    use_ok('Modwheel::Object');
};

#########################

use strict;
# 2
my $prefix = './';
ok( my $modwheel = Modwheel->new(
        prefix             => $prefix,
        configfile         => 't/modwheelconfig.yml',
        site               => 'modwheeltest',
        configcachetype => 'memshare',
        locale            => 'en_EN',
        logmode            => 'off',
), 'Create Modwheel root object instance');

is($modwheel->prefix, $prefix);

ok(Modwheel::Object::MW_TREE_ROOT, 'Is constant MW_TREE_ROOT defined?');
ok(Modwheel::Object::MW_TREE_TRASH, 'Is constant MW_TREE_TRASH defined?');
ok(Modwheel::Object::MW_TREE_NOPARENT, 'Is constant MW_TREE_NOPARENT defined?');

ok($Modwheel::VERSION, 'We have \$Modwheel::VERSION');
ok($modwheel->configfile, 'We have a configuration file.');
is($modwheel->site, 'modwheeltest', 'Site is modwheeltest?');
ok(ref $modwheel->siteconfig, 'Siteconfig is set up.');
ok($modwheel->locale, 'We have locale.');
$modwheel->set_locale(undef);
$modwheel->setup_locale_globally;
ok($modwheel->locale, 'Modwheel::setup_locale_globally()');
is($modwheel->debug, 1, 'We set debug to be on in the test config. Is it still on?');
is($modwheel->siteconfig->{uniqueidfortest}, 'SITEID0001');
my $dumped_config = $modwheel->dumpconfig;
print $dumped_config, "\n";
ok($dumped_config, 'Modwheel::dumpconfig');
ok( my $mw2 = Modwheel->new(
        prefix             => $prefix,
        configfile         => 't/modwheelconfig.yml',
        site               => 'modwheeltest2',
        configcachetype => 'memshare',
), 'Create another Modwheel root object instance, without locale. is this ok?');
is($mw2->siteconfig->{uniqueidfortest}, 'SITEID0002');
ok( my $mw3 = Modwheel->new(
        prefix             => $prefix,
        configfile         => 't/modwheelconfig.yml',
        site               => 'modwheeltest',
), 'Create another Modwheel root object instance, without cache type. is this ok?');
ok(ref $mw3->config);
is($mw3->site, 'modwheeltest');
ok(ref $mw3->siteconfig);
ok( my $mw4 = Modwheel->new(
        prefix             => $prefix,
        configfile         => 't/modwheelconfig.yml',
), 'Create another Modwheel root object instance, without site specified.');
is($mw4->site, 'modwheeltest', '   - site should be set to defaultsite in config.');
ok($mw4->siteconfig);
is($mw4->locale, 'en_EN');
undef $mw2;
undef $mw3;
undef $mw4;
ok(!$modwheel->logerror("Test of logerror()."), 'Testing Modwheel::log and friends...');
ok($modwheel->error);
ok(!$modwheel->logwarn("Test of logwarn()."));
ok(!$modwheel->loginform("Test of loginform()."));

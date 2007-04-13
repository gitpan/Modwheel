# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Modwheel.t'

BEGIN {
    use lib '/opt/devel/Modwheel/lib';
}

#########################

use Test::More tests => 3;
BEGIN {
    use_ok('Modwheel');
    use_ok('Modwheel::Session');
};

#########################

use strict;
my $modwheel_config = {
        prefix             => './',
        configfile         => 't/modwheelconfig.yml',
        site               => 'modwheeltest',
        configcachetype => 'memshare',
        locale            => 'en_EN',
};
ok(
    my($modwheel, $db, $user, $object, $template) =
    modwheel_session($modwheel_config, qw(db user object template)
        ), 'Create Modwheel CGI/Terminal session'
);


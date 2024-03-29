use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More;

if ($ENV{TEST_COVERAGE}) {
    plan( skip_all => 'Disabled when testing coverage.' );
}

eval 'use Test::YAML::Meta';
if ($EVAL_ERROR) {
    plan(skip_all => 'Test::YAML::Meta required for testing META.yml');
}

plan tests => 2;

meta_spec_ok(undef, '1.2');



use Test::More;

if ($ENV{TEST_COVERAGE}) {
    plan( skip_all => 'Disabled when testing coverage.' );
}

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
my @POD_dirs = qw(lib/ .pod lib/Manual);
all_pod_files_ok( 'lib/Modwheel/Manual.pod', all_pod_files(@POD_dirs) );

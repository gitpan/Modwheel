use Test::More;

eval 'use Test::YAML::Valid';
plan(skip_all => 'This test requires Test::YAML::Valid.') if $@;

plan(tests => 2);

 yaml_string_ok(YAML::Dump({foo => 'bar'}), 'YAML generates good YAML?');
 yaml_file_ok('./t/modwheelconfig.yml', './t/modwheelconfig.yml is valid YAML');

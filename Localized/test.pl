use strict;
use warnings;
use YAML::Syck;
use utf8;

my $test_file   = shift @ARGV;
   $test_file ||= 'en_EN.yml';

my $testing = YAML::Syck::LoadFile($test_file);

print YAML::Syck::Dump($testing), "\n";

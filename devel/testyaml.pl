#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use YAML;

my $yaml = YAML->new();
my $config = YAML::LoadFile('./config2.yml');
print $config, "\n";
my $dumper = Data::Dumper->new([$config]);
print $dumper->Dump();

print $config->{global}{templatedir}, "\n";


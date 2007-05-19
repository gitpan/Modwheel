use YAML::Syck;

my @data;
my $slurp;
my $in_start = 1;
while (my $line  = <> ) {
    if (!$in_start && $line =~ m/^---\s+$/xms) {
        push @data, YAML::Syck::Load($slurp);
        $slurp = q{};
    }
    $slurp .= $line;
    $in_start = 0;
}

use Data::Dumper;
for my $entry (@data) {
    print Data::Dumper::Dumper($entry), "\n";
}

use DBI;
    my $dbh = DBI->connect('DBI:mysql:database=modwheel;host=localhost',
        'modwheel',
        'torskd0rsk',
        {
            RaiseError => 0,
            PrintError => 1
        }
    );

$dbh->disconnect;

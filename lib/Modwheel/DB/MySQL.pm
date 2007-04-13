package Modwheel::DB::MySQL;
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/DB/MySQL.pm - Modwheel database driver for MySQL.
# (c) 2007 Ask Solem Hoel <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
use Modwheel::DB::Generic;
our @ISA = qw(Modwheel::DB::Generic);

sub create_dsn
{
    my $self = shift;
    my $c = $self->modwheel->siteconfig->{database};

    my $dsn = 'DBI:mysql:';
    
    $dsn .= "database=$c->{name};"    if $c->{name};
    $dsn .= "host=$c->{host};"        if $c->{host};
    $dsn .= "port=$c->{port};"        if $c->{port};
    $dsn .= "mysql_client_found_rows=$c->{mysql_client_found_rows};"
        if $c->{mysql_client_found_rows};
    $dsn .= "mysql_compression=$c->{mysql_compression};"
        if $c->{mysql_compression};
    $dsn .= "mysql_connect_timeout=$c->{mysql_connect_timeout};"
        if $c->{mysql_connect_timeout};
    $dsn .= "mysql_read_default_file=$c->{mysql_read_default_file};"
        if $c->{mysql_read_default_file};
    $dsn .= "mysql_read_default_group=$c->{mysql_read_default_group};"
        if $c->{mysql_read_default_group};
    $dsn .= "mysql_socket=$c->{mysql_socket};"
        if $c->{mysql_socket};
    
    chop $dsn;
    return $dsn;
}

sub maintainance
{
    my $self = shift;

    $self->exec_query('OPTIMIZE TABLE object');
    $self->exec_query('OPTIMIZE TABLE users');
    $self->exec_query('OPTIMIZE TABLE groups');
    $self->exec_query('OPTIMIZE TABLE repository');
    $self->exec_query('OPTIMIZE TABLE objtagmap');
    $self->exec_query('OPTIMIZE TABLE tags');
    
    return 1;
}

1;

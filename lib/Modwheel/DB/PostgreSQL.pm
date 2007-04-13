package Modwheel::DB::MySQL;
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/DB/PostgreSQL.pm - Modwheel database driver for PostgreSQL.
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

    my $dsn   = 'dbi:Pg:';
    if ($c->name}) {
        $dsn .= "dbname=$c->{name};"
    }
    if ($c->{host}) {
        $dsn .= "host=$c->{host};"
    }
    if ($c->{port}) {
        $dsn .= "port=$c->{port};"
    }
    if ($c->{options}) {
        $dsn .= "options=$c->{options};"
    }
    if ($c->{tty}) {
        $dsn .= "tty=$c->{tty};"
    }

    chop $dsn;
    return $dsn;
}

sub create_timestamp
{
    my($self, %time) = @_;

    $time{timezone} ||= 1;
    $time{hour}     ||= 0;
    $time{minute}   ||= 0;
    $time{second}   ||= 0;

    for (keys %time) {
        $time{$_} =~ s/\D*//g;
    }

    my $timestamp = sprintf("%.4d-%.2d-%.2d %.2d:%.2d:%.2d+%.2d",
        $time{year}, $time{month}, $time{day},
        $time{hour}, $time{minute}, $time{second}, $time{timezone}
    );

    return $timestamp;
}

# use sql sequences
sub fetch_next_id
{
    my ($self, $table) = @_;

    return $self->fetch_singlevar("SELECT nextval('${table}_seq')");
}

sub maintainance
{
    my ($self) = @_;

    $self->exec_query("VACUUM");
    $self->exec_query("VACUUM_ANALYZE");

    return 1;
}

1;

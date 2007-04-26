# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/DB/PostgreSQL.pm - Modwheel database driver for PostgreSQL.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# $Id: PostgreSQL.pm,v 1.5 2007/04/25 18:49:15 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/DB/PostgreSQL.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.5 $
# $Date: 2007/04/25 18:49:15 $
#####
package Modwheel::DB::PostgreSQL;
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw( :std );
use base 'Modwheel::DB::Base';
use version; our $VERSION = qv('0.2.1');
{
    
    use Readonly;

    Readonly my @DRIVER_REQUIRES  => qw( DBD::Pg );

    Readonly my @POSTGRES_OPTIONS => qw(
        host
        port
        options
        tty
    );

    sub create_dsn {
        my $self = shift;
        my $c = $self->modwheel->siteconfig->{database};
    
        my $dsn   = 'dbi:Pg:';

        $dsn .= "dbname=$c->{name}";

        foreach my $option (@POSTGRES_OPTIONS) {
            if (defined $c->{$option}) {
                $dsn .= "$option=$c->{$option};";
            }
        }
        chop $dsn;

        return $dsn;
    }

    sub driver_requires {
        return @DRIVER_REQUIRES;
    }

    sub create_timestamp {
        my($self, %time) = @_;
    
        $time{timezone} ||= 1;
        $time{hour}     ||= 0;
        $time{minute}   ||= 0;
        $time{second}   ||= 0;

        foreach my $time_value (keys %time) {
            $time{$time_value} =~ s/\D*//xmsg;
        }

        my $timestamp = sprintf '%.4d-%.2d-%.2d %.2d:%.2d:%.2d+%.2d',
            $time{year}, $time{month}, $time{day},
            $time{hour}, $time{minute}, $time{second}, $time{timezone}
        ;

        return $timestamp;
    }

    # use sql sequences
    sub fetch_next_id {
        my ($self, $table) = @_;
         my $table_seq = $table . '_seq';
         my $new_id = $self->fetch_singlevar(qq{ SELECT nextval('$table_seq') });
        return;
    }

    sub maintainance {
        my ($self) = @_;

        $self->exec_query('VACUUM');
        $self->exec_query('VACUUM_ANALYZE');

        return 1;
    }

}

1;
__END__

# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/DB/MySQL.pm - Modwheel database driver for MySQL.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# $Id: MySQL.pm,v 1.3 2007/04/25 18:49:15 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/DB/MySQL.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.3 $
# $Date: 2007/04/25 18:49:15 $
#####
package Modwheel::DB::MySQL;
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw( :std );
use base 'Modwheel::DB::Base';
use version; our $VERSION = qv('0.2.1');
{

    use Readonly;

    Readonly my @DRIVER_REQUIRES  => qw( DBD::mysql );
    
    Readonly my @MYSQL_OPTIONS    => qw(
        name
        host
        port
        mysql_client_found_rows
        mysql_compression
        mysql_connect_timeout
        mysql_read_default_file
        mysql_read_default_group
        mysql_socket
    );

    Readonly my @OPTIMIZE_TABLES => qw(
        object users groups repository objtagmap tags prototype
    );

    sub create_dsn {
        my $self = shift;
        my $dbc = $self->modwheel->siteconfig->{database};

        my %dbconfig = %{ $dbc };
        my $dsn = 'DBI:mysql:';
    
        $dsn .= "database=$dbconfig{name};";
    
        foreach my $option (@MYSQL_OPTIONS) {
            if ( $dbconfig{$option} ) {
                $dsn .= "$option=$dbconfig{$option};";
            }
        }
        chop $dsn;

        return $dsn;
    }

    sub driver_requires {
        return @DRIVER_REQUIRES;
    }

    sub maintainance {
        my $self = shift;

        foreach my $table (@OPTIMIZE_TABLES) {
            $self->exec_query("OPTIMIZE TABLE $table");
        }
    
        return 1;
    }

};

1;
__END__

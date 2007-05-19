# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/DB/MySQL.pm - Modwheel database driver for MySQL.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# $Id: SQLite.pm,v 1.2 2007/05/18 23:42:38 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/DB/SQLite.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.2 $
# $Date: 2007/05/18 23:42:38 $
#####
package Modwheel::DB::SQLite;
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw( :std );
use base 'Modwheel::DB::Base';
use version; our $VERSION = qv('0.3.1');
{

    use Readonly;

    Readonly my @DRIVER_REQUIRES  => qw( DBD::SQLite );
    
    Readonly my @MYSQL_OPTIONS    => qw(
        name
    );

    sub create_dsn {
        my $self = shift;
        my $dbc = $self->modwheel->siteconfig->{database};

        my %dbconfig = %{ $dbc };
        my $dsn = 'DBI:SQLite:';
    
        $dsn .= "dbname=$dbconfig{name};";
    
        chop $dsn;

        return $dsn;
    }

    sub driver_requires {
        return @DRIVER_REQUIRES;
    }

	    #------------------------------------------------------------------------
		# ->current_timestamp()
		#
		# Fetch the current time as a string.
		# This is the stringified data representation to use in database
		# fields.
		#------------------------------------------------------------------------
		sub current_timestamp {
			my ($self) = @_;
			my $timestamp = $self->fetch_singlevar(q{SELECT DATETIME('NOW')});
			return $timestamp;
		}

};

1;
__END__

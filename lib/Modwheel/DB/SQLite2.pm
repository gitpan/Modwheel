# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/DB/MySQL.pm - Modwheel database driver for MySQL.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# $Id: SQLite2.pm,v 1.3 2007/05/19 13:02:52 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/DB/SQLite2.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.3 $
# $Date: 2007/05/19 13:02:52 $
#####
package Modwheel::DB::SQLite2;
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw( :std );
use base 'Modwheel::DB::Base';
use version; our $VERSION = qv('0.3.3');
{

    use Readonly;

    Readonly my @DRIVER_REQUIRES  => qw( DBD::SQLite2 );
    
    Readonly my @MYSQL_OPTIONS    => qw(
        name
    );

    sub create_dsn {
        my $self = shift;
        my $dbc = $self->modwheel->siteconfig->{database};

        my %dbconfig = %{ $dbc };
        my $dsn = 'DBI:SQLite2:';
    
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

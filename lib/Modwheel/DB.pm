# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/DB.pm - Abstract class for loading database drivers.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####
# $Id: DB.pm,v 1.6 2007/04/28 13:13:03 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/DB.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.6 $
# $Date: 2007/04/28 13:13:03 $
#####
package Modwheel::DB;
use strict;
use warnings;
use Params::Util ('_CLASS');
use version; our $VERSION = qv('0.2.3');
{

    #------------------------------------------------------------------------
    # ->new( \%arguments )
    #
    # This is an abstract factory class for the database backend.
    # The database type is selected from the configuration entry:
    #   Site:
    #     $MySiteName:
    #       database:
    #         type: MySQL
    #
    # In this example the type is MySQL, so the final database object
    # returned by this function will be Modwheel::DB::MySQL.
    #
    # This way we can support different database types for each session.
    #------------------------------------------------------------------------
    sub new {
        my ($class, $arg_ref) = @_;

        my $modwheel = $arg_ref->{modwheel};
        my $backend  = $modwheel->siteconfig->{database}{type};
        $backend ||= 'Modwheel::DB::Base';



        # User can select the full class name or just the name
        # of the database.
        if ($backend !~ m/::/xms) {
            $backend = 'Modwheel::DB::' . $backend;
        }

        # Check the class name. 
        if (!_CLASS($backend)) {
            $modwheel->logerror(
                "DB: $backend is not a valid class name."
            );
            return;
        };

        # we just include the database we need by require(),
        # create a new instance and return it.
        my $file = $backend . q{.pm};
        $file =~ s{ :: }{/}xmsg;
        require $file;    ## no critic
        my $obj = $backend->new($arg_ref);

        return $obj;
    }

};

1;
__END__

=head1 NAME

Modwheel::DB - Abstract factory class for Modwheel database drivers.

=head1 VERSION

v0.2.3

=head1 SYNOPSIS

    my $db = Modwheel::DB->new({ modwheel => $modwheel });
    $db->connect or die "Couldn't connect to database: " . $db->errstr;

    # [ ...do something with the database here...  ]

    $db->disconnect if $db->connected;

=head1 DESCRIPTION

This class is just a wrapper for database driver classes.

=head1 MORE INFORMATION

See L<Modwheel::DB::Base> instead.

=head1 SUBROUTINES/METHODS

=head2 CONSTRUCTOR

=over 4

=item C<Modwheel::DB-E<gt>new({modwheel =E<gt> $modwheel})>

This function creates a DB class based on the current database type.
The database type is selected from the configuration entry

    Site:
        $MySiteName:
            database:
                type: $MyDatabaseType

So if C<$MyDatabaseType> is MySQL, the object returned by C<-E<gt>new( )>
is actually a Modwheel::DB::MySQL object.

This way we can support different database systems for each instance.

=back

=head1 CONFIGURATION AND ENVIRONMENT

See the C<database> directive in L<Modwheel::Manual::Config>

=head1 DEPENDENCIES

It requires the module you have specified as database type in the
configuration.

=head1 INCOMPATIBILITIES

None known at this moment.

=head1 BUGS AND LIMITATIONS
                                                                                                                            
If you have a module that doesn't include '::' in the name, it will
add Modwheel::Template:: to the name.

=head1 SEE ALSO

The README included in the Modwheel distribution.

The Modwheel website: http://www.0x61736b.net/Modwheel/

=head1 DIAGNOSTICS

Be sure that the module specified in the database:type: section of the
coniguration file is installed and is loadable.

If the module name includes the characters '::', it will use the full
module name, if it doesn't it will add Modwheel::DB:: to the front of 
the name. So if the module name is:

MyCompany::OurDB::ModwheelSupport

it will load that module. If the name is PostgreSQL however, it will
load:

Modwheel::DB::PostgreSQL

=head1 AUTHOR

Ask Solem, F<< ask@0x61736b.net >>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 by Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

# Local variables:
# vim: ts=4
~                                        


# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/Template.pm - Abstract class for using Template drivers.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# $Id: Template.pm,v 1.11 2007/05/18 23:42:37 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/Template.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.11 $
# $Date: 2007/05/18 23:42:37 $
#####
package Modwheel::Template;
use strict;
use warnings;
use Params::Util ('_CLASS');
use version; our $VERSION = qv('0.3.1');
{

    #------------------------------------------------------------------------
    # ->new( \%arguments )
    #
    # This is an abstract factory class for representation engines.
    # The representation engine is selected from the configuration entry
    #   Site:
    #     $MySiteName:
    #       templatedriver:
    #
    # Or if no template driver configured for the site, it looks in the
    # global directive:
    #
    #   global:
    #     templatedriver:
    #
    # This way we can support different database types for each instance.
    #------------------------------------------------------------------------
    sub new {
        my ($class, $arg_ref) = @_;

        my $modwheel = $arg_ref->{modwheel};
        my $user     = $arg_ref->{user};
        my $driver   = $modwheel->siteconfig->{templatedriver};

        # User can select the full class name or just the name
        # of the database.
        if ($driver !~ m/ :: /xms) {
            $driver = 'Modwheel::Template::' . $driver;
        }

        # Check the class name.
        if (!_CLASS($driver)) {
            return $modwheel->throw(
                'template-factory-invalid-class', $driver
            );
        }

        # we just include the database we need by require(),
        # create a new instance and return it.
        my $file = $driver . q{.pm};
        $file =~ s{::}{/}xmsg;
       
        if (! $INC{$file}) {
            CORE::require $file;    ## no critic
        }
        my $obj = $driver->new($arg_ref);

        return $obj;
    }

}

1;

__END__

=head1 NAME

Modwheel::Template - Abstract factory class for Modwheel presentation engine
drivers.

=head1 VERSION

v0.3.1

=head1 SYNOPSIS

    my $template   = Modwheel::Template->new({
        modwheel   => $modwheel,
        db         => $db,
        user       => $user,
        repository => $repository,
        object     => $object
    });
    $db->connect or die "Couldn't connect to database: ". $db->errstr;
   
    $template->init(input => 'myfile.html');

    print $template->process();
 
    $db->disconnect if $db->connected;

=head1 DESCRIPTION

Abstract loading of template drivers.

=head1 MORE INFORMATIOAN

If you're using Template Toolkit as representation engine, see:

=over 4

=item * L<Modwheel::Template::TT::Plugin>

   This is the plugin you use in your Template Toolkit templates.

=item * L<Modwheel::Template::TT>

  This is the driver that sets up and loads the Template Toolkit.

=back

=head1 SUBROUTINES/METHODS

=head2 CONSTRUCTOR

=over 4

=item C<Modwheel::Template-E<gt>new({modwheel =E<gt> $modwheel [...]})>

This function creates a Template class based on the current template driver in
the configuration. Either a templatedriver configured for the current site, or a
templatedriver defined in the global configuration directive.

=back


=head1 DIAGNOSTICS

Be sure that the module specified in the templatedriver: section of the
coniguration file is installed and is loadable.

If the module name includes the characters C<::>, it will use the full
module name, if it doesn't it will add Modwheel::Template:: to the front of 
the name. So if the module name is:

    MyCompany::OurRepresentationEngine::ModwheelSupport

it will load that module. If the name is Mason however, it will
load:

    Modwheel::Template::Mason

=head1 CONFIGURATION AND ENVIRONMENT

See the templatedriver section of L<Modwheel::Manual::Config>

=head1 DEPENDENCIES

Requires the module specified in the C<templatedriver:> directive in the
configuration to be installed.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

If you have a module that doesn't include C<::> in the name, it will
add C<Modwheel::Template::> to the name.

=head1 AUTHOR

Ask Solem, F<< ask@0x61736b.net >>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 by Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

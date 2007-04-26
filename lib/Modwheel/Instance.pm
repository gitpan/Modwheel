# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/Instance.pm
# - The base of every Modwheel component, ensures communication between objects.
#   XXX: (This design should change in the near future, maybe Mediator?)
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####
# $Id: Instance.pm,v 1.4 2007/04/24 16:22:24 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/Instance.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.4 $
# $Date: 2007/04/24 16:22:24 $
#####

package Modwheel::Instance;
use strict;
use warnings;
use version; our $VERSION = qv('0.2.1');
use Class::InsideOut::Policy::Modwheel qw(:std);
use Scalar::Util qw(weaken);
use namespace::clean;
{

    public modwheel   => my %modwheel_for,   { is => 'rw' };
    public db         => my %db_for,         { is => 'rw' };
    public user       => my %user_for,       { is => 'rw' };
    public object     => my %object_for,     { is => 'rw' };
    public repository => my %repository_for, { is => 'rw' };
    public template   => my %template_for,   { is => 'rw' };

    sub new {
        my ($class, $arg_ref ) = @_;

        my $self = register($class);

        # Save modwheel object and delete the argument for modwheel.
        $modwheel_for{ident $self} = $arg_ref->{modwheel};
        delete $arg_ref->{modwheel};

    # so if there's still any arguments left, we pass them on to setup_instance.
        if (scalar keys %{ $arg_ref } ) {
            $self->setup_instance($arg_ref);
        }

        return $self;
    }

    sub setup_instance {
        my ($self, $use ) = @_;
        $db_for{ident $self}         = $use->{db};
        $user_for{ident $self}       = $use->{user};
        $object_for{ident $self}     = $use->{object};
        $template_for{ident $self}   = $use->{template};
        $repository_for{ident $self} = $use->{repository};

        return 1;
    }

}

1;

__END__

=head1 NAME

Modwheel::Instance - Base class for modwheel application components.

=head1 VERSION

v0.2.1

=head1 SYNOPSIS

    package Modwheel::MyPackage;
    use strict;
    use warnings;
    use version; our $VERSION = qv('1.0.0');
    use Class::InsideOut::Policy::Modwheel qw( :std );
    use base qw( Modwheel::Instance );
    {
        sub hello_world {
            my ($self) = @_;
            my $modwheel = $self->modwheel;
            $modwheel->loginform("Hello World!");
        } 
    }

    package main;
    use strict;
    use warnings;
    my $pkg = Modwheel::MyPackage->new({
        modwheel   => $modwheel,
        db         => $db,
        user       => $user,
        object     => $object,
        repository => $repository,
        template   => $template,
    });

=head1 DESCRIPTION

This is the base class for Modwheel applications. It ensures communication
between the Modwheel components.

=head1 SUBROUTINES/METHODS

=head2 CONSTRUCTOR


=over 4

=item C<-Egt>new(\%args)>

Inherited method for creating a modwheel instance class.

=back


=head2 ATTRIBUTES

=over 4

=item C<$self-E<gt>modwheel()>

=item C<$self-E<gt>set_modwheel($modwheel)>

The Modwheel object,

=item C<$self-E<gt>user()>

=item C<$self-E<gt>set_user($user)>

Access/set the current object for working with users and authentication.

=item C<$self-E<gt>db()>

=item C<$self-E<gt>set_db($db)>

Access/set the current object for working with databases.

=item C<$self-E<gt>object()>

=item C<$self-E<gt>set_object($object)>

Access/set the current object for working with Modwheel data objects.


=item C<$self-E<gt>template()>

=item C<$self-E<gt>set_template($template)>

Access/set the current object for working with templates.

=item C<$self-E<gt>repository()>

=item C<$self-E<gt>set_repository()>

Access/set the current object for working with file repositories.

=back

=head2 INSTANCE METHODS

=over 4

=item C<$self-E<gt>setup_instance({db => $db, user => $user ...})>

Shortcut for set_db, set_user, set_template, set_object, set_repository.

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Nothing configurable.

=head1 DEPENDENCIES

=over 4

=item L<namespace::clean>

=item L<version>

=item L<Class::InsideOut::Policy::Modwheel>

=back

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

None.

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



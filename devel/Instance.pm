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

  package Modwheel::Instance;
  use Moose::Policy 'Modwheel::Policy';
  use Moose;
  use namespace::clean;

sub new
{
    my ($class, %argv) = @_;
    $class = ref $class || $class;
    my $self = { };
    bless $self, $class;

    # delete also returns the object it deletes,
    # so this will both set the modweel var and delete the hash key.
    $self->set_modwheel( delete $argv{modwheel} );

    # so if there's still any arguments left, we pass them on to setup_instance.
    if (%argv) {
        $self->setup_instance(\%argv);
    }
    
    return $self;
}


sub modwheel
{
    return $_[0]->{_MODWHEEL_};
}



sub set_modwheel
{
    my ($self, $modwheel) = @_;

    if (ref $self) {
        $self->{_MODWHEEL_} = $modwheel
    }

    return;
}


sub user
{
    return $_[0]->{_MODWHEEL_USER_};
}


sub set_user
{
    my ($self, $db) = @_;

    if (ref $db) {
        $self->{_MODWHEEL_USER_} = $db
    }

    return;
}


sub db
{
    return $_[0]->{_MODWHEEL_DB_};
}


sub set_db
{
    my ($self, $db) = @_;

    if (ref $db) {
        $self->{_MODWHEEL_DB_} = $db
    }

    return;
}


sub object
{
    return $_[0]->{_MODWHEEL_OBJECT_};
}


sub set_object
{
    my ($self, $object) = @_;

    if (ref $object) {
        $self->{_MODWHEEL_OBJECT_} = $object
    }

    return;
}


sub template
{
    return $_[0]->{_MODWHEEL_TEMPLATE_};
}



sub set_template
{
    my ($self, $template) = @_;

    if (ref $template) {
        $self->{_MODWHEEL_TEMPLATE_} = $template;
    }

    return;
}


sub repository
{
    return $_[0]->{_MODWHEEL_REPOSITORY_};
}


sub set_repository
{
    my ($self, $repository) = @_;

    if (ref $repository) {
        $self->{_MODWHEEL_REPOSITORY_} = $repository;
    }

    return;
}


sub setup_instance
{
    my ($self, $use) = @_;
    $self->set_db( $use->{db} )                 if $use->{db};
    $self->set_user( $use->{user} )             if $use->{user};
    $self->set_object( $use->{object} )         if $use->{object};
    $self->set_template( $use->{template} )     if $use->{template};
    $self->set_repository( $use->{repository})  if $use->{repository};

    return 1;
}


sub explicit_free
{
    my $self = shift;
    foreach my $instancevar
        (qw(_MODWHEEL_ _MODWHEEL_DB_ _MODWHEEL_USER_ _MODWHEEL_TEMPLATE_ _MODWHEEL_OBJECT))
    {
        undef $self->{$instancevar};
    }

    return 1;
}

1;

__END__
=head1 NAME

Modwheel::Instance - Base class for modwheel application components.

=head1 SYNOPSIS

    package Modwheel::MyPackage;
    use base qw(Modwheel::Instance);

    package main;
    my $pkg = Modwheel::MyPackage->new(
        modwheel   => $modwheel,
        db         => $db,
        user       => $user,
        object     => $object,
        repository => $repository,
        template   => $template,
    );

=head1 CONSTRUCTOR

=over 4

=item C<Modwheel::*E-<gt>new(%argv)>

Inherited method for creating a modwheel instance class.

=cut

=back

=head1 ACCESSORS

=over 4

=item C<$self-E<gt>modwheel()>

Access the Modwheel object,

=cut

=item C<$self-E<gt>set_modwheel($modwheel)>

Set the current Modwheel object to use.

=cut

=item C<$self-E<gt>user()>

Access the current object for working with users and authentication.

=cut

=item C<$self-E<gt>set_user($user)>

Set the current object for working with users and authentication.

=cut

=item C<$self-E<gt>db()>

Access the current object for working with databases.

=cut


=item C<$self-E<gt>set_db($db)>

Set the current object for working with databases.

=cut

=item C<$self-E<gt>object()>

Access the current object for working with Modwheel data objects.

=cut

=item C<$self-E<gt>set_object($object)>

Set the current object for working with Modwheel data objects.

=cut


=item C<$self-E<gt>set_template($template)>

Set the current object for working with templates.

=cut

=item C<$self-E<gt>template()>

Access the current object for working with templates.

=cut


=item C<$self-E<gt>repository()>

Access the current object for working with file repositories.

=cut

=item C<$self-E<gt>set_repository()>

Set the current object for working with file repositories.

=cut

=back

=head1 INSTANCE METHODS

=over 4

=item C<$self-E<gt>setup_instance({modwheel => $modwheel ...})>

Private method used by new().

=cut

=item C<$self-E<gt>explicit_free()>

Explicitly destroy allocated objects.

=cut





=back

=head1 EXPORT

None.

=head1 HISTORY

=over 8

=item 0.01

Initial version.

=back

=head1 SEE ALSO

The README included in the Modwheel distribution.

The Modwheel website: http://www.0x61736b.net/Modwheel/


=head1 AUTHORS

Ask Solem, F<< ask@0x61736b.net >>.

=head1 COPYRIGHT, LICENSE

Copyright (C) 2007 by Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

# Local variables:
# vim: ts=4



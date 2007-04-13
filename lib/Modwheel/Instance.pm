package Modwheel::Instance;
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/Instance.pm
# - The base of every Modwheel component, ensures communication between objects.
#   XXX: (This design should change in the near future, maybe Mediator?)
# (c) 2007 Ask Solem Hoel <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####

=head1 NAME

Modwheel::Instance - Base class for modwheel application components.

=head1 SYNOPSIS

    package Modwheel::MyPackage;
    use Modwheel::Instance;
    our @ISA = qw(Modwheel::Instance);

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

=back

=head1 ACCESSORS

=over 4

=item C<$self-E<gt>modwheel()>

Access the Modwheel object,

=cut
sub modwheel
{
    return $_[0]->{_MODWHEEL_};
}


=item C<$self-E<gt>set_modwheel($modwheel)>

Set the current Modwheel object to use.

=cut
sub set_modwheel
{
    my ($self, $modwheel) = @_;

    if (ref $self) {
        $self->{_MODWHEEL_} = $modwheel
    }
}

=item C<$self-E<gt>user()>

Access the current object for working with users and authentication.

=cut
sub user
{
    return $_[0]->{_MODWHEEL_USER_};
}

=item C<$self-E<gt>set_user($user)>

Set the current object for working with users and authentication.

=cut
sub set_user
{
    my ($self, $db) = @_;

    if (ref $db) {
        $self->{_MODWHEEL_USER_} = $db
    }
}

=item C<$self-E<gt>db()>

Access the current object for working with databases.

=cut
sub db
{
    return $_[0]->{_MODWHEEL_DB_};
}

=item C<$self-E<gt>set_db($db)>

Set the current object for working with databases.

=cut
sub set_db
{
    my ($self, $db) = @_;

    if (ref $db) {
        $self->{_MODWHEEL_DB_} = $db
    }
}

=item C<$self-E<gt>object()>

Access the current object for working with Modwheel data objects.

=cut
sub object
{
    return $_[0]->{_MODWHEEL_OBJECT_};
}

=item C<$self-E<gt>set_object($object)>

Set the current object for working with Modwheel data objects.

=cut
sub set_object
{
    my ($self, $object) = @_;

    if (ref $object) {
        $self->{_MODWHEEL_OBJECT_} = $object
    }
}

=item C<$self-E<gt>template()>

Access the current object for working with templates.

=cut
sub template
{
    return $_[0]->{_MODWHEEL_TEMPLATE_};
}


=item C<$self-E<gt>set_template($template)>

Set the current object for working with templates.

=cut
sub set_template
{
    my ($self, $template) = @_;

    if (ref $template) {
        $self->{_MODWHEEL_TEMPLATE_} = $template;
    }
}

=item C<$self-E<gt>repository()>

Access the current object for working with file repositories.

=cut
sub repository
{
    return $_[0]->{_MODWHEEL_REPOSITORY_};
}

=item C<$self-E<gt>set_repository()>

Set the current object for working with file repositories.

=cut
sub set_repository
{
    my ($self, $repository) = @_;

    if (ref $repository) {
        $self->{_MODWHEEL_REPOSITORY_} = $repository;
    }
}

=back

=head1 INSTANCE METHODS

=over 4

=item C<$self-E<gt>setup_instance({modwheel => $modwheel ...})>

Private method used by new().

=cut
sub setup_instance
{
    my ($self, $use) = @_;
    $self->set_db( $use->{db} )                 if $use->{db};
    $self->set_user( $use->{user} )             if $use->{user};
    $self->set_object( $use->{object} )         if $use->{object};
    $self->set_template( $use->{template} )     if $use->{template};
    $self->set_repository( $use->{repository})  if $use->{repository};
}

=item C<$self-E<gt>explicit_free()>

Explicitly destroy allocated objects.

=cut
sub explicit_free
{
    my $self = shift;
    foreach my $instancevar
        (qw(_MODWHEEL_ _MODWHEEL_DB_ _MODWHEEL_USER_ _MODWHEEL_TEMPLATE_ _MODWHEEL_OBJECT))
    {
        undef $self->{$instancevar};
    }
}

1;

__END__
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

Ask Solem Hoel, F<< ask@0x61736b.net >>.

=head1 COPYRIGHT, LICENSE

Copyright (C) 2007 by Ask Solem Hoel C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

# Local variables:
# vim: ts=4



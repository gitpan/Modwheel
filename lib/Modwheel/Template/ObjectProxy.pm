# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/ObjectProxy.pm - Work with Modwheel-objects in Template Toolkit.
#                           Internal use only!
# 
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# $Id: ObjectProxy.pm,v 1.7 2007/05/18 23:42:42 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/Template/ObjectProxy.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.7 $
# $Date: 2007/05/18 23:42:42 $
#####

package Modwheel::Template::ObjectProxy;
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw( :std );
use version; our $VERSION = qv('0.3.2');
{
    
    use Sub::Install;

    public object => my %object_for, {is => 'ro'};

    sub import {
        # Create aliases to the accessor methods in Modwheel::Object.
        foreach my $method_name (keys %Modwheel::Object::attributes) {
            # Install the subroutine into our class.
            Sub::Install::install_sub({
                into => 'Modwheel::Template::ObjectProxy',
                as   => $method_name,
                code => sub {
                    return $_[0]->object->$method_name;
                }
            });
        }

        return;
    }

    sub new {
        my ($class, $object) = @_;

        my $self = register($class);
        $object_for{ident $self} = $object;

    
        return $self;
    }

    sub setObjectValues {
        my ($self, $arg_ref) = @_;
        my $object = $self->object;
        return if ! $arg_ref;

        while (my($field, $value) = each %{ $arg_ref }) {
            my $set_field = 'set_' . $field;
            # remove leading and trailing whitespace from the value.
            $value =~ s/^ \s+  //xms;
            $value =~ s/  \s+ $//xms;
            if ($object->can($field) && ($value || $value eq '0')) {
                $object->$set_field($value)
            }
        }

        return;
    }

}

1;
__END__
=pod


=head1 NAME

Modwheel::Template::ObjectProxy - Access to Modwheel data objects from templates.

=head1 SYNOPSIS

   [% get_id   = modwheel.getParam(id)          %]
   [% new_name = modwheel.getParam(new_name)    %]
   [% object   = modwheel.fetch( id => get_id ) %] 

   [% IF new_name %]
     [% object.setObjectValues( name => new_name ) %]
     [% ret = modwheel.saveObject( object )        %]
   [% END %]
   
   <strong>Name:</strong> [% object.name %]

    [% IF ret %]
      New name set to [% new_name %]
    [% END %]

=head1 DESCRIPTION

Access Modwheel data objects from templates.
See L<Modwheel::Object> for more information on the attributes available.

=head1 SUBROUTINES/METHODS

=head2 TEMPLATE METHODS

=over 4

=item C<object.setObjectValues(\%values)>

Set object values.

=back

=head2 API METHODS

=over 4

=item C<-E<gt>new( )>

=back

=head2 ATTRIBUTES

Same attributes as Modwheel::Object.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES


=over 4

=item L<Sub::Install>

=item L<version>

=back



=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

=over 4

=item * L<Modwheel::Manual>

The Modwheel manual.

=item * L<Modwheel::Object>

=item * L<http://www.0x61736b.net/Modwheel/>

The Modwheel website.

=back

=head1 VERSION

v0.3.2

=head1 AUTHOR

Ask Solem, L<< ask@0x61736b.net >>.


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 by Ask Solem L<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

# Local variables:
# vim: ts=4

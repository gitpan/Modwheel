# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/Session.pm
# - Easily create a Modwheel session in a perl-program running on
#   a terminal or as a CGI-script.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# $Id: Session.pm,v 1.5 2007/04/28 13:13:03 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/Session.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.5 $
# $Date: 2007/04/28 13:13:03 $
#####

package main;

# Import modules into main:
use Modwheel             ();
use Modwheel::DB         ();
use Modwheel::User       ();
use Modwheel::Object     ();
use Modwheel::Template   ();
use Modwheel::Repository ();

package Modwheel::Session;
use strict;
use warnings;
use Perl6::Export::Attrs;
use version; our $VERSION = qv('0.2.3');

# example:
#   my $modwheel_config = { prefix => '...', configfile => '...' };
#   my ($modwheel, $db, $user, $template, $object)
#       = modwheel_session($modwheel_config, qw(db user template object));
sub modwheel_session : Export(:MANDATORY) {
    my $modwheel_config_ref = shift;
    my %use = map {$_ => 1} @_;
    my ($modwheel, $db, $user, $repository, $template, $object);

    $modwheel = Modwheel->new( $modwheel_config_ref );

    if (!%use || $use{db}) {
        $db = Modwheel::DB->new({
            modwheel    => $modwheel,
        });
    }
    if (!%use || $use{user}) {
        $user = Modwheel::User->new({
            modwheel    => $modwheel,
            db          => $db,
        })
    }
    if (!%use || $use{object}) {
        $object = Modwheel::Object->new({
            modwheel    => $modwheel,
            user        => $user,
            db          => $db,
        });
    }
    if (!%use || $use{repository}) {
        $repository = new Modwheel::Repository({
            modwheel    => $modwheel,
            user        => $user,
            db          => $db,
        });
    }
    if (!%use || $use{template}) {
        $template = new Modwheel::Template({
            modwheel    => $modwheel,
            user        => $user,
            db          => $db,
            object      => $object,
            repository  => $repository,
        });
    }

    return ($modwheel, $user, $db, $object, $repository, $template);
}

1;

__END__

=pod

=head1 NAME

Modwheel::Session - Easily create Modwheel sessions.

=head1 VERSION

v0.2.3

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Modwheel::Session;

    my $modwheel_config = {
        prefix          => '/opt/modwheel',
        configfile      => 'config/modwheelconfig.yml',
        site            => 'mySite',
        logmode         => 'stderr',
        locale          => 'en_EN',
    };
    
    my ($modwheel, $user, $db, $object, $repository, $template) =
        modwheel_session($modwheel_config, qw(db user object template repository));
    $modwheel->set_debug(1);
    $db->connect();

    my $args = { };
    $template->init({
        input => './myfile.html'
    });
    print $template->process($args)

    $db->disconnect() if $db->connected();

=head1 DESCRIPTION

L<Modwheel::Session> is a shortcut for creating L<Modwheel> sessions in a
terminal or L<CGI>-program.

It imports all modules required for the standard L<Modwheel> components into the
main namespace, including a handy function for allocating objects from all of
them in C<the right way(tm)>B<*>.

B<*> I<Not that it's the right way, it's actually a horrid hack. But it's still
handy :-)>

=head1 SUBROUTINES/METHODS

=head2 CLASS METHODS

=over 4

=item C<modwheel_session($modwheel_config, qw(db user object template repository))>

Create a new modwheel session with the given config.
Returns an array with the objects you've asked for.

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

=over 4

=item L<Modwheel>

=item L<Modwheel::DB>

=item L<Modwheel::User>

=item L<Modwheel::Object>

=item L<Modwheel::Repository>

=item L<Modwheel::Template>

=item L<Perl6::Export::Attrs>

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

=item * L<http://www.0x61736b.net/Modwheel/>

The Modwheel website.

=back

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

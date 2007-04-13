# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/Session.pm
# - Easily create a Modwheel session in a perl-program running on
#   a terminal or as a CGI-script.
# (c) 2007 Ask Solem Hoel <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

package main;
use strict; # XXX: forces strict in main,,, 

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
use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(&modwheel_session);

# example:
#   my $modwheel_config = { prefix => '...', configfile => '...' };
#   my ($modwheel, $db, $user, $template, $object)
#       = modwheel_session($modwheel_config, qw(db user template object));
sub modwheel_session
{
    my $modwheel_config = shift;
    my %use = map {$_ => 1} @_;
    my ($modwheel, $db, $user, $repository, $template, $object);

    $modwheel = Modwheel->new( %$modwheel_config );

    if (!%use || $use{db}) {
        $db = Modwheel::DB->new(modwheel => $modwheel);
    }
    if (!%use || $use{user}) {
        $user = Modwheel::User->new(modwheel => $modwheel, db => $db)
    }
    if (!%use || $use{object}) {
        $object = Modwheel::Object->new;
        $object->setup_instance(modwheel => $modwheel, user => $user, db => $db);
    }
    if (!%use || $use{repository}) {
        $repository = new Modwheel::Repository(modwheel=>$modwheel, user=>$user, db=>$db);
    }
    if (!%use || $use{template}) {
        $template = new Modwheel::Template(modwheel=>$modwheel, user=>$user, db=>$db, object=>$object, repository=>$repository);
    }

    return($modwheel, $user, $db, $object, $repository, $template);
}

1

__END__

=head1 NAME

Modwheel::Session - Easily create a Modwheel session.

=head1 SYNOPSIS

    Modwheel::Session is used for easily creating a Modwheel session in a terminal or CGI-program.

    use Modwheel::Session;

    my $modwheel_config = {
        prefix          => '/opt/devel/Modwheel',
        configfile      => 't/modwheelconfig.yml',
        site            => 'modwheeltest',
        configcachetype => 'memshare',
        locale          => 'en_EN',
    };
    
    my ($modwheel, $user, $db, $object, $repository, $template) =
        modwheel_session($modwheel_config, qw(db user object template repository));
    $modwheel->debug(1);
    $db->connect();

    my $args = { };
    $template->init(input => './myfile.html');
    print $template->process($args)

    $db->disconnect() if $db->connected();

=head1 FUNCTIONS

=over 4

=item C<modwheel_session($modwheel_config, qw(db user object template repository))>

Create a new modwheel session with the given config.
Returns an array with the objects you've asked for.

=back

=head1 EXPORT

This module will when used import all Modwheel related classes, and also force strict in main.

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

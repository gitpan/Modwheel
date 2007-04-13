package Modwheel::Template;
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/Template.pm - Abstract class for using Template drivers.
# (c) 2007 Ask Solem Hoel <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

use Modwheel::Instance;
our @ISA = qw(Modwheel::Instance);

# ####### CONSTRUCTOR
# This is an abstract factory class for the database backend.
# The database type is selected from the configuration entry
# <database><type>.
# 
# This way we can support different database types for each session.
sub new
{
    my ($class, %argv) = @_;
    $class = ref $class || $class;

    my $modwheel = $argv{modwheel};
    my $user     = $argv{user};
    my $driver   = $modwheel->siteconfig->{templatedriver};
    unless ($driver) {
        $driver  = $modwheel->config->{templatedriver};
    }

    # User can select the full class name or just the name
    # of the database.
    unless ($driver =~ m/::/) {
        $driver = 'Modwheel::Template::' . $driver;
    }

    # we just include the database we need by require(),
    # create a new instance and return it.
    (my $file = $driver) =~ s#::#/#g;
    require "$file.pm";
    my $obj = $driver->new(%argv);

    return $obj;
}

# ###### ACCESSORS

# ###### INSTANCE METHODS

# ###### CLASS METHODS

1

__END__

=head1 NAME

Modwheel::Template - Abstract factory class for Modwheel template support.

=head1 SYNOPSIS

    my $templatesystem = $modwheel->siteconfig->{templatedriver};
    my $template   = Modwheel::Template->new(
        modwheel   => $modwheel,
        db         => $db,
        user       => $user,
        repository => $repository,
        object     => $object
    );
    $db->connect or die("Couldn't connect to database: ". $db->errstr);
   
    $template->init(input => 'myfile.html');
    print $template->process();
 
    $db->disconnect if $db->connected;

See individual template system support classes for more information. (i.e Template::Plugin::TT)

=head1 CONSTRUCTOR

=over 4

=item C<Modwheel::Template-E<gt>new(modwheel =E<gt> $modwheel [...])>

This function creates a Template class based on the current template driver in
the configuration. Either a templatedriver configured for the current site, or a
templatedriver defined in the global configuration directive.

This way we can support different templating systems.

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

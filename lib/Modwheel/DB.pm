package Modwheel::DB;
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/DB.pm - Abstract class for loading database drivers.
# (c) 2007 Ask Solem Hoel <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####
use Modwheel::Instance;
our @ISA = qw(Modwheel::Instance);

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
    my $backend  = $modwheel->siteconfig->{database}{type};
    $backend     = 'Modwheel::DB::Generic' unless $backend;

    # User can select the full class name or just the name
    # of the database.
    unless ($backend =~ m/::/) {
        $backend = 'Modwheel::DB::' . $backend;
    }

    # we just include the database we need by require(),
    # create a new instance and return it.
    (my $file = $backend) =~ s#::#/#g;
    require "$file.pm";
    my $obj = $backend->new(%argv);

    return $obj;
}


1
__END__

=head1 NAME

Modwheel::DB - Abstract factory class for Modwheel database interfaces.

=head1 SYNOPSIS

    my $db = Modwheel::DB->new(modwheel => $modwheel);
    $db->connect or die("Couldn't connect to database: ". $db->errstr);
    
    $db->disconnect if $db->connected;

=head1 MORE INFORMATION

See L<Modwheel::DB::Generic> for more information.

=head1 CONSTRUCTOR

=over 4

=item C<Modwheel::DB-E<gt>new(modwheel =E<gt> $modwheel)>

This function creates a DB class based on the current database type.
The database type is selected from the configuration entry
<database><type>.

This way we can support different database types for each session.

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
~                                        


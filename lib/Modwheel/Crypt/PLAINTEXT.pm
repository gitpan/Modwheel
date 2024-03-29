# $Id: PLAINTEXT.pm,v 1.1 2007/05/19 18:47:14 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/Crypt/PLAINTEXT.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.1 $
# $Date: 2007/05/19 18:47:14 $
package Modwheel::Crypt::PLAINTEXT;
use strict;
use warnings;
use Carp;
use Readonly;
use Class::InsideOut::Policy::Modwheel qw( :std );
use version; our $VERSION = qv('0.2.3');
use base 'Modwheel::Crypt::Base';
{
    $Modwheel::Crypt::PLAINTEXT::warning_already_printed = 0;

    Readonly my @REQUIRES => qw( );

    my $plaintext_warning = q{
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
MODWHEEL WARNING:
    You are currently not using any encryption, because you are missing required perl-modules
    for encryption to work.

    You can choose between different implementations, depending on which are available for your operating
    system, the amount of security you need, and personal preference.

    You should install one or more of the following modules from CPAN, you need atleast
    one one-way crypt module, and one digest module.

    These are your options:

        One-way crypt modules:

            Crypt::Eksblowfish  - This is a good choice for Unix-like systems.
            http://search.cpan.org/~zefram/Crypt-Eksblowfish-0.001/

            Crypt::UnixCrypt    - Good alternative for Windows users or those without a C compiler.
            http://search.cpan.org/~mvorl/Crypt-UnixCrypt-1.0/

        Digest modules:

            Digest::SHA1 - The NIST SHA-1 message digest algorithm.
            http://search.cpan.org/~gaas/Digest-SHA1-2.11/ 

            Digest::MD5  - The MD5 message digest algorithm.
            http://search.cpan.org/~gaas/Digest-MD5-2.36/



    Thank you for your patience!    
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    };
    sub encipher {
        my ($self, $text) = @_;

        $self->print_warning;
    
        return $text;

    }

    sub decipher {
        my ($self, $text, $key) = @_;

        $self->print_warning;

        return $text;
    }


    sub compare {
        my ($self, $text1, $text2) = @_;

        $self->print_warning;

        return $text1 eq $text2 ? 1 : 0;
    }

    sub requires {
        return @REQUIRES;
    }

    sub print_warning {
        return if $Modwheel::Crypt::PLAINTEXT::warning_already_printed++;
        carp $plaintext_warning;
        return;
    }

}

1;
__END__
=pod


=head1 NAME

Modwheel::Crypt::Plaintext - Fallback module if no other encryption support available.

=head1 VERSION

This document describes Modwheel version v0.3.3

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SUBROUTINES/METHODS


=head2 CONSTRUCTOR


=over 4

=item C<-E<gt>new( )>

=back


=head2 ATTRIBUTES


=head2 INSTANCE METHODS


=head2 CLASS METHODS 


=head2 PRIVATE INSTANCE METHODS


=head2 PRIVATE CLASS METHODS 



=head1 DIAGNOSTICS


=head1 CONFIGURATION AND ENVIRONMENT

This module requires no configuration file or environment variables.

=head1 DEPENDENCIES


=over 4

=item * version

=back



=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-modwheel@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

=over 4

=item * L<Modwheel::Manual>

The Modwheel manual.

=item * L<http://www.0x61736b.net/Modwheel/>

The Modwheel website.

=back

=head1 VERSION

v0.3.3

=head1 AUTHOR

Ask Solem, C<< ask@0x61736b.net >>.


=head1 LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# Local variables:
# vim: ts=4

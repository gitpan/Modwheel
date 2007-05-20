# $Id: Eksblowfish.pm,v 1.1 2007/05/19 18:47:14 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/Crypt/Eksblowfish.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.1 $
# $Date: 2007/05/19 18:47:14 $
package Modwheel::Crypt::Eksblowfish;
use strict;
use warnings;
use Readonly;
use Class::InsideOut::Policy::Modwheel qw( :std );
use version; our $VERSION = qv('0.2.3');
use base 'Modwheel::Crypt::Base';
{

    Readonly my @REQUIRES => qw(
        Crypt::Eksblowfish::Bcrypt
    );

    Readonly my $BLOWFISH_SALT_SIZE     => 0x10;
    Readonly my $BLOWFISH_KEY_SIZE      => 0x48;
    Readonly my $BLOWFISH_BLOCK_SIZE    => 0x08;
    Readonly my $BLOWFISH_OW_SALT_SIZE  => 0x10;
    Readonly my $BLOWFISH_OW_COST       => 0x08;
    Readonly my $BLOWFISH_OW_KEY_NUL    => 0x01;
    Readonly my $BLOWFISH_MAX_PW_LEN    => 0x08;
    Readonly my $BLOWFISH_PADDING_CHAR  => q{~}; # (tilde)

    sub encipher {
        my ($self, $text) = @_;

        # Enforce blowfish password length limitation.
        $text   = substr $text, 0, $BLOWFISH_MAX_PW_LEN;

        # Pad with '~' (tilde) if text is less than the limit.
        while (length $text < $BLOWFISH_MAX_PW_LEN) {
            $text  .= $BLOWFISH_PADDING_CHAR;
        }
        my $salt    = $self->make_salt($BLOWFISH_OW_SALT_SIZE);
        my $hash    = Crypt::Eksblowfish::Bcrypt::bcrypt_hash(
            {
                key_nul => $BLOWFISH_OW_KEY_NUL,
                cost    => $BLOWFISH_OW_COST,
                salt    => $salt,
            },
            $text,
        );

        my $hashb64    = Crypt::Eksblowfish::Bcrypt::en_base64($hash);
        my $hashcookie = $salt . $hashb64;

        return $hashcookie;

    }


    sub compare {
        my ($self, $ciphertext, $text) = @_;

        # Enforce blowfish password length limitation.
        $text   = substr $text, 0, $BLOWFISH_MAX_PW_LEN;

        # Pad with '~' (tilde) if password is less than the limit.
        while (length $text < $BLOWFISH_MAX_PW_LEN) {
            $text .= $BLOWFISH_PADDING_CHAR;
        }

        my $salt    = substr $ciphertext, 0, $BLOWFISH_OW_SALT_SIZE;
        my $hashb64 = substr $ciphertext, $BLOWFISH_OW_SALT_SIZE,
            length $ciphertext;

        my $cmphash = Crypt::Eksblowfish::Bcrypt::bcrypt_hash(
            {
                key_nul => $BLOWFISH_OW_KEY_NUL,
                cost    => $BLOWFISH_OW_COST,
                salt    => $salt,
            },
            $text,
        );

        my $cmphashb64 = Crypt::Eksblowfish::Bcrypt::en_base64($cmphash);

        return $hashb64 eq $cmphashb64 ? 1 : 0;
    }

    sub requires {
        return @REQUIRES;
    }

}

1;
__END__
=pod


=head1 NAME

Modwheel::Crypt::Eksblowfish - Eksblowfish support for Modwheel::Crypt.

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

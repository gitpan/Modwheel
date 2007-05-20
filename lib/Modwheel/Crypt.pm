# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/Crypt.pm - Abstract class for loading a suitable class with cryptographic functions.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####
# $Id: Crypt.pm,v 1.2 2007/05/19 18:53:23 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/Crypt.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.2 $
# $Date: 2007/05/19 18:53:23 $
#####
package Modwheel::Crypt;
use strict;
use warnings;
use Params::Util ('_CLASS');
use version; our $VERSION = qv('0.3.3');
{

    my @ONE_WAY_CRYPT = qw(
        Modwheel::Crypt::Eksblowfish
        Modwheel::Crypt::UnixCrypt
        Modwheel::Crypt::PLAINTEXT
    );

    my @DIGEST        = qw(
        Modwheel::Crypt::SHA1
        Modwheel::Crypt::PLAINTEXT
    );

    my %TYPE          = (
        'One-way'       => [ @ONE_WAY_CRYPT ],
        'Digest'        => [ @DIGEST        ],
    );

    # Cache classes that fails to require.
    my %probe_fail_cache = ( );

    #------------------------------------------------------------------------
    # ->new( \%arguments )
    #
    #------------------------------------------------------------------------
    sub new {
        my ($class, $arg_ref) = @_;
        $arg_ref ||= { };

        my $type   = $arg_ref->{require_type};
           $type ||= 'One-way';

        my $select_ref = $arg_ref->{crypt}  ? [ $arg_ref->{crypt} ]
                                            : $TYPE{$type};
        
        CLASS:
        for my $crypt (@{ $select_ref }) {

            next CLASS if exists $probe_fail_cache{$crypt};

            # User can select the full class name or just the name
            # short-name. (last component of the class).
            if ($crypt !~ m/::/xms) {
                $crypt = 'Modwheel::Crypt::' . $crypt;
            }

            # Check the class name. 
            next CLASS if ! _CLASS($crypt);

            # we just include the database we need by require(),
            # create a new instance and return it.
            my $file = $crypt . q{.pm};
            $file =~ s{ :: }{/}xmsg;

            # Check if the module is already loaded. (about 4 x faster).
            if (! $INC{$file}) {
                CORE::require $file;    ## no critic
            }

            my $obj = $crypt->new($arg_ref);
            if (not $obj) {
                $probe_fail_cache{$crypt} = 1;
                next CLASS;
            }

            return $obj;
        }

        return;
    }
};

=for Now_playing
    
    Req - Runout Scratches - Car Paint Scheme (Warp records)

=cut

1;




__END__

=head1 NAME

Modwheel::Crypt - Abstract factory class for Modwheel cryptography support.

=head1 VERSION

v0.3.3

=head1 SYNOPSIS

    my $text  = 'The quick brown fox jumps over the lazy dog.';
    my $crypt = Modwheel::Crypt->new({ require_type => 'One-way' })
    my $hashcookie = $crypt->encipher($text);


    my $other_text = 'The xuick brown foz rumps ov3r thy lazy fog.';

    if (! $crypt->compare($hashcookie, $other_text)) {
        print {*STDERR} "The other text is different.\n";
    }

=head1 DESCRIPTION

This class is a factory creating a suitable cryptography class.

=head1 MORE INFORMATION

See L<Modwheel::Crypt::Eksblowfish>

=head1 SUBROUTINES/METHODS

=head2 CONSTRUCTOR

=head3 C<Modwheel::Crypt-E<gt>new({crypt =E<gt> 'Eksblowfish'}, require_type => 'One-way')>

This function creates a class able to provide cryptographic functions.
Arguments can be of the following:

    required_type   - The crypt-module to load must be of the given type,
                      where type can be:

            One-way     - One way crypt/Hashcookie/Unix-crypt like.
            Digest      - Digest/Fingerprinting/Hashing like.

    crypt           - Explicitly specify crypto-support module to use.
            Example:

            crypt => 'Eksblowfish',
            crypt => 'MyCrypt::ModwheelSupport',


=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

It tries to select the most suitable module for the cryptographic need you have,
the following are the requirements of the different classes it can create:

    Eksblowfish     -  Requires Crypt::Eksblowfish >= 0.001

=head1 INCOMPATIBILITIES

None known at this moment.

=head1 BUGS AND LIMITATIONS
                                                                                                                            
If you have a module that doesn't include '::' in the name, it will
add Modwheel::Crypt:: to the name.

=head1 SEE ALSO

The README included in the Modwheel distribution.

The Modwheel website: http://www.0x61736b.net/Modwheel/

=head1 DIAGNOSTICS

If the module name includes the characters '::', it will use the full
module name, if it doesn't it will add Modwheel::Crypt:: to the front of 
the name. So if the module name is:

MyCompany::OurCrypt::ModwheelSupport

it will load that module. If the name is Eksblowfish however, it will
load:

Modwheel::Crypt::Eksblowfish

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
~                                        


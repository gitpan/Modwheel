#!/usr/bin/perl -w
use strict;
use lib qw(/opt/devel/Modwheel/lib);
use Crypt::Eksblowfish;
use Crypt::Eksblowfish::Bcrypt;
use Modwheel::User ();

sub BLOWFISH_SALT_SIZE    { 0x10 };
sub BLOWFISH_KEY_SIZE     { 0x48 };
sub BLOWFISH_BLOCK_SIZE   { 0x08 };
sub BLOWFISH_OW_SALT_SIZE { 0x10 };
sub BLOWFISH_OW_COST      { 0x08 };
sub BLOWFISH_OW_KEY_NUL   { 0x01 };


my $hashcookie = hashcookie_encipher('fiskfiskfisk');
hashcookie_compare($hashcookie, 'fiskfiskfisk');

sub hashcookie_encipher
{
    my $password = shift;
    $password  = substr($password, 0, 8);
    $password .= '~' until length $password == 8;
    my $salt = Modwheel::User::mkpasswd(BLOWFISH_OW_SALT_SIZE);
    my $hash = Crypt::Eksblowfish::Bcrypt::bcrypt_hash({
        key_nul    => BLOWFISH_OW_KEY_NUL,
        cost    => BLOWFISH_OW_COST,
        salt    => $salt
    }, $password);

    print "1. SALT: $salt\n";

    my $hashb64 = Crypt::Eksblowfish::Bcrypt::en_base64($hash);
    print "1. HASH: $hashb64\n";
    my $hashcookie = $salt. $hashb64;
    return $hashcookie;
}

sub hashcookie_compare
{
    my($hashcookie, $password) = @_;
    $password   = substr($password, 0, 8);
    $password  .= '~' until length $password == 8;
    
    my $salt    = substr($hashcookie, 0, BLOWFISH_OW_SALT_SIZE);
    my $hashb64 = substr($hashcookie, BLOWFISH_OW_SALT_SIZE, length $hashcookie);

    print "2. SALT: $salt\n";
    print "2. HASH: $hashb64\n";

    my $cmphash = Crypt::Eksblowfish::Bcrypt::bcrypt_hash({
        key_nul    => BLOWFISH_OW_KEY_NUL,
        cost    => BLOWFISH_OW_COST,
        salt    => $salt
    }, $password);

    my $cmphashb64 = Crypt::Eksblowfish::Bcrypt::en_base64($cmphash);

    if($hashb64 eq $cmphashb64) {
        print "YES\n";
    } else {
        print "NO\n";
    }

}

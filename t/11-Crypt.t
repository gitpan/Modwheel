#!/usr/bin/perl
use strict;
use warnings;
use Modwheel::Crypt;
use Test::More;
use English qw( -no_match_vars );

BEGIN {
    use FindBin qw($Bin);
    use lib "$Bin/lib"; 
}

our $THIS_TEST_HAS_TESTS = 17;
our $THIS_BLOCK_HAS_TESTS;

plan(tests => $THIS_TEST_HAS_TESTS);


my $text  = 'The quick brown fox jumps over the lazy dog.';
my $other_text = 'The xuick brown foz rumps ov3r thy lazy fog.';

# ## require_type => One-way
my $crypt = Modwheel::Crypt->new({ require_type => 'One-way'});
ok( $crypt, 'New Modwheel::Crypt object require_type One-Way' );
my $hashcookie = $crypt->encipher($text);
ok( $crypt->compare($hashcookie, $text), 'compare equal');
ok(!$crypt->compare($hashcookie, $other_text), 'compare not equal');

# ## require_type => Digest
$crypt = Modwheel::Crypt->new({ require_type => 'Digest'});
ok( $crypt, 'New Modwheel::Crypt object require_type Digest' );
$hashcookie = $crypt->encipher($text);
ok( $crypt->compare($hashcookie, $text), 'compare equal');
ok(!$crypt->compare($hashcookie, $other_text), 'compare not equal');

$THIS_BLOCK_HAS_TESTS = 3;
SKIP: {
    $crypt = Modwheel::Crypt->new({ crypt => 'Eksblowfish' });
    if (! $crypt) { 
        skip('These tests requires Crypt::Eksblowfish', $THIS_BLOCK_HAS_TESTS);
    }

    $crypt = Modwheel::Crypt->new({ crypt => 'Modwheel::Crypt::Eksblowfish' });
    ok( $crypt, 'Eksblowfish' );
    my $hashcookie = $crypt->encipher($text);
    ok( $crypt->compare($hashcookie, $text), 'compare equal');
    ok(!$crypt->compare($hashcookie, $other_text), 'compare not equal');
}

$THIS_BLOCK_HAS_TESTS = 3;
SKIP: {
    $crypt = Modwheel::Crypt->new({ crypt => 'UnixCrypt' });
    if (! $crypt) { 
        skip('These tests requires Crypt::UnixCrypt', $THIS_BLOCK_HAS_TESTS);
    }

    $crypt = Modwheel::Crypt->new({ crypt => 'Modwheel::Crypt::UnixCrypt' });
    ok( $crypt, 'UnixCrypt' );
    my $hashcookie = $crypt->encipher($text);
    ok( $crypt->compare($hashcookie, $text), 'compare equal');
    ok(!$crypt->compare($hashcookie, $other_text), 'compare not equal');
}

$THIS_BLOCK_HAS_TESTS = 3;
SKIP: {
    $crypt = Modwheel::Crypt->new({ crypt => 'SHA1' });
    if (! $crypt) { 
        skip('These tests requires Digest::SHA1', $THIS_BLOCK_HAS_TESTS);
    }

    $crypt = Modwheel::Crypt->new({ crypt => 'Modwheel::Crypt::SHA1' });
    ok( $crypt, 'SHA1' );
    my $hashcookie = $crypt->encipher($text);
    ok( $crypt->compare($hashcookie, $text), 'compare equal');
    ok(!$crypt->compare($hashcookie, $other_text), 'compare not equal');
}

ok(! Modwheel::Crypt->new({ crypt => 'I!DNvalidCL$&&Z////Name' }),
    'bail on invalid class name'
);

eval "Modwheel::Crypt->new({ crypt => 'xyz::zyx::Non::Existing::Crypt' })",
ok($EVAL_ERROR, 'bail on non existing crypt-module');


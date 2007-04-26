#!/usr/bin/perl
use strict;
use warnings;
use Scalar::Util qw(blessed);
use Params::Util ('_HASH', '_ARRAY');
use English qw( -no_match_vars);

use Test::More;

eval "use HTML::TokeParser";
if ($EVAL_ERROR) {
    plan( skip_all => 'These tests requires HTML::TokeParser' );
}

plan tests => 348;

use_ok('Modwheel::HTML::Tagset');

my @TEST_ALLOWED_TAGS = qw(
     BOLD B ITALIC EMPH I UNDERLINE U LINK A
        BR P SMALL BIG INPUT ABBR ACRONYM ADDRESS
        BLOCKQUOTE BUTTON CENTER CITE CODE DD DL DT
        EM DIV FONT H1 H2 H3 H4 H5 H6 HR IMG INS
        LABEL FIELDSET LEGEND LI MAP OBJECT OL
);

my %TEST_REWRITE = (
    a => 'b',
    b => 'd',
    d => 'e',
    e => 'f',
    g => 'h',
    h => 'i',
    i => 'j',
    j => 'k',
);

my @TEST_ADDITIONAL_TAGS = qw(
    HTML BODY HEAD
);


# ## Test default behaviour.
my $tagset = Modwheel::HTML::Tagset->new();
ok( blessed $tagset, 'New tagset without arguments' );
my $allowed = $tagset->_tags_allowed;
ok( _HASH($allowed), '  using default allow tags?'  );
my %saved_default_allowed = %{ $allowed };
my $rewrite = $tagset->_tags_rewrite;
ok( _HASH($rewrite), '  using default rewrite table?' );
my %saved_default_rewrite = %{ $rewrite };


# ## Test user specified allowed table.
$tagset = Modwheel::HTML::Tagset->new({
    allow => \@TEST_ALLOWED_TAGS,
});
ok( blessed $tagset, 'New tagset with user specified list of tags' );
$allowed = $tagset->_tags_allowed;
ok( _HASH($allowed), '  tagset registered? ');
for my $allowed_tag (@TEST_ALLOWED_TAGS) {
    ok ( $allowed->{lc $allowed_tag} , "     registered tag $allowed_tag" );
}

# ## Test user specified rewrite table.
$tagset = Modwheel::HTML::Tagset->new({
    rewrite => \%TEST_REWRITE,
});
ok( blessed $tagset, 'New tagset with user specified rewrite table');
$allowed = $tagset->_tags_allowed;
ok( _HASH($allowed), '  tagset registered? ');
for my $allowed_tag (@TEST_ALLOWED_TAGS) {
    ok ( $allowed->{lc $allowed_tag} , "     registered tag $allowed_tag" );
}
$rewrite = $tagset->_tags_rewrite;
ok( _HASH($rewrite), '  rewrite table registered?' );
while (my ($from_tag, $to_tag) = each %TEST_REWRITE) {
    is( $rewrite->{$from_tag}, $to_tag,
        "  Is $rewrite->{$from_tag} == $to_tag? "
    );
}


# ## Test user specified additional tags.
$tagset = Modwheel::HTML::Tagset->new({
    add_allow => \@TEST_ALLOWED_TAGS,
});
ok( blessed $tagset, 'New tagset with additional tags' );
$allowed = $tagset->_tags_allowed;
ok( _HASH($allowed), '  tagset registered? ');
for my $allowed_tag (@TEST_ALLOWED_TAGS) {
    ok ( $allowed->{lc $allowed_tag} , "     registered tag $allowed_tag" );
}
for my $allowed_tag (%saved_default_allowed) {
    ok ( $allowed->{lc $allowed_tag} , "     registered tag $allowed_tag" );
}

# ## Test user specified additional rewrites
$tagset = Modwheel::HTML::Tagset->new({
    add_rewrite => \%TEST_REWRITE,
});
ok( blessed $tagset, 'New tagset with user specified rewrite table');
$allowed = $tagset->_tags_allowed;
ok( _HASH($allowed), '  tagset registered? ');
for my $allowed_tag (@TEST_ALLOWED_TAGS) {
    ok ( $allowed->{lc $allowed_tag} , "     registered tag $allowed_tag" );
}
$rewrite = $tagset->_tags_rewrite;
ok( _HASH($rewrite), '  rewrite table registered?' );
while (my ($from_tag, $to_tag) = each %TEST_REWRITE) {
    is( $rewrite->{$from_tag}, $to_tag,
        "  Is $rewrite->{$from_tag} == $to_tag? "
    );
}
while (my ($from_tag, $to_tag) = each %saved_default_rewrite) {
    is( $rewrite->{$from_tag}, $to_tag,
        "  Is $rewrite->{$from_tag} == $to_tag? "
    );
}

# ### Test striptags.

my $html_string = '<HTML><HEAD><TITLE>TAGSET</TITLE></HEAD></HTML>';
my $strip_str = $tagset->striptags($html_string);
is($strip_str, 'TAGSET',  'striptags()');
$html_string = '<html><head><title>tagset</title></head></html>';
$strip_str = $tagset->striptags($html_string);
is($strip_str, 'tagset',  'striptags()');
$html_string = '<title></head>tagset</title></head></html>';
$strip_str = $tagset->striptags($html_string);
is($strip_str, '</head>tagset',  'striptags()');
# pass reference.
$strip_str = $tagset->striptags(\$html_string);
is($strip_str, '</head>tagset',  'striptags()');

# ### Test parse
$tagset = Modwheel::HTML::Tagset->new({
    add_rewrite => {
        foo         => 'bar',
        cross       => 'quantum',
        j           => 'juxtaposition'
    }
});

$html_string = '<body><h1>hei hei</h1></body>';
my $parsed = $tagset->parse($html_string);
is($parsed, '<h1>hei hei</h1>', 'parse()');
# Pass reference.
$parsed = $tagset->parse(\$html_string);
is($parsed, '<h1>hei hei</h1>', 'parse()');

$html_string = '<form><input type="submit" /><b>Foo was hanging around Bar when suddently...</b></form>';
$parsed = $tagset->parse($html_string, 1);
is($parsed, '<b>Foo was hanging around Bar when suddently...</b>', 'parse(, NO_FORM)');

$html_string = '<foo>iControl, yeah Right!#&*!@*&@!</foo>';
$parsed = $tagset->parse($html_string);
is( $parsed, '<bar>iControl, yeah Right!#&*!@*&@!</bar>' );

$html_string =
'<cross>Here<cross>There</cross><cross>Everywhere?</cross></cross>';
$parsed = $tagset->parse($html_string);
is( $parsed,
'<quantum>Here<quantum>There</quantum><quantum>Everywhere?</quantum></quantum>');

$html_string = '<j<j><j>><j><j>&gt;>><j>,a<j><<J>><J>><a><j>';
$parsed = $tagset->parse($html_string);
is( $parsed,
'<juxtaposition>><juxtaposition><juxtaposition>&gt;>><juxtaposition>,a<juxtaposition><<juxtaposition>><juxtaposition>><a><juxtaposition>'
);

# No tags...
$html_string = 'The quick brown fox jumps over the lazy dog';
$parsed = $tagset->parse($html_string);
is( $parsed, 'The quick brown fox jumps over the lazy dog' );

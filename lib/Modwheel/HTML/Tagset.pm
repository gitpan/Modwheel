package Modwheel::HTML::Tagset;
use strict;
use warnings;
use HTML::TokeParser ();
# ---------------------------------------------------------------------#
=head1 Modwheel-HTML-Tagset

Allow basic tags in strings.

=head1 SYNOPSIS

        use Modwheel::HTML::Tagset;

        my $HTML = <>;
        my $tagset = new Modwheel::HTML::Tagset;
        my $strippedString = $tagset->parse($HTML);
        print $strippedString, "\n";

=head1 DESCRIPTION

The tags that are not supported are removed.
Usually the illegal tags are those that can destroy
the rendering of the page, like tables etc.

You can pass references instead of scalars
for better performance.

=cut
# ---------------------------------------------------------------------#

# ### The tags we allow.
my %allowed = map {lc($_)=>1}
  qw/
        BOLD B ITALIC EMPH I UNDERLINE U LINK A
        BR P SMALL BIG INPUT ABBR ACRONYM ADDRESS
        BLOCKQUOTE BUTTON CENTER CITE CODE DD DL DT
        EM DIV FONT H1 H2 H3 H4 H5 H6 HR IMG INS
        LABEL FIELDSET LEGEND LI MAP OBJECT OL
        OPTION SELECT OPTGROUP PARAM PRE Q SAMP
        SPAN STRIKE STRONG SUB SUP TEXTAREA
        VAR UL TT FORM SCRIPT
    /    
;

# ### Allow some abbreviations for tags.
my %rewrite = (
    bold        => 'b',
    italic      => 'i',
    emph        => 'i',
    underline   => 'u',
    'link'      => 'a',
);


# ###
# For accessing the different array elements
# in HTML::TokeParsers output.
my $TYPE        = 0;
my $TAG         = 1;
my $S_ATTR      = 2;
my $S_ATTR_ORD  = 3;
my $S_SRC       = 4;
my $D_TEXT      = 1;
my $E_SRC       = 2;


sub new
{
    my $class = shift;
    $class    = ref $class || $class;
    my $self  = bless { }, $class;
    return $self;
}

# ### string striptags (string)
# Remove HTML tags in a string.
#
sub striptags
{
    my ($self, $str) = @_;

    my $sp = HTML::TokeParser->new(ref $str ? $str : \$str);
    my $filtered;
    while (my $token = $sp->get_token) {
        if($token->[$TYPE] eq 'T') {
            $filtered .= $token->[$D_TEXT];
        }
    }

    return $filtered;
}

# ### string parse (string)
# Parse and filter a string.
#
sub parse
{
    my ($self, $str, $no_forms) = @_;

    my %allow = %allowed;
    if ($no_forms) {
        foreach (qw(form input button object param textarea select script)) {
            delete $allow{$_};
        }
    }
    
    my $sp = HTML::TokeParser->new(ref $str ? $str : \$str);
    my $filtered;
    my %state;
    while (my $token = $sp->get_token) {
        if ($token->[$TYPE] eq 'S' || $token->[$TYPE] eq 'E') {
            my $tag = lc $token->[$TAG];
            my $src = $token->[$TYPE] eq 'S'
                ? $token->[$S_SRC]
                : $token->[$E_SRC]
            ;
            next if $state{IGNORE} = ($allow{$tag} ? 0 : 1);
    
            if($rewrite{$tag}) {
                my $map = join(" ",
                    map {"$_=\"$token->[$S_ATTR]->{$_}\""}
                        keys %{$token->[$S_ATTR]}
                ) if $token->[$TYPE] eq 'S';
    
                $tag  = $rewrite{$tag};
                $src  = $token->[$TYPE] eq 'S' ? '<' : '</';
                $src .= $tag;
                $src .= " ". $map if $map;
                $src .= '>';
            }
    
            $filtered .= $src;
        }
        elsif ($token->[$TYPE] eq 'T') {
            $token->[$D_TEXT] =~ s/[ \t]+/ /;
            $filtered .= $token->[$D_TEXT]
        }
    }

    return $filtered;
}

1
__END__

=head1 CONSTRUCTOR

=over 4

=item % C<Modwheel::HTML::TagSet>$tagset =  B<new()>

Create a new Modwheel::HTML::TagSet object.

=back

=head1 INSTANCE METHODS


=over 4

=item string B<striptags> (string)

Remove HTML tags in a string.

=item string B<parse> (string)

Parse and filter a string.

=back

=head1 HISTORY

0.2 (29.03.2007)  Changed to object-oriented interface.

0.1 (13.06.1998) Initial version.

=head1 AUTHORS

B<Ask Solem Hoel> L<ask@0x61736b.net>

=head1 COPYRIGHT

Copyright (C) 1998-2007 Ask Solem Hoel. All rights reserved.

=cut

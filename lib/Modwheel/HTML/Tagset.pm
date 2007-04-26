# $Id: Tagset.pm,v 1.4 2007/04/23 19:28:48 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/HTML/Tagset.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.4 $
# $Date: 2007/04/23 19:28:48 $
#####
package Modwheel::HTML::Tagset;
use strict;
use warnings;
use version;
use Readonly;
use Params::Util ('_HASH', '_ARRAY');
use HTML::TokeParser ();

our $VERSION = qv('1.0.0');

# ### The tags we allow.
Readonly my @DEFAULT_ALLOWED => map {lc($_)=>1}
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
Readonly my %DEFAULT_REWRITE => (
    bold        => 'b',
    italic      => 'i',
    emph        => 'i',
    underline   => 'u',
    'link'      => 'a',
);


# These tags are deleted if the $no_forms option of parse() is set
Readonly my @FORM_TAGS => qw(
    form input button object param textarea select script
);

# ###
# For accessing the different array elements
# in HTML::TokeParsers output.
Readonly my $TYPE        => 0;
Readonly my $TAG         => 1;
Readonly my $S_ATTR      => 2;
Readonly my $S_ATTR_ORD  => 3;
Readonly my $S_SRC       => 4;
Readonly my $D_TEXT      => 1;
Readonly my $E_SRC       => 2;


sub new {
    my ($class, $options_ref) = @_;
    my $self  = bless { }, $class;

    $self->_init();
    $self->_init_args($options_ref);

    return $self;
}

sub _init {
    my ($self) = @_;
    # Set up default allowed tags and rewrite aliases.
    my %allowed_defaults_copy = map { lc $_ => 1 } @DEFAULT_ALLOWED;
    my %rewrite_defaults_copy = %DEFAULT_REWRITE;
    $self->{_allowed} = \%allowed_defaults_copy;
    $self->{_rewrite} = \%rewrite_defaults_copy;
    return;
}

sub _init_args {
    my ($self, $options_ref) = @_;
    return if not _HASH($options_ref);
    my $allowed     = $options_ref->{allow};
    my $add_allow   = $options_ref->{add_allow};
    my $rewrite     = $options_ref->{rewrite};
    my $add_rewrite = $options_ref->{add_rewrite};

    # allow => [ ...]
    # User wants to replace all allowed tags with new array. 
    if (_ARRAY($allowed)) {
        my %to_if_map = map { lc $_ => 1 } @{ $allowed };
        $self->_set_tags_allowed(\%to_if_map);
    }

    # add_allow => [ ... ]
    # User wants to add additional allowed tags
    if (_ARRAY($add_allow)) {
        for my $new_allowed (@{ $add_allow }) {
            $self->_push_tags_allowed($new_allowed);
        }
    }

    # rewrite => { a => 'b' }
    # User wants to replace all aliases with new hash.
    if (_HASH($rewrite))    {
        $self->_set_tags_rewrite( $rewrite );
    }

    # add_rewrite => { c => 'd' }
    # User wants to add additional aliases.
    if (_HASH($add_rewrite)) {
        while (my ($from_tag, $to_tag) = each %{ $add_rewrite }) {
            $self->_add_tags_rewrite($from_tag, $to_tag);
        }
    }
             
    return;
}

sub _tags_allowed {
    my ($self) = @_;
    return $self->{_allowed};
}

sub _set_tags_allowed {
    my ($self, $allowed_ref) = @_;
    $self->{_allowed} = $allowed_ref;
    return;
}

sub _push_tags_allowed {
    my ($self, $tag) = @_;
    $self->{_allowed}->{$tag} = 1;
    return;
}

sub _tags_rewrite {
    my ($self) = @_;
    return $self->{_rewrite};
}

sub _set_tags_rewrite {
    my ($self, $rewrite_ref) = @_;
    $self->{_rewrite} = $rewrite_ref;
    return;
}

sub _add_tags_rewrite {
    my ($self, $from_tag, $to_tag) = @_;
    $self->{_rewrite}->{$from_tag} = $to_tag;
    return;
}


# ### string striptags (string)
# Remove HTML tags in a string.
#
sub striptags {
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
sub parse {
    my ($self, $str, $no_forms) = @_;

    # Get the list of tags we want.
    my $allowed = $self->_tags_allowed;
    my %allow = %{ $allowed };

    # Get the list of tags we want to rewrite. (aliases)
    my $rewrite = $self->_tags_rewrite;

    # If the $no_forms option is set, we delete the tags in %allowed
    # that breaks HTML forms.    
    if ($no_forms) {
        foreach my $form_tags (@FORM_TAGS) {
            delete $allow{$form_tags};
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
            
            $state{IGNORE} = ($allow{$tag} || $rewrite->{$tag}) ? 0
                                                                : 1
            ;
            next if $state{IGNORE};
    
            if($rewrite->{$tag}) {
                my $map = q{};
                if ($token->[$TYPE] eq 'S') {
                    my @mapped = map {"$_=\"$token->[$S_ATTR]->{$_}\""}
                        keys %{ $token->[$S_ATTR] };
                    $map = join q{ }, @mapped;
                }
    
                $tag   = $rewrite->{$tag};
                $src   = $token->[$TYPE] eq 'S' ? '<' : '</';
                $src  .= $tag;
                $src  .= $map;
                $src  .= '>';
            }
    
            $filtered .= $src;
        }
        elsif ($token->[$TYPE] eq 'T') {
            $token->[$D_TEXT] =~ s/
                    [
                        \s
                        \t
                    ]+
            / /xms;
            $filtered .= $token->[$D_TEXT]
        }
    }

    return $filtered;
}

1;
__END__

=head1 NAME 

Modwheel-HTML-Tagset - Allow basic tags in strings.

=head1 SYNOPSIS

        use Modwheel::HTML::Tagset;

        my $HTML = <>;
        my $tagset = new Modwheel::HTML::Tagset({
            add_allow => [
                qw(head title meta)
            ],
            add_rewrite => {
                italic => 'i',
                large  => 'big',
            },
        });
        my $strippedString = $tagset->parse($HTML);
        print $strippedString, "\n";

=head1 DESCRIPTION

This module takes a chunk of text and uses HTML::TokeParser to look
for tags. It uses a list of allowed tags and all tags that are not
in that list are removed. It also has support for aliases to tags.

You can pass references instead of scalars
for better performance.

=head1 SUBROUTINES/METHODS

=head2 CONSTRUCTOR

=over 4

=item % C<Modwheel::HTML::TagSet>$tagset =  B<new(\%options)>

Create a new Modwheel::HTML::TagSet object.
Options:

    Modwheel::HTML::Tagset->new({ 
        add_allow    = [qw(....)]  - Add tags to the list of allowed tags.
        allow        = [qw(....)]  - Replace the default list of allowed tags.
        add_rewrite  = {           - Add aliases to tags.
            from_tag => 'to_tag',
            # [... ]
        }
        rewrite      = {
            from_tag => 'to_tag',  - Replace the default list of aliases.
            # [...]
    });

=back

=head2 INSTANCE METHODS

=over 4

=item string B<striptags> (string)

Remove illegal HTML tags in a string.

=item string B<parse> (string)

Parse and filter a string.

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

=over 4

=item L<HTML::TokeParser>

=item L<version>

=back

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 VERSION

v1.0.0

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


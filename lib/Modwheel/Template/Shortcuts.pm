# $Id: Shortcuts.pm,v 1.9 2007/05/18 23:42:42 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/Template/Shortcuts.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.9 $
# $Date: 2007/05/18 23:42:42 $
#####
package Modwheel::Template::Shortcuts;
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw(:std);
use version; our $VERSION = qv('0.3.1');
{
    use URI::Escape  ();
    use Params::Util ('_HASH');
    use Scalar::Util qw( blessed weaken );

    my %cache_uri_for_id = ( );

    public modwheel  => my %modwheel_for,  {is => 'rw'};
    public template  => my %template_for,  {is => 'rw'};
    public resolvers => my %resolvers_for, {is => 'rw'};


    sub new {
        my ($class, $arg_ref) = @_;

        my $self      = register($class);
        my $resolvers = { };

        if(_HASH($arg_ref)) {
            if ($arg_ref->{modwheel}) {
                Scalar::Util::weaken($arg_ref->{modwheel});
                $self->set_modwheel( $arg_ref->{modwheel} );
            }
            if ($arg_ref->{template}) {
                Scalar::Util::weaken($arg_ref->{template});
                $self->set_template( $arg_ref->{template} );
            }
        }
        $self->set_resolvers($resolvers);
        $self->_init_resolvers( );

        return $self;
    }


    sub _init_resolvers {
        my ($self)    = @_;
        my $modwheel  = $self->modwheel;
        my $template  = $self->template;
        $resolvers_for{ident $self} = { };
        my $resolvers = $self->resolvers;
        return if not ref $modwheel;

        my $shortcut_config = $modwheel->config->{shortcuts};
        if (_HASH($shortcut_config)) {
            while (my($key, $content) = each %{ $shortcut_config }) {
                $resolvers->{$key} = $content;
            }
        }

        return;
    }


    sub parse {
        my ($self, $string) = @_;
        return if not $string;

        # Resolve everything inside [ (block start) and ] (block end)
        $string =~ s{( \[ .+? \] )}{$self->resolve($1)}xmseg;
    
        return $string;
    }


    sub resolve {
        my ($self, $string) = @_;
        my $resolvers  = $self->resolvers;
        my $template   = $self->template;

        $string =~ s/ ^\[  //xmsg;
        $string =~ s/  \]$ //xmsg;
        $string =~ tr/\n//d;
        my ($type, $argument_str) = split m/[ \: ]/xms, $string, 2;

        my ($content, $name);
        if ($argument_str) {


            my @temp = split m/[ \| ]/xms, $argument_str, 2;
            ($content, $name) = @temp;

# Perl::Critic thinks my($a, $b) = split(..) is statements separated by comma,
# so we use a temporary array to make perlcritic happy.

            if( !$name ) {
                $name = $content;
            }
        }

        if ($type eq 'file' && $template) {
            my($repid) = $content =~ m/(\d+)/xms;
            if ($cache_uri_for_id{$repid}) {
                return $cache_uri_for_id{$repid};
            }
            else {
                my $repository = $template->repository;
                my $uri = $repository->uri_for_id($repid);
                $cache_uri_for_id{$repid} = $uri;
                return $uri;
            }
        }
        elsif ($resolvers->{$type}) {

            if( !$name ) {
                $name = q{};
            }
            if( !$content ) {
                $content = q{};
            }

            my $res = $resolvers->{$type};
            $res =~ s{\[name    \]}{$name}xmsg;
            $res =~ s{\[type    \]}{$type}xmsg;
            $res =~ s{\[content \]}{$content}xmsg;
            $res =~ s{\[:name   \]}{$self->_uri_escape($name)}xmseg;
            $res =~ s{\[:type   \]}{$self->_uri_escape($type)}xmseg;
            $res =~ s{\[:content\]}{$self->_uri_escape($content)}xmseg;
            return $res;
        }
        else {
            return "[$string]"
        }
    
    }

    sub _uri_escape {
        my ($self, $uri) = @_;
        return URI::Escape::uri_escape($uri, '^A-Za-z0-9');
    }

}


1;
__END__
=head1 NAME

Modwheel::Template::Shortcuts - Class for expanding shortcut abbreviations in strings.

=head1 VERSION

This document describes version 0.3.1.

=head1 SYNOPSIS

    my $string = '[http:www.google.com|Gooooogle]';
    my $shortcuts = Modwheel::Template::Shortcuts->new({
        modwheel => $modwheel,
        template => $template,
    );
    $string = $shortcuts->parse($string);
    print $string, "\n";

    # string is now: '<a href="http://www.google.com">Gooooogle</a>'
    # with the default modwheel configuration.

=head1 DESCRIPTION

In the Modwheel configuration file you can define a set of shortcuts.
An example of an abbreviation with the name C<cpan>, could be defined like this:

       shortcuts:
         cpan:  <a href="http://search.cpan.org?query=[:content]">[name]</a>

Now, if you have a string that contains C<[cpan:Carp|The Carp Module]> and send it to
C<$shortcuts-E<gt>parse> it will replace it with C<E<lt>a
href="http://search.cpan.org?query=Carp"E<gt>The Carp ModuleE<lt>/aE<gt>>

The syntax for resolving an abbreviation in text is:
C<[I<type>:I<content>E<verbar>I<name>]>
The type is the name of the shortcut in the configuration file.

        <a href="http://search.cpan.org?query=
        [:content]                             -> Carp
        ">
        [name]                                 -> The Carp Module

If you add a C<:> to a variable in the shortcut configuration, the
characthers will be properly escaped to be used in a URL. (Using
L<URI::Escape>) 

=head1 SUBROUTINES/METHODS

=head2 CONSTRUCTOR


=over 4

=item C<Modwheel::Template::Shortcuts-E<gt>new($template)>

Create new object.

=back


=head2 INSTANCE METHODS


=over 4

=item C<$shortcuts-E<gt>parse($string)>

Resolve shortcuts in C<$string>.

=back


=head2 PRIVATE ATTRIBUTES


=over 4

=item C<$shortcuts-E<gt>template($template)>

=item C<$shortcuts-E<gt>set_template($template)>

Set or get the Modwheel template object.

=item C<$shortcuts-E<gt>resolvers($resolvers)>

=item C<$shortcuts-E<gt>set_resolvers($resolvers)>

Set or get the current resolvers hash.

=back


=head2 PRIVATE INSTANCE METHODS


=over 4

=item C<$shortcuts-E<gt>init_resolvers()>

Initialize the resolvers hash using the modwheel configuration file.
Used by new().

=item C<$shortcuts-E<gt>resolve($string)>

Private function used by C<parse()> to resolve the shortcuts.

=item C<$shortcuts-E<gt>_uri_escape($string)>

Uses URI::Escape to properly escape unsafe carachters in a string to be
used as an URI.

=back


=head1 DIAGNOSTICS


=over 4

=item * If the [file:] type does not work:

Remember that the file type needs access to the Repository object.
Are you sure you passed the repository object when calling C<-E<gt>new()>?

=back

=head1 CONFIGURATION AND ENVIRONMENT

Uses the Modwheel configuration file. F<config/modwheelconfig.yml>

See L<Modwheel::Manual::Config> for more information.

=head1 DEPENDENCIES


=over 4

=item L<URI::Escape>

=item L<Params::Util>

=item L<Scalar::Utils>

=item L<Version>

=back

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

=over 4

=item * L<Modwheel::Manual>

The Modwheel manual.

=item * L<http://www.0x61736b.net/Modwheel/>

The Modwheel website.

=back

=head1 AUTHOR

Ask Solem, L<< ask@0x61736b.net >>.


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 by Ask Solem L<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

# Local variables:
# vim: ts=4

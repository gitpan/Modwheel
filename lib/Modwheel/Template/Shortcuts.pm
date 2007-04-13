package Modwheel::Template::Shortcuts;
use Scalar::Util;
our %cache_uri_for_id = ( );

=head1 NAME

Modwheel::Template::Shortcuts.

Class for expanding shortcut abbreviations in strings.

=head1 SYNOPSIS

    my $string = '[http:www.google.com|Gooooogle]';
    my $shortcuts = Modwheel::Template::Shortcuts->new($template);
    $string = $shortcuts->parse($string);
    print $string, "\n";

    # string is now: '<a href="http://www.google.com">Gooooogle</a>'
    # with the default modwheel configuration.

=head1 CONSTRUCTOR

=over 4

=item B<public:> C<Modwheel::Template::Shortcuts-E<gt>new($template)>

Create a new Shortcuts object.

=back

=cut
sub new
{
    my ($class, $template) = @_;
    $class = ref $class || $class;
    my $self      = { };
    my $resolvers = { };
    bless $self, $class;

    $self->template($template);
    $self->resolvers($resolvers);
    $self->init_resolvers;

    return $self;
}

=head1 ACCESSORS

=over 4

=item B<private:> C<$shortcuts-E<gt>template($template)>

Set or get the Modwheel template object.

=cut
sub template
{
    my ($self, $template) = @_;
    Scalar::Util::weaken( $self->{_TEMPLATE_} = $template ) if $template;
    return $self->{_TEMPLATE_};
}

=item B<private:> C<$shortcuts-E<gt>resolvers($resolvers)>

Set or get the current resolvers hash.

=cut
sub resolvers
{
    my ($self, $resolvers) = @_;
    $self->{_RESOLVERS_} = $resolvers if $resolvers;
    return $self->{_RESOLVERS_};
}

=item B<private:> C<$shortcuts-E<gt>init_resolvers()>

Initialize the resolvers hash using the modwheel configuration file.
Used by new().

=cut
sub init_resolvers
{
    my ($self)    = @_;
    my $modwheel  = $self->template->modwheel;
    my $resolvers = $self->resolvers;

    my $shortcut_config = $modwheel->config->{shortcuts};
    if (ref $shortcut_config eq 'HASH') {
        while (my($key, $content) = each %$shortcut_config) {
            $resolvers->{$key} = $content;
        }
    }
}

=item B<public:> C<$shortcuts-E<gt>parse($string)>

Resolve shortcuts in C<$string>.

=cut
sub parse
{
    my ($self, $string) = @_;
    return undef unless $string;

    $string =~ s#(\[.+?\])#$self->resolve($1)#seg;
    
    return $string;
}

=item B<private:> C<$shortcuts-E<gt>resolve($string)>

Private function used by C<parse()> to resolve the shortcuts.

=cut
sub resolve
{
    my ($self, $string) = @_;
    my $resolvers  = $self->resolvers;
    my $template   = $self->template;
    my $repository = $template->repository;
    Scalar::Util::weaken($repository);

    $string =~ s/^\[//g;
    $string =~ s/\]$//g;
    $string =~ tr/\n//d;
    my($type, $argument_str) = split ':',  $string, 2;
    my($content, $name)      = split /\|/, $argument_str if($argument_str);
    $name ||= $string;

    if ($type eq 'file') {
        my($repid) = $content =~ m/(\d+)/;
        if ($cache_uri_for_id{$repid}) {
            return $cache_uri_for_id{$repid};
        }
        else {
            my $uri = $repository->uriForId($repid);
            $cache_uri_for_id{$repid} = $uri;
            return $uri;
        }
    }
    elsif ($resolvers->{$type}) {
        my $res = $resolvers->{$type};
        $res =~ s#\[name\]#$name#g;
        $res =~ s#\[type\]#$type#g;
        $res =~ s#\[content\]#$content#g;
        $res =~ s#\[:name\]#$template->uri_escape($name)#eg;
        $res =~ s#\[:type\]#$template->uri_escape($type)#eg;
        $res =~ s#\[:content\]#$template->uri_escape($content)#eg;
        return $res;
    }
    else {
        return "[$string]"
    }
}

1;

__END__

=back

=head1 HISTORY

0.1 (13.06.2004) Initial version.

=head1 AUTHORS

B<Ask Solem Hoel> L<ask@0x61736b.net>

=head1 COPYRIGHT

Copyright (C) 2004-2007 Ask Solem Hoel. All rights reserved.

=cut

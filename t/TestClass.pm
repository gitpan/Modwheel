
{ package TestClass;
use strict;
use warnings;
use Data::Dumper;
use Class::InsideOut::Policy::Modwheel qw( :std );

public title => my %title_for, {is => 'rw'};

sub new {
    my ($class, $arg_ref) = @_;

    my $self = register($class);

    $self->set_title( $arg_ref->{title} );

    return $self;
}

1; }

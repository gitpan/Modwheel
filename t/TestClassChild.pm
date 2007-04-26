
{ package TestClassChild;
use strict;
use warnings;
use Data::Dumper;
use Class::InsideOut::Policy::Modwheel qw( :std );
use base qw(TestClass);

public phone => my %phone_for, {is => 'rw'};

sub new {
    my ($class, $arg_ref) = @_;

    my $self = $class->SUPER::new($arg_ref);

    $self->set_phone( $arg_ref->{phone} );

    return $self;
}

    
1;}


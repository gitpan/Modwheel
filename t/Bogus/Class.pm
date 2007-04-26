package Bogus::Class;

sub new {
    my ($class) = @_;
    my $self = bless { }, $class;

    $self->set_loaded_ok( );

    return $self;
}

sub set_loaded_ok {
    my ($self) = @_;
    $self->{_loaded_ok} = 1;
}

sub loaded_ok {
    my ($self) = @_;
    return $self->{_loaded_ok} ? 1 : 0;
}

sub connect    { return 1; };
sub connected  { return 1; };
sub disconnect { return 1; };
sub init       { return 1; };

1;

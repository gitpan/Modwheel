
use Test::More tests => 26;

BEGIN {
    use lib './t';
}

{
    package smoke::TestClass::Person;
    use Class::InsideOut::Policy::Modwheel qw(:std);

    public 'name'      => my %name,     {is => 'rw'};
    public 'onlyread'  => my %readonly, {is => 'ro'};

    sub new {
        register( shift );
    };

}
{
    package smoke::TestClass::Person::Info;
    our @ISA = qw(smoke::TestClass::Person);
    use Class::InsideOut::Policy::Modwheel qw(:std);
    
    public 'address'       => my %address,    {is => 'rw'};
    public 'phone'         => my %phone,      {is => 'rw'};

}
{
    package smoke::TestClass::Using::isaOption;
    use Class::InsideOut::Policy::Modwheel qw(:std);
    
    public person         => my %person,      {is => 'rw', isa => 'smoke::TestClass::Person'        };
    public info           => my %info,        {is => 'ro', isa => 'smoke::TestClass::Person::Info'  };

    sub new {
        my ($class, $options_ref) = @_;
        my $self       = register($class);
        $options_ref ||= { };

        $info{ident $self} = $options_ref->{info};

        return $self;
    }
    
}
package main;

my $person  = smoke::TestClass::Person->new();
my $person2 = smoke::TestClass::Person->new();
isa_ok($person, 'smoke::TestClass::Person');

foreach my $method (qw(name set_name onlyread)) {
    ok($person->can($method));
}

ok($person->ident);
ok($person2->ident);
isnt($person->ident, $person2->ident);

ok(!$person->can('set_onlyread'));

$person->set_name('Hello World');

is($person->name, 'Hello World');

my $person_with_info    = smoke::TestClass::Person::Info->new;
isa_ok($person_with_info, smoke::TestClass::Person::Info);

foreach my $method
    (qw(name set_name onlyread address set_address phone set_phone))
{
    ok($person_with_info->can($method));
}

my $isaOption = smoke::TestClass::Using::isaOption->new({
    info => $person_with_info,
});
isa_ok($isaOption,  'smoke::TestClass::Using::isaOption');

foreach my $method (qw(person set_person info)) {
    ok( $isaOption->can($method), '$isaOption->can '.$method );
}

isa_ok($isaOption->info, 'smoke::TestClass::Person::Info');
isa_ok($isaOption->person, 'smoke::TestClass::Person');
# provided info object inside new object is the same
is($isaOption->info, $person_with_info,
    'provided info object inside new object has same memory address'
);

use TestClassChild;


my $tc = TestClassChild->new({
    title => 'Monster Jack',
    phone => "+45 99 13 43 21",
});

is( $tc->title, 'Monster Jack', 'Test inheritance');
is( $tc->phone, '+45 99 13 43 21' );



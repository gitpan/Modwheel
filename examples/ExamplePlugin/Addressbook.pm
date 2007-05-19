package ModwheelX::Addressbook;
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw( :std );
{

=for Comment
     This is an example address book.
     It relies on the following database table:

     CREATE TABLE addressbook (
       id       INT NOT NULL PRIMARY KEY,
       name     VARCHAR(255),
       address  VARCHAR(255),
       phone    VARCHAR(20),
       email    VARCHAR(20)
    );

    It can be used from within perl like this:

    my $addressbook = Modwheel::Plugin::Addressbook->new({
        modwheel => $modwheel,
        db       => $db,
    });
    
    $addressbook->set_name('Foo Bar');
    $addressbook->set_address('Shellcode park 3b');
    $addressbook->phone('047 1337');
    $addressbook->email('foo@bar.info');

    $addressbook->save;

    my $entry = $addressbook->fetch( $id );

=cut

    # ## Some object attributes.
    public id       => my %id_for,      {is => 'rw'};
    public name     => my %name_for,    {is => 'rw'};
    public address  => my %address_for, {is => 'rw'};
    public phone    => my %phone_for,   {is => 'rw'};
    public email    => my %email_for,   {is => 'rw'};


    sub new {
        my $class = shift;
        my $self  = $class->SUPER::new(@_);
        my ($options_ref) = @_;
        $options_ref    ||= { };

        $id_for{ident $self}      = $options_ref->{id};
        $name_for{ident $self}    = $options_ref->{name};
        $address_for{ident $self} = $options_ref->{address};
        $phone_for{ident $self}   = $options_ref->{phone};
        $email_for{ident $self}   = $options_ref->{email};


        return $self;
    }


    sub fetch {
        my ($self, $id) = @_;
        $id ||= $self->id;
        return if not $id;

        my $db = $self->db;

        # This creates a query like this: SELECT * FROM addressbook WHERE id = ?
        my $q  = $db->build_select_q('addressbook', q{*}, {id => '?'});

        # arguments to fetchonerow_hash is the query and the bind variables.
        my $entry = $db->fetchonerow_hash($q, $id); 
        
        return $entry;
    }

    sub save {
        my ($self) = @_;
        my $db     = $self->db;
        my $id     = $self->id;
        my $ret;

        if ($id) {
            my $ret = $db->update('addressbook', [qw(name address phone email)], { id => '?' }, $id,
                $self->name,
                $self->address,
                $self->phone,
                $self->email,
            );
        } else {
            my $new_id = $db->fetch_next_id('addressbook');
            my $ret = $db->insert('addressbook', [qw(id name address phone email)], $new_id,
                $self->name,
                $self->address,
                $self->phone,
                $self->email,
            );
            $self->set_id($new_id);
        }
                
        return $ret;
    }

}

1;

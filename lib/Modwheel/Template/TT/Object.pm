package Modwheel::Template::TT::Object;
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/Object.pm - Work with Modwheel-objects in Template Toolkit.
#                        Internal use only.
# 
# (c) 2007 Ask Solem Hoel <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

sub new
{
    my ($class, $object) = @_;
    $class   = ref $class || $class;

    my $self = bless { }, $class;
    $self->set_object($object);

    return $self;
}

sub object
{
    return $_[0]->{_MODWHEEL_OBJECT_};
}

sub set_object
{
    $_[0]->{_MODWHEEL_OBJECT_} = $_[1];
}

sub setObjectValues
{
    my ($self, $argv) = @_;
    return undef unless UNIVERSAL::isa($argv, 'HASH');

    while (my($field, $value) = each %$argv) {
        $value =~ s/^\s+//;
        $value =~ s/\s+$//;
        if ($self->object->can($field) && ($value || $value eq '0')) {
            $self->object->$field($value)
        }
    }

    return undef;
}

# ###
# this may seem dirty, but Class::Struct also does it, so why not? :)
# It iterates through the Modwheel::Object accessor methods and creates
# shortcuts so we can easily use them in Template Toolkit like this:
#
# [% object = modwheel.fetch(id => 1) %]
# <h1>[% object.title %]</h1>
# <p> [% object.description %] </p>
#
#my $out;
foreach my $method (keys %Modwheel::Object::methods) {
   #$out .= "sub $method { return \$_[0]->object->$method };"
   eval "sub $method { return \$_[0]->object->$method };"
}
#eval $out;

1;

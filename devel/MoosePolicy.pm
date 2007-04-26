
package Modwheel::Policy;

use constant attribute_metaclass => 'Modwheel::Policy::Attribute';

package Modwheel::Policy::Attribute;
use Moose;

extends 'Moose::Meta::Attribute';

before '_process_options' => sub {
    my ($class, $name, $options) = @_;
    
    if (exists $options->{is}) {
        if(! exists $options->{reader} || ! exists $options->{writer}) {
            if    ($options->{is} eq 'ro') {
                $options->{reader} = $name;
            }
            elsif ($options->{is} eq 'rw') {
                $options->{reader} = $name;
                $options->{writer} = 'set_' . $name;
            }
            delete $options->{is};
        }
    }

    return;
};


1;

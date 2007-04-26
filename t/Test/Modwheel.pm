  package Test::Modwheel;
use strict;
use warnings;
use Carp;
use Readonly;
use English                 qw( -no_match_vars );
use Scalar::Util            qw( blessed );
use Params::Util            ('_HASH', '_ARRAY', '_INSTANCE');
use Data::Dumper            qw();
use Perl6::Export::Attrs;
use Modwheel;


sub TRUE  : Export(:boolean)   {
    return 1;
}
sub FALSE : Export(:boolean)   {
    return 0;
}

Readonly my $ADD_SUFFIX     => 1;
Readonly my $NO_SUFFIX      => 0;

sub new {
    my ($class, $arg_ref) = @_;
    
    unless (_HASH($arg_ref)) {
        croak "Argument to Test::Modwheel::new() must be reference to hash."
    }
    
    my $self = { };
    bless $self, $class;

    if ($arg_ref->{config}) {
        $self->set_config( $arg_ref->{config} );
    }

    return $self;
}

sub get_config {
    my ($self) = @_;
    return $self->{_CONFIG_};
}

sub set_config {
    my ($self, $config_ref) = @_;
    $self->{_CONFIG_} = $config_ref;
    return;
}

sub database_driver_module_filename {
    my ($self) = @_;
    my $testconfig = $self->get_config();
    croak "No config" unless $testconfig;

    # Create a temporary modwheel object to test the database config. 
    my $modwheel_tmp = Modwheel->new( $testconfig ); 

    # ## Check  the database driver backend in the test config
    my $backend  = $modwheel_tmp->siteconfig->{database}{type};

    if (! $backend) {
        $backend = 'Modwheel::DB::Base';
    }
    # User can select the full class name or just the name
    # of the database.
    if ($backend !~ m/::/) {
        $backend = 'Modwheel::DB::' . $backend;
    }
    my $file = $self->class_to_filename($backend, $ADD_SUFFIX);


    $modwheel_tmp = undef;

    return $file;
}

sub class_to_filename {
    my ($self, $class, $bool_add_suffix) = @_;
    $bool_add_suffix ||= $ADD_SUFFIX;

    $class =~ s{ :: }{/}xmsg;

    if ($bool_add_suffix == $ADD_SUFFIX) {
        $class .= '.pm';
    }

    return $class;
}

sub database_driver {
    my ($self) = @_;

    my $driver_filename =
        $self->database_driver_module_filename();
    return FALSE unless $driver_filename;

    eval q{require "$driver_filename"};

    return $EVAL_ERROR      ? FALSE
                            : TRUE
    ;
} 

sub db_missing_required_module {
    my ($self, $db) = @_;

    my @modules_required   = $db->driver_requires;
    my $num_modules_passed = 0;

    REQUIRED:
    for my $module (@modules_required) {
        my $module_filename = $self->class_to_filename($module, $NO_SUFFIX);
        
        next REQUIRED if $INC{$module_filename};

        # Turn of warnings in eval using $WARNING ($^W).
        my $saved_warning_state = $WARNING;
        $WARNING = 0;

        eval "use $module";

        # If warnings was on before, turn it on again.
        $WARNING = $saved_warning_state;

        if ($EVAL_ERROR) {
            return $module;
        }
    }

    return;
}



1;
__END__

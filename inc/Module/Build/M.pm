# $Id: M.pm,v 1.2 2007/05/18 22:40:27 ask Exp $
# $Source: /opt/CVS/Modwheel/inc/Module/Build/M.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.2 $
# $Date: 2007/05/18 22:40:27 $
package inc::Module::Build::M;
use strict;
use warnings;
use Carp;
use File::Spec;
use File::Spec::Functions qw( splitpath catfile );
use English qw( -no_match_vars );
our $VERSION = 1.0;

use base 'Module::Build';

use inc::M::Bootstrap;

my $CONFIG_MODULE = 'Modwheel::BuildConfig';

my @DEFAULT_PREFIX;

if ($OSNAME eq 'Win32') {
    @DEFAULT_PREFIX = ('Program Files', 'Modwheel'); ## no critic
}
else {
    @DEFAULT_PREFIX = qw(opt modwheel);
}

sub new {
    my $class  = shift;
    my $self   = $class->SUPER::new(@_);
    my %args   = @_;
    my $reason;

    my $prefix = File::Spec->catdir(@DEFAULT_PREFIX);
       $prefix = File::Spec->rel2abs($prefix, q{/});
    $self->set_m_prefix($prefix);

    my $config = $self->notes('config_data') || { };
    $self->set_m_config($config);

    $reason = $self->m_configure( );
    if ($reason) {
        croak "Could not install Modwheel. Reason: $reason";
    }

    $reason = $self->m_save_config(\%args);
    if ($reason) {
        croak "Could not install Modwheel. Reason: $reason";
    }

    return $self;
}

sub m_config {
    my ($self) = @_;
    return $self->{__m_config__};
}

sub set_m_config {
    my ($self, $config_ref) = @_;
    $self->{__m_config__}   = $config_ref;
    return;
}

sub m_prefix {
    my ($self) = @_;
    return $self->{__m_prefix__};
}

sub set_m_prefix {
    my ($self, $prefix) = @_;
    $self->{__m_prefix__} = $prefix;
    return;
}

sub m_configure {
    my ($self) = @_;
    my $config = $self->m_config;
    my $prefix = $self->m_prefix;

    my $q = 'Where would you like to install Modwheel?';
    $prefix = $self->prompt($q, $prefix);
    $config->{prefix} = $prefix;
    $self->set_m_prefix($prefix);
    
    return;
}

sub m_save_config {
    my ($self, $args) = @_;
    my $config = $self->m_config;

    $self->notes('config_module', $CONFIG_MODULE);
    $self->notes('config_data',   $config);

    return;
}

sub ACTION_build {
    my $self = shift;
    $self->SUPER::ACTION_build(@_);
    $self->m_write_config( );
    inc::M::Bootstrap->strap_it( );

    return;
}

sub m_write_config {
    my ($self) = @_;
    my $module_file = $self->notes( 'config_module' );
    my $data = $self->notes( 'config_data'   );
    my $dump = Data::Dumper->new([$data], ['config_data'])->Dump;
    my @file_path = split m/::/xms, $module_file;
    my $file_path = catfile( 'blib', 'lib', @file_path );
       $file_path = $file_path . q{.pm};

    my $path = ( splitpath( $file_path ) )[1];
    if (!-d $path) {
        mkpath($path);
    };

    my $package = <<"END_MODULE";
        package $module_file;

        my $dump;

        sub get_value {
            my (\$class, \$key) = \@_;
            return unless exists \$config_data->{\$key};
            return               \$config_data->{\$key};
        }

        1;
END_MODULE
    ;
                                                                                       
    $package =~ s/^\t//xmsg;
    open  my $fh, '>', $file_path
        or die "Cannot write config file module '$path': $OS_ERROR\n";
    print {$fh} $package;
    close $fh
        or die "Couldn't close config file module '$path': $OS_ERROR\n";

    return;
}
1;

# $Id: Makefile.PL,v 1.14 2007/05/19 13:02:43 ask Exp $
# $Source: /opt/CVS/Modwheel/Makefile.PL,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.14 $
# $Date: 2007/05/19 13:02:43 $
use strict;
use warnings;
no strict 'subs';
use ExtUtils::MM_Unix ();
use inc::Module::Install;
use inc::M::Bootstrap;
use English qw( -no_match_vars );

#############################################################

# Configuration for this script is done in the config.ph file.
our $BUILD_CONFIGFILE = 'config.ph';

# ##########################################################

my $BUILD_CONFIG = get_config_ph( );    

# Define metadata
name            $BUILD_CONFIG->{module_name};
version         $BUILD_CONFIG->{dist_version};
all_from        $BUILD_CONFIG->{all_from};
author          $BUILD_CONFIG->{dist_author};
license         $BUILD_CONFIG->{license};

include('ExtUtils::AutoInstall');
    
# Specific dependencies
while (my ($module, $version) = each %{ $BUILD_CONFIG->{requires} }) {
    requires $module => $version;
}

while (my ($module, $version) = each %{ $BUILD_CONFIG->{build_requires} }) {
    build_requires  $module => $version;
}

while (my ($module, $version) = each %{ $BUILD_CONFIG->{recommends} }) {
    recommends  $module => $version;
}
    
no_index        'directory'            => '.svn';
    
auto_install();

print qq{-\n};
$inc::M::Bootstrap::builder = 'Makefile.PL';
my $buildconfig_class = $BUILD_CONFIG->{config_module};
my $default_prefix    = inc::M::Bootstrap->default_prefix( );
my $prefix 
    = ExtUtils::MakeMaker::prompt('Where would you like to install Modwheel?', $default_prefix);
my $config_data = {
    prefix => $prefix,
};
print "Writing build configuration to $buildconfig_class...\n";
inc::M::Bootstrap->write_buildconfig($buildconfig_class, $config_data);
print qq{-\n};

inc::M::Bootstrap->strap_it( );

WriteAll;

sub get_config_ph {
    no warnings;
    my $configfile = slurp_file($BUILD_CONFIGFILE);
    my $BUILD_CONFIG = {eval $configfile};
    if ($EVAL_ERROR) {
        die "Error with config.ph, please review the file for syntax error(s).\n";
    }
    return $BUILD_CONFIG;
}

sub slurp_file {
    my ($filepath) = @_;
    open my $fh, '<', $filepath
        or die "Couldn't open $filepath for reading: $OS_ERROR\n";
    my $contents = do { local $/; <$fh> };
    close $fh
        or die "Couldn't close $filepath after reading: $OS_ERROR\n";
    return $contents;
}

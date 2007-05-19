use strict;
use warnings;
no strict 'subs';
use ExtUtils::MM_Unix ();
use inc::M::Bootstrap;

use inc::Module::Install;

# Define metadata
name            'Modwheel';
version         '0.3.1';
all_from        'lib/Modwheel.pm';
author          'Ask Solem <ask@0x61736b.net>';
license         'perl';

include('ExtUtils::AutoInstall');
    
# Specific dependencies
requires        'namespace::clean'      => 0;
requires        'version'               => 0;
requires        'Carp'                  => 0;
requires        'Params::Util'          => 0.23;
requires        'POSIX'                 => 0;
requires        'Data::Dumper'          => 0;
requires        'FileHandle'            => 0;
requires        'Fcntl'                 => 0;
requires        'Scalar::Util'          => 1.14; # Last significant bug fix for weaken 
requires        'List::Util'            => 0;
requires        'List::MoreUtils'       => 0;
requires        'Sub::Install'          => 0;
requires        'Readonly'              => 1.00;
recommends      'Readonly::XS'          => 1.00;
requires        'Perl6::Export::Attrs'  => 0;
requires        'YAML'                  => 0.39;
requires        'YAML::Syck'            => 0.84;
requires        'DBI'                   => 1.51;
requires        'Crypt::Eksblowfish'    => 0.001;
requires        'HTML::Tagset'          => 3.10;
requires        'HTML::Parser'          => 3.48;
requires        'URI::Escape'           => 3.28;
requires        'AppConfig'             => 1.56;
requires        'Template'              => 2.18;
requires        'Template::Context'     => 2.98;
requires        'Template::Stash::XS'   => 0;
requires        'Template::Plugin'      => 2.70;
requires        'Term::ReadKey'         => 2.30;
requires        'Getopt::Euclid'        => 0.001000;
requires        'Perl6::Export'         => 0.07;
requires        'Perl6::Form'           => 0.04;
requires        'IO::Prompt'            => '0.099004';
requires        'Digest::SHA1'          => 2.11;
requires        'IO::Interactive'       => '0.0.3';
requires        'Perl6::Slurp'          => 0.03;

build_requires  'Test::More'            => 0.42;
recommends      'Test::Pod'             => 1.26;
recommends      'Test::Pod::Coverage'   => 0;
recommends      'Test::YAML::Valid'     => 0;
recommends      'Test::Exception'       => 0;
recommends      'Perl::Critic'          => 1.051;
recommends      'Test::Perl::Critic'    => 1.0;
recommends      'Test::YAML::Meta'      => 0.04;
recommends      'Test::Kwalitee'        => 0.30;
    
no_index        'directory'            => '.svn';
#install_script  'bin/install.sh';
    
auto_install();
WriteAll;
inc::M::Bootstrap->strap_it( );

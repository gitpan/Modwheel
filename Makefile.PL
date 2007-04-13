use inc::Module::Install;
    
# Define metadata
name            'Modwheel';
all_from        'lib/Modwheel.pm';
author          'Ask Solem Hoel <ask@0x61736b.net>';
license         'perl';

    
# Specific dependencies
requires        'Carp'                  => 0;
requires        'POSIX'                 => 0;
requires        'Data::Dumper'          => 0;
requires        'FileHandle'            => 0;
requires        'Fcntl'                 => 0;
requires        'Scalar::Util'          => 0;
requires        'Class::Struct'         => 0;
requires        'YAML'                  => 0.39;
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


build_requires  'Test::More'            => 0.42;
recommends      'Test::Pod'             => 1.26;
    
no_index        'directory'            => '.svn';
#install_script  'bin/install.sh';
    
auto_install;
WriteAll;

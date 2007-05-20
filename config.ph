# $Id: config.ph,v 1.2 2007/05/19 18:46:44 ask Exp $
# $Source: /opt/CVS/Modwheel/config.ph,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.2 $
# $Date: 2007/05/19 18:46:44 $
module_name          => 'Modwheel',
license              => 'perl',
dist_author          => 'Ask Solem <ASKSH@cpan.org>',
dist_version         => '0.3.3',
dist_version_from    => 'lib/Modwheel.pm',
all_from             => 'lib/Modwheel.pm',
dynamic_config       => NO,
sign                 => NO, # asksh: have to find out why my signature fails.
recursive_test_files => YES,
config_module        => 'Modwheel::BuildConfig',
docs => [ qw(
    lib/Modwheel/Manual.pod
    lib/Modwheel/Manual/Install.pod
    lib/Modwheel/Manual/Config.pod
) ], 

requires             => {
    'version'               => 0,       # 
    'namespace::clean'      => 0.01,
    'Params::Util'          => 0.22,    # bugfix for _CODELIKE
    'Scalar::Util'          => 1.14,    # weaken works here.
    'List::Util'            => 1.15,    # memory-leak fixed.
    'List::MoreUtils'       => 0.13,    # memory-leak fixed.
    'Sub::Install'          => 0.90,    # breaks backwards-compatability
    'Readonly'              => 1.03,    # breaks backwards-compatability
    'Perl6::Export::Attrs'  => '0.0.1',
    'YAML'                  => 0.50,
    'YAML::Syck'            => 0.70,    
    'JSON::Syck'            => 0.14,
    'DBI'                   => 1.51,    
    'HTML::Tagset'          => 3.03,    # [Alexandr Ciornii CHORNY@cpan.org]: Last significant change.
    'HTML::Parser'          => 3.48,
    'URI'                   => 1.29,
    'AppConfig'             => 1.56,    
    'Template'              => 2.17,    # 2.17 needed to work on Mac OS X intel.
    'Template::Stash::XS'   => 0,
    'Term::ReadKey'         => 2.30,    # no changelog for Term::ReadKey?
    'Getopt::Euclid'        => 0.001000, #  for :vars to work properly.
    'Perl6::Export'         => 0.06,    # 0.07 is only a minor bug-fix.
    'Perl6::Form'           => 0.04,
    'IO::Prompt'            => 0.099004,
    'Digest::SHA1'          => 2.07,    # [Alexandr Ciornii CHORNY@cpan.org]: Last significant change.
    'IO::Interactive'       => '0.0.1', # Minimum version we need.
    'UNIVERSAL::require'    => 0.10,    # 0.10 fixes a security issue.
},
recommends           => {
    'Test::Pod'             => 1.22,    # Last significant bug-change.
    'Pod::Coverage'         => 0.18,       
    'Test::Pod::Coverage'   => 1.08,    # Last significant bug-change.
    'Readonly::XS'          => 1.02,
    'Test::YAML::Valid'     => 0.03,
    'Test::Exception'       => 0.25,
    'Perl::Critic'          => 1.051,
    'Test::Perl::Critic'    => 1.0,
    'Test::YAML::Meta'      => 0.04,
    'Test::Kwalitee'        => 0.30,
    'UNIVERSAL::require'    => 0.11,    # 0.11 is said to be 400% percent faster than 0.10 ;)
    'Crypt::Eksblowfish'    => 0.001,
    'Crypt::UnixCrypt'      => 1.0,
    'Digest::SHA1'          => 2.04,    # PerlIO bug fixed in this version.
    'Digest::MD5'           => 2.35,    # 
},
build_requires       => {
    'Test::Simple'            => 0.42,    # 
},
add_to_cleanup       => [ qw(
    a.out
    test.pl
    test.c
    test.cpp
    test.m
    *.swp
    .gdb_history
    install.cache
    t/cache
    ) ],
auto_features        => {
    db_sqlite_support       => {
        description             => 'SQLite as database driver.',
        requires                => {
            'DBD::SQLite'           => 1.13,
        },
    },
    db_sqlite2_support       => {
        description             => 'SQLite2 as database driver.',
        requires                => {
            'DBD::SQLite2'           => 0.33,
        },
    },
    db_mysql_support        => {
        description             => 'MySQL as database driver.',
        requires                => {
            'DBD::mySQL'            => 0,
        },
    },
    db_postgres_support     => {
        description             => 'PostgreSQL as database driver.',
        requires                => {
            'DBD::Pg'               => 0
        },
    },
    pe_template_toolkit     => {
        description             => 'Template Toolkit as presentation engine.',
        requires                => {
            'Template'              => 2.18, 
            'Template::Stash::XS'   => 0,
         },
    },
},
get_options          => {
    DOCONFIG        => { },
    AUTOCONFIG      => { },
},
meta_merge          => {
    resources           => {
        HomePage            => 'http://www.0x61736b.net/Modwheel',
        Download            => 'http://search.cpan.org/~asksh/Modwheel-0.3.3/',
    },
    distribution_type   => 'Application',
},

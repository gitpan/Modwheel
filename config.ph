# $Id: RCS.stub,v 1.1 2007/04/23 19:28:42 ask Exp $
# $Source: /opt/CVS/Modwheel/devel/RCS.stub,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.1 $
# $Date: 2007/04/23 19:28:42 $
module_name          => 'Modwheel',
license              => 'perl',
dist_author          => 'Ask Solem <ASKSH@cpan.org>',
dist_version         => '0.3.2',
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
    'namespace::clean'      => 0,
    'version'               => 0,
    'Carp'                  => 0,
    'Params::Util'          => 0.23,
    'POSIX'                 => 0,
    'Data::Dumper'          => 0,
    'FileHandle'            => 0,
    'Fcntl'                 => 0,
    'Scalar::Util'          => 1.14,
    'List::Util'            => 0,
    'List::MoreUtils'       => 0,
    'Sub::Install'          => 0,
    'Readonly'              => 1.00,
    'Perl6::Export::Attrs'  => 0,
    'YAML'                  => 0.39,
    'YAML::Syck'            => 0.84,
    'DBI'                   => 1.51,
    'Crypt::Eksblowfish'    => 0.001,
    'HTML::Tagset'          => 3.03,    # [Alexandr Ciornii CHORNY@cpan.org]: Last significant change.
    'HTML::Parser'          => 3.48,
    'URI::Escape'           => 3.28,
    'AppConfig'             => 1.56,
    'Template'              => 2.18,
    'Template::Context'     => 2.98,
    'Template::Stash::XS'   => 0,
    'Template::Plugin'      => 2.70,
    'Term::ReadKey'         => 2.30,
    'Getopt::Euclid'        => 0.001000,
    'Perl6::Export'         => 0.07,
    'Perl6::Form'           => 0.04,
    'IO::Prompt'            => 0.099004,
    'Digest::SHA1'          => 2.07,    # [Alexandr Ciornii CHORNY@cpan.org]: Last significant change.
    'IO::Interactive'       => '0.0.3',
    'Perl6::Slurp'          => 0.03,
    'File::Copy::Recursive' => 0,
},
recommends           => {
    'Test::Pod'             => 0,
    'Pod::Coverage'         => 0,
    'Test::Pod::Coverage'   => 0,
    'Readonly::XS'          => 1.00,
    'Test::YAML::Valid'     => 0,
    'Test::Exception'       => 0,
    'Perl::Critic'          => 1.051,
    'Test::Perl::Critic'    => 1.0,
    'Test::YAML::Meta'      => 0.04,
    'Test::Kwalitee'        => 0.30,
},
build_requires       => {
    'Test::More'            => 0.42,
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
        Download            => 'http://search.cpan.org/~asksh/Modwheel-0.3.2/',
    },
    distribution_type   => 'Application',
},

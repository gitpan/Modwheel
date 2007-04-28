use strict;
use warnings;
use inc::Module::Build::Modwheel;

sub YES { 1 };
sub NO  { 0 };

# if set to a string, we should create the installation directory.
my $prefix = q{};

$ENV{DEVEL_COVER_OPTIONS} = '-ignore,blib/Class/InsideOut/Policy/Modwheel.pm';

#my $builder = inc::Module::Build::Modwheel->new(
 my $builder = Module::Build->new(
    module_name          => 'Modwheel',
    license              => 'perl',
    dist_author          => 'Ask Solem <ASKSH@cpan.org>',
    dist_version_from    => 'lib/Modwheel.pm',
    dynamic_config       => NO,
    sign                 => NO, # asksh: have to find out why my signature fails.
    recursive_test_files => YES,
    config_module        => 'Modwheel::BuildConfig',
    config_questions     => [
            ['Where do you want to install modwheel?', 'prefix',
            '/opt/modwheel'],
    ],
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
        'HTML::Tagset'          => 3.10,
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
        'Digest::SHA1'          => 2.11,
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
    },
    build_requires       => {
        'Test::More'            => 0.42,
    },
    pod_files            => {
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
        PREFIX                  => {
            store                   => \$prefix
        },
        DOCONFIG        => { },
        AUTOCONFIG      => { },
    },
    meta_merge          => {
        resources           => {
            homepage            => 'http://www.0x61736b.net/Modwheel',
            cpan                => 'http://search.cpan.org/~asksh/Modwheel-0.02/',
        },
        uses            => {
            scriptaculous       => 'http://script.aculo.us/',
        },
    },
    
);

$builder->create_build_script( );


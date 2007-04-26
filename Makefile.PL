use strict;
use warnings;
no strict 'subs';
use ExtUtils::MM_Unix ();

=for comment
BEGIN {
    use English qw( -no_match_vars );
    eval 'use version';
    if ($EVAL_ERROR) {
        die 'Modwheel requires the version module. ' .
            'You can download version from CPAN: '   .
            "http://search.cpan.org/~jpeacock/version-0.71/.\n"
        ;
    }
    eval 'use Readonly';
    if ($EVAL_ERROR) {
        die 'Modwheel requires the Readonly module. ' .
            'You can download Readonly from CPAN: '   .
            "http://search.cpan.org/~roode/Readonly-1.03/\n"
        ;
    }
}

use version;
use Readonly;

my $v = version->new;

Readonly my $MAIN_DIST_FILE => 'lib/Modwheel.pm';

my $modwheel_version = ExtUtils::MM_Unix->parse_version($MAIN_DIST_FILE);
my $modwheel_numified_version = version->new($modwheel_version)->numify;

=cut

use inc::Module::Install;

# Define metadata
name            'Modwheel';
version         '0.2.1';
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

build_requires  'Test::More'            => 0.42;
recommends      'Test::Pod'             => 1.26;
recommends      'Test::Pod::Coverage'   => 0;
recommends      'Test::YAML::Valid'     => 0;
recommends      'Test::Exception'       => 0;
recommends      'Perl::Critic'          => 1.051;
recommends      'Test::Perl::Critic'    => 1.0;
    
no_index        'directory'            => '.svn';
#install_script  'bin/install.sh';
    
auto_install();
WriteAll;
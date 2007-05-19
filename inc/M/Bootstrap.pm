package inc::M::Bootstrap;
# $Id: Bootstrap.pm,v 1.3 2007/05/18 23:42:33 ask Exp $
# $Source: /opt/CVS/Modwheel/inc/M/Bootstrap.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.3 $
# $Date: 2007/05/18 23:42:33 $
use strict;
use warnings;
use Carp;
use File::Spec;
use File::Spec::Functions qw( splitpath catfile );
use English qw( -no_match_vars );
our $VERSION = 1.0;

use base 'Module::Build';

use inc::M::InstallerBuilder;

# Name of the class to generate.
my $OUTCLASS    = 'Modwheel::Install::Everything';

# Use catdir to make paths for sql-files for databases.
# catdir is portable to other OS's than unix.
my $mysql_path  = File::Spec->catdir('sql', 'MySQL');
my $sqlite_path = File::Spec->catdir('sql', 'SQLite');

#========================================================================
# %STRAP: List of installer-modules to generate.
#
# Key: Class-name
#   in  => Directory (from cwd) to copy files from.
#          (files won't be copied now, but they will be self-contained
#          into the module generated).
#   out => Directory (relative to prefix) to write files to,
#         when the generated module's write_files method is run.
#========================================================================
my %STRAP = (
    'Modwheel::Install::Localized' => {
        in      => 'Localized',
        out     => 'Localized',
    },
    'Modwheel::Install::Templates' => {
        in      => 'Templates',
        out     => 'Templates',
    },
    'Modwheel::Install::sql::MySQL' => {
        in      => $mysql_path,
        out     => $mysql_path,
    },
    'Modwheel::Install::sql::SQLite' => {
        in      => $sqlite_path,
        out     => $sqlite_path,
    },
    'Modwheel::Install::doc'         => {
        in      => 'doc',
        out     => 'doc',
    },
    'Modwheel::Install::bin'         => {
        in      => 'bin',
        out     => 'bin',
        type    => 'bin',
    },
    'Modwheel::Install::skel::Config' => {
        in      => 'skel/config',
        out     => 'config',
    },
    'Modwheel::Install::skel::Repository' => {
        in      => 'skel/Repository',
        out     => 'Repository',
        type    => 'rep',
    },
);


#------------------------------------------------------------------------
# ->strap_it( )
#
# Create Installer classes for all components out of the %STRAP hash.
# Also create the main installer: Modwheel::Install::Everything.
#
# Modwheel/Install/Everything.pm is the module used by 'modstrap install'
# to install Modwheel run-time files.
#------------------------------------------------------------------------
sub strap_it {
    my ($self) = @_;

    my @everything;
    while (my ($class, $arg_ref) = each %STRAP) {
        push @everything,
            inc::M::InstallerBuilder->create($arg_ref->{in}, $arg_ref->{out}, $class, $arg_ref->{type});
    }

    my $out;
    $out .= <<"END"
package $OUTCLASS;
use strict;

__PACKAGE__->main( ) if not caller && caller ne 'PAR';

END
;

    # Use all generated modules..
    for my $class (@everything) {
        $out .= "use $class;\n";
    }

    # Create the subroutines...
    $out .= <<'END'

sub install {
    my ($opt_force) = @_;
END
;
    for my $class (@everything) {
        $out .= "\t$class->write_files( \$opt_force );\n";
    }
    $out .= <<"END"
}

sub install_force {
    install(1);
}

sub main {
    install( );
    exit 0;
}

1;

END
;


    my $class_final = inc::M::InstallerBuilder::class_to_class_path($OUTCLASS);
    inc::M::InstallerBuilder::writefile($class_final, $out);
    print {*STDERR} "* Created installation main $OUTCLASS -> $class_final\n";

    return;
}

1;
__END__

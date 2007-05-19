# $Id: InstallerBuilder.pm,v 1.3 2007/05/18 23:42:33 ask Exp $
# $Source: /opt/CVS/Modwheel/inc/M/InstallerBuilder.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.3 $
# $Date: 2007/05/18 23:42:33 $
package inc::M::InstallerBuilder;
use strict;
use warnings;
use Carp;
use FindBin;
use File::Spec;
use DirHandle;
use FileHandle;
use English qw( -no_match_vars );
our $VERSION = 1.0;

use constant LICENSE   => 'LICENSE'; ## no critic

#------------------------------------------------------------------------
# ->create($in_path, $out_path, $class, $type)
#
# Create a self-contained installer module.
#
# Arguments:
#
#   $in_path    -> Path to take files from. (cwd will be prefixed if relative)
#   $out_path   -> Path generated module should install files to. (Relative to Modwheel prefix)
#   $class      -> Name of the installer class to be generated.
#   $type       -> If type is 'bin' the files will be made executable after installation.
#
# Example:
#   inc::M::InstallerBuilder->create('Localized', 'Localized', 'Modwheel::Installer::Localized');
#------------------------------------------------------------------------
sub create {
    my ($self, $in_path, $out_path, $class, $type) = @_;
    $type ||= q{file};

    my $bin = $FindBin::Bin;

    my $license_file = File::Spec->catfile($bin, LICENSE);

    if (! File::Spec->file_name_is_absolute($in_path)) {
        $in_path = File::Spec->catdir($bin, $in_path);
    }
    my $in_dfh = DirHandle->new($in_path);
    my $out;

    $out .= qq{ package $class;\n };
    $out .= qq{ our \$OUTDIR = '$out_path'; \n };
    $out .= qq{ our \$TYPE   = '$type';     \n };
    $out .= file_code( );
    $out .= q{'magic true value';}   . "\n";
    $out .= start_data_section( );
    $out .= '__' . LICENSE . '__'    . "\n";;
    $out .= encode_base64(slurp_file($license_file));

    FILE:
    while(my $filename = $in_dfh->read) {
         last FILE if not defined $filename;
        my $filepath = File::Spec->catfile($in_path, $filename);
        next FILE if not -f $filepath;

        my $file_fh = FileHandle->new( );
        open  $file_fh, '<', $filepath or die "Couldn't open  $filename: $OS_ERROR\n";
        $out .= print_file($file_fh, $filename, $filepath);
        close $file_fh            or die "Couldn't close $filename: $OS_ERROR\n";
    }

    my $class_final = class_to_class_path($class);
    writefile($class_final, $out);
    print {*STDERR} "* Created installation class $class -> $class_final\n";


    return $class;

}

#------------------------------------------------------------------------
# ->class_to_class_path($class)
#
# Creates a directory out of a class name.
# On unix the class X/Y/Z will create the directory blib/lib/X/Y
# and this function will return blib/lib/X/Y/Z.pm
#------------------------------------------------------------------------
sub class_to_class_path {
    my ($class) = @_;
    my $class_file = $class . q{.pm};
    my @class_path = split m/::/xms, $class_file;
    my $class_path = File::Spec->catfile(@class_path);
    my $class_basename = File::Basename::basename($class_path);
    my $class_dir      = File::Basename::dirname($class_path);
       $class_dir      = File::Spec->catdir('blib', 'lib', $class_dir);
    my $class_final    = File::Spec->catfile($class_dir, $class_basename);
    mkdir_recursive($class_dir);
    return wantarray ? ($class_final, $class_dir)
                     : $class_final;
}

#------------------------------------------------------------------------
# ->writefile($filename, $contents)
#
# Write contents to filename.
#------------------------------------------------------------------------
sub writefile {
    my ($filename, $contents) = @_;
    open my $out_fh, '>', $filename
        or die "Can't open file $filename for writing: $OS_ERROR\n";
    print {$out_fh} $contents;
    close $out_fh
        or die "Couldn't close file $filename after writing: $OS_ERROR\n";
    return;
}

#------------------------------------------------------------------------
# ->start_data_section( )
#
# Returns a string with a perl __DATA__ section start.
#------------------------------------------------------------------------
sub start_data_section {
    return '__DATA__' . "\n\n";
}

#------------------------------------------------------------------------
# ->print_file($file_fh, $filename, $filepath)
#
# Return the base64 encoded contents of $file_fh.
#------------------------------------------------------------------------
sub print_file {
    my ($file_fh, $filename, $filepath) = @_;
    my $out;
    my $contents = slurp_filefh($file_fh);
    $out = "__${filename}__\n";
    $out .= encode_base64($contents);
    return $out;
}

#------------------------------------------------------------------------
# ->slurp_filefh($file_fh)
#
# Slurp the contents of a file handle.
#------------------------------------------------------------------------
sub slurp_filefh {
    my ($file_fh) = @_;
    return do { local $/; <$file_fh> }; ## no critic
}

#------------------------------------------------------------------------
# ->slurp_file($filename)
#
# Slurp the contents of a file by file path.
#------------------------------------------------------------------------
sub slurp_file {
    my ($filename) = @_;
    my $file_fh = FileHandle->new( );
    open $file_fh, '<', $filename
        or croak "Couldn't open $filename: $OS_ERROR\n";
    my $contents = do { local $/; <$file_fh> }; ## no critic;
    close $file_fh
        or croak "Couldn't close $filename: $OS_ERROR\n";
    return $contents;
}

#------------------------------------------------------------------------
# ->mkdir_recursive($dir)
#
# Create directory recursively.
#------------------------------------------------------------------------
sub mkdir_recursive {
    my ($dir) = @_;
    my @path_components = File::Spec->splitdir($dir);
    my @done_so_far;
    for my $path_component (@path_components) {
        my $path = File::Spec->catdir(@done_so_far, $path_component);
        if (! -d $path) {
            mkdir $path;
        }
        push @done_so_far, $path_component;
    }
    return;
}

#------------------------------------------------------------------------
# ->encode_base64($string, $eol)
#
# encode_base64 and decode_base64 is copyright Gisle Aas
# and is taken directly from MIME::Base64::Perl.
#
# See the documentation for MIME::Base64::Perl on search.cpan.org
# for more information.
#------------------------------------------------------------------------
sub encode_base64 {
    if ($] >= 5.006) { ## no critic
    require bytes;
    if (bytes::length($_[0]) > length($_[0]) ||
        ($] >= 5.008 && $_[0] =~ /[^\0-\xFF]/)) { ## no critic
            require Carp;
            Carp::croak('The Base64 encoding is only defined for bytes');
        }
    }

    use integer;

    my $eol = $_[1];
    if (not defined $eol) {
        $eol = "\n";
    }

    my $res = pack q{u}, $_[0];
    # Remove first character of each line, remove newlines
    $res =~ s/^.//mg; ## no critic;
    $res =~ s/\n//g; ## no critic;

    $res =~ tr|` -_|AA-Za-z0-9+/|;               # `# help emacs
    # fix padding at the end
    my $padding = (3 - length($_[0]) % 3) % 3;
    $res =~ s/.{$padding}$/'=' x $padding/e if $padding; ## no critic
    # break encoded string into lines of no more than 76 characters each
    if (length $eol) {
    $res =~ s/(.{1,76})/$1$eol/xmsg;
    }
    return $res;
}

#------------------------------------------------------------------------
# ::file_code( )
#
# Returns the code to be contained in the installer module.
# (not including __DATA__ section).
#------------------------------------------------------------------------
sub file_code {
    my $file_code = <<'__END_OF_THE_WORLD__'
use strict;
use Carp;
use File::Spec;
require 5.00800;
our $VERSION = 1.0;
__PACKAGE__->main( ) if not caller || caller eq 'PAR';
{
    my %cache_data;
    sub get_file {
        my ($self, $filename) = @_;
    
        if (defined $filename && $cache_data{$filename}) {
            return decode_base64($cache_data{$filename});
        }

        my $in_file;
        while (my $line = <DATA>) {
            my $pure = $line;
            chomp $pure;
            if ($pure =~ m/^ __(.+)__ $/xms) {
                $in_file = $1;
            }
            else {
                if ($in_file) {
                    $cache_data{$in_file} .= $line;
                }
            }
        }

        if (defined $filename && $cache_data{$filename}) {
            return decode_base64($cache_data{$filename});
        }

        return;

    }

    sub files {
        my ($self) = @_;

        if (! scalar keys %cache_data) {
            get_file(undef);
        }

        return keys %cache_data;
    }

    sub write_files {
        my ($self, $opt_force) = @_;

        eval 'use Modwheel::BuildConfig'; ## no critic
        my $bc_class = 'Modwheel::BuildConfig';
        my $prefix = $bc_class->get_value('prefix');
        my $outdir = File::Spec->catdir($prefix, $OUTDIR);
        mkdir_recursive($outdir);
        my @files  = files( );
        my $total_files_installed = 0;

        FILE:
        for my $file (@files) {
            my $contents = get_file(undef, $file);
            my $outfile = File::Spec->catfile($outdir, $file);
            next FILE if -f $outfile && !$opt_force; 
            open my $outfh, '>', $outfile
                or croak "Couldn't open file $outfile for writing: $!\n";
            print {$outfh} $contents;
            close $outfh
                or croak "Couldn't close file $outfile after writing: $!\n";
            if ($TYPE eq 'bin') {
                chmod 0755, $outfile;
                print {*STDERR} "* Installed $OUTDIR program file $file to $outfile...\n";
            }
            else {
                print {*STDERR} "* Installed $OUTDIR file $file to $outfile...\n";
            }
            $total_files_installed++;
        }

        if (!$total_files_installed && !$Modwheel::Install::Everything::warning_printed++) {
            print {*STDERR} 'All files already exists. ' . 
                            "Nothing to install. Overwrite files with install_force\n";
        }

        return;
    }

    sub mkdir_recursive {
        my ($dir) = @_;
        my @path_components = File::Spec->splitdir($dir);
        my @done_so_far;
        for my $path_component (@path_components) {
            my $path = File::Spec->catdir(@done_so_far, $path_component);
            if (! -d $path) {
                mkdir $path;
            }
            push @done_so_far, $path_component;
        }
        return;
    }

    sub main {
        write_files( );
    }

# ###
# encode_base64 and decode_base64 is copyright Gisle Aas
sub decode_base64 {
    local($^W) = 0; # unpack("u",...) gives bogus warning in 5.00[123]
    use integer;

    my $str = shift;
    $str =~ tr|A-Za-z0-9+=/||cd;            # remove non-base64 chars
    if (length($str) % 4) {
    require Carp;
    Carp::carp("Length of base64 data not a multiple of 4")
    }
    $str =~ s/=+$//;                        # remove padding
    $str =~ tr|A-Za-z0-9+/| -_|;            # convert to uuencoded format
    return "" unless length $str;

    ## I guess this could be written as
    #return unpack("u", join('', map( chr(32 + length($_)*3/4) . $_,
    #           $str =~ /(.{1,60})/gs) ) );
    ## but I do not like that...
    my $uustr = '';
    my ($i, $l);
    $l = length($str) - 60;
    for ($i = 0; $i <= $l; $i += 60) {
    $uustr .= "M" . substr($str, $i, 60);
    }
    $str = substr($str, $i);
    # and any leftover chars
    if ($str ne "") {
    $uustr .= chr(32 + length($str)*3/4) . $str;
    }
    return unpack ("u", $uustr);
}
    
}
__END_OF_THE_WORLD__
;
    return $file_code;
}

1;
__END__

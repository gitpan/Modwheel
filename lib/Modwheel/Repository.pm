# $Id: Repository.pm,v 1.5 2007/04/27 10:57:38 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/Repository.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.5 $
# $Date: 2007/04/27 10:57:38 $
#####
package Modwheel::Repository;
use strict;
use warnings;
use utf8;
use Class::InsideOut::Policy::Modwheel qw(:std);
use base 'Modwheel::Instance';
use version; our $VERSION = qv('0.2.2');
{

    use English      qw( -no_match_vars );
    use Scalar::Util qw( blessed );
    use Fcntl        ( );
    use FileHandle   ( );
    use File::Spec   ( );

sub get_file {
    my ($self, $parent, $bool_active_only) = @_;
    my $modwheel = $self->modwheel;
    my $db       = $self->db;
    $bool_active_only ||= 0;

    my $fetch = { parentobj => q{?}, };
    $fetch->{active} = int $bool_active_only;
    my $query = $db->build_select_q('repository',
        [qw(id name mimetype created changed path)],
        $fetch
    );

    my $sth = $db->prepare($query);
    $sth->execute($parent);

    my @repository;
    while (my $href = $db->fetchrow_hash($sth)) {
        push @repository, {
            id       => $href->{id},
            name     => $href->{name},
            mimetype => $href->{mimetype},
            created  => $href->{created},
            path     => $href->{path},
        };
    }
    $db->query_end($sth);

    return \@repository
}

sub uri_for_id {
    my ($self, $id) = @_;
    my $modwheel    = $self->modwheel;
    my $db          = $self->db;
    return if not defined $id;

    my $query = $db->build_select_q('repository',
        [ qw(name parentobj) ],
        [ 'id' ]
    );
    my $entry = $db->fetchonerow_hash($query, $id);
    my $uri   = join q{/}, ($modwheel->siteconfig->{repositoryurl},
                            $entry->{parentobj},
                            $entry->{name}
    );
    
    return $uri;
}

sub _check_filename {
    my ($self, $filename, $bool_rel) = @_;
    return if not defined $filename;

    if ($bool_rel) {
        return $filename =~ m/^
([\s\w\d\.\-\(\)\_\+\#\,\&\[\]\=\:\'\~\*\!\"\>\<\^\%\`]+)   $/xms ? $filename : 0;
    }
    else {
        return $filename =~ m/^
([\/\s\w\d\.\-\(\)\_\+\#\,\&\[\]\=\:\'\~\*\!\"\>\<\^\%\`]+) $/xms ? $filename : 0;
    }
}

sub upload_file {
    my ($self, $infh, %argv) = @_;
    my $modwheel = $self->modwheel;
    my $db = $self->db;

    foreach my $required_argument (qw(filename mimetype parent)) {
        if (! $argv{$required_argument}) {
            $modwheel->throw('repository-upload-missing-argument');
            $modwheel->logerror(
                'Repository upload: Missing argument:',
                $required_argument
            );
            return;
        }
    }

    if ($argv{parent} !~ m/^\d+$/xms) {
        $modwheel->throw('repository-upload-parent-id-not-digit');
        return $modwheel->logerror('Repository upload: Parent for upload must be a digit.');
    }

    # untaint user input:    
    my $filename   = $self->check_filename($argv{filename}, 1);
    return if not $filename;
    my ($parent)   = $argv{parent}   =~ m/^(\d+)$/xms;
    return if not $parent;

    my $repository = $modwheel->siteconfig->{repository};
    my $dir        = File::Spec->catdir($repository, $parent);
    my $filepath   = File::Spec->catfile($dir, $filename);
    if (! -d $dir) {
        if (! mkdir $dir, oct 755) {
            $modwheel->throw('repository-upload-mkdir-error');
            return $modwheel->logerror(
                "Repository upload: Couldn't create directory '$dir':",
                $OS_ERROR,
            );
        }
    }

    my $outfh = $self->safeopen($filepath, Fcntl::O_WRONLY|Fcntl::O_CREAT);
    return if not $outfh;
    binmode $outfh;
    while (<$infh>) {
        print {$outfh} $_;
    }

    my $id        = $db->fetch_next_id('repository');
    my $timestamp = $db->current_timestamp;
    my $query     = $db->build_insert_q('repository', {
        active      => qw{%d},
        changed     => qw{'%s'},
        created     => qw{'%s'},
        id          => qw{%d},
        mimetype    => qw{'%s'},
        name        => qw{'%s'},
        parentobj   => qw{%d},
        path        => qw{%s},
    });
    $db->exec_query($query, 1, $timestamp, $timestamp, $id,
        $argv{mimetype}, $filename, $parent, $filepath
    );

    return $id;
}

sub delete_file {
    my ($self, $id) = @_;
    my $modwheel = $self->modwheel;
    my $db       = $self->db;
    return if not defined $id;

    my $getpathq = $db->build_select_q('repository',
        ['path'], ['id']
    );
    my $path     = $db->fetch_singlevar($getpathq, $id);

    if (-f $path) {
        if (! unlink $path) {
            $modwheel->throw('repository-could-not-delete-file');
            $modwheel->logerror(
                'Repository Delete: Could not delete file',
                "(rep id: $id, filepath: $path):",
                $OS_ERROR,
            );
            return;
        }
    }

    my $deleteq = $db->build_delete_q('repository', ['id']);
    if (! $db->exec_query($deleteq, $id)) {
        $modwheel->throw('repository-could-not-delete-entry');
        $modwheel->logerror("Couldn't delete repository id $id: ", $db->errstr);
        return;
    }
    else {
        return 1;
    }
}

sub safeopen {
    my ($self, $fname, $flags) = @_;
    return if not defined $fname;
    my $fh = new FileHandle;
    my ($fdev, $fino, $hdev, $hino);


    # Untaint.
    my $filename = $self->_check_filename($fname, 0);
    # Clean up bogus bits.
    $flags &= (
        Fcntl::O_RDONLY | Fcntl::O_WRONLY | Fcntl::O_RDWR |
        Fcntl::O_CREAT  | Fcntl::O_APPEND | Fcntl::O_TRUNC
    );

    if ($filename =~ m/(\.\.|\||;)/xms) {
        $self->modwheel->throw('repository-open-file-shell-escape');
        $self->modwheel->logerror('User tries to shell escape or get parent directory!');
        $self->modwheel->logerror('SHELL ESCAPE POISONING ATTEMPT!');
        return;
    }

    if (-f $filename) {
        ($fdev, $fino) = stat $filename;
        if (! $fdev || ! $fino) {
            $self->modwheel->throw('repository-open-can-not-stat');
            $self->modwheel->logerror("Couldn't stat file $filename: $OS_ERROR");
            return;
        }
    }


    if (! sysopen $fh, $filename, $flags) {
        $self->modwheel->logerror("Couldn't open $filename: $flags: $OS_ERROR");
        return;
    }

    if (-f $filename and $hdev and $hino) {
        ($hdev, $hino) = stat $fh;
        if (! $hdev || ! $hino) {
            $self->modwheel->throw('repository-open-can-not-stat');
            $self->modwheel->logerror(
                "Couldn't stat filehandle for $filename:",
                $OS_ERROR,
            );
            return;
        }
        if (! ($fdev == $hdev) || ($fino == $hino)) {
            $self->modwheel->throw('repository-open-race-condition');
            $self->modwheel->logerror(
                'POSSIBLE RACE ATTEMP. STAT DOES NOT MATCH FOR FILE',
                "$filename: ($fdev|$hdev, $fino|$hino)"
            );
            return;
        }
    }

    return $fh;
}

}

1;

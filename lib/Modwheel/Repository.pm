# $Id: Repository.pm,v 1.11 2007/05/19 13:02:50 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/Repository.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.11 $
# $Date: 2007/05/19 13:02:50 $
#####
package Modwheel::Repository;
use strict;
use warnings;
use utf8;
use Class::InsideOut::Policy::Modwheel qw(:std);
use base 'Modwheel::Instance';
use version; our $VERSION = qv('0.3.3');
{

    use English      qw( -no_match_vars );
    use Scalar::Util qw( blessed );
    use Fcntl        ();
    use FileHandle   ();
    use File::Spec   ();

    sub get_file {
        my ($self, $parent, $bool_active_only) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;
        $bool_active_only ||= 0;

        my $fetch = { parentobj => q{?}, };
        $fetch->{active} = int $bool_active_only;
        my $query = $db->build_select_q('repository',
            [qw(id name mimetype created changed path)],$fetch);

        my $sth = $db->prepare($query);
        $sth->execute($parent);

        my @repository;
        while (my $href = $db->fetchrow_hash($sth)) {
            push @repository,
                {
                id       => $href->{id},
                name     => $href->{name},
                mimetype => $href->{mimetype},
                created  => $href->{created},
                path     => $href->{path},
                };
        }
        $db->query_end($sth);

        return \@repository;
    }

    sub uri_for_id {
        my ($self, $id) = @_;
        my $modwheel    = $self->modwheel;
        my $db          = $self->db;
        return if not defined $id;

        my $query
            = $db->build_select_q('repository',[qw(name parentobj)],['id']);
        my $entry = $db->fetchonerow_hash($query, $id);
        my $uri   = join q{/},
            (
            $modwheel->siteconfig->{repositoryurl},
            $entry->{parentobj},$entry->{name}
            );

        return $uri;
    }

    sub _check_filename {
        my ($self, $filename, $bool_rel) = @_;
        return if not defined $filename;

        if ($bool_rel) {
            return $filename =~ m/^
([\s\w\d\.\-\(\)\_\+\#\,\&\[\]\=\:\'\~\*\!\"\>\<\^\%\`]+)   $/xms
                ? $filename
                : 0;
        }
        else {
            return $filename =~ m/^
([\/\s\w\d\.\-\(\)\_\+\#\,\&\[\]\=\:\'\~\*\!\"\>\<\^\%\`]+) $/xms
                ? $filename
                : 0;
        }
    }

    sub upload_file {
        my ($self, $infh, %argv) = @_;
        my $modwheel = $self->modwheel;
        my $db = $self->db;

        foreach my $required_argument (qw(filename mimetype parent)) {
            if (!$argv{$required_argument}) {
                return $modwheel->throw('repository-upload-missing-argument',
                    $required_argument);
            }
        }

        if ($argv{parent} !~ m/^\d+$/xms) {
            return $modwheel->throw('repository-upload-parent-id-not-digit');
        }

        # untaint user input:
        my $filename   = $self->check_filename($argv{filename}, 1);
        return if not $filename;
        my ($parent)   = $argv{parent}   =~ m/^(\d+)$/xms;
        return if not $parent;

        my $repository = $modwheel->siteconfig->{repository};
        my $dir        = File::Spec->catdir($repository, $parent);
        my $filepath   = File::Spec->catfile($dir, $filename);
        if (!-d $dir) {
            if (!mkdir $dir, oct 755) {
                return $modwheel->throw('repository-upload-mkdir-error',
                    $dir, $OS_ERROR);
            }
        }

        my $outfh
            = $self->safeopen($filepath, Fcntl::O_WRONLY|Fcntl::O_CREAT);
        return if not $outfh;
        binmode $outfh;
        while (<$infh>) {
            print {$outfh} $_;
        }

        my $id        = $db->fetch_next_id('repository');
        my $timestamp = $db->current_timestamp;
        my $query     = $db->build_insert_q(
            'repository',
            {   active      => qw{%d},
                changed     => qw{'%s'},
                created     => qw{'%s'},
                id          => qw{%d},
                mimetype    => qw{'%s'},
                name        => qw{'%s'},
                parentobj   => qw{%d},
                path        => qw{%s},
            }
        );
        $db->exec_query(
            $query, 1, $timestamp,
            $timestamp, $id,$argv{mimetype},
            $filename, $parent, $filepath
        );

        return $id;
    }

    sub delete_file {
        my ($self, $id) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;
        return if not defined $id;

        my $getpathq = $db->build_select_q('repository',['path'], ['id']);
        my $path     = $db->fetch_singlevar($getpathq, $id);

        if (-f $path) {
            if (!unlink $path) {
                return $modwheel->throw('repository-could-not-delete-file',
                    $id, $path, $OS_ERROR);
            }
        }

        my $deleteq = $db->build_delete_q('repository', ['id']);
        if (!$db->exec_query($deleteq, $id)) {
            return $modwheel->throw('repository-could-not-delete-entry',
                $id, $db->errstr);
        }
        else {
            return 1;
        }
    }

    sub safeopen {
        my ($self, $fname, $flags) = @_;
        my $modwheel = $self->modwheel;
        return if not defined $fname;
        my $fh = new FileHandle;
        my ($fdev, $fino, $hdev, $hino);

        # Untaint.
        my $filename = $self->_check_filename($fname, 0);

        # Clean up bogus bits.
        $flags &= (
            Fcntl::O_RDONLY | Fcntl::O_WRONLY | Fcntl::O_RDWR |Fcntl::O_CREAT
                | Fcntl::O_APPEND | Fcntl::O_TRUNC);

        if ($filename =~ m/(\.\.|\||;)/xms) {
            $modwheel->throw('repository-open-file-shell-escape');
            $modwheel->logerror('SHELL ESCAPE POISONING ATTEMPT!');
            return;
        }

        if (-f $filename) {
            ($fdev, $fino) = stat $filename;
            if (!$fdev || !$fino) {
                return $modwheel->throw('repository-open-can-not-stat',
                    $OS_ERROR);
            }
        }

        if (!sysopen $fh, $filename, $flags) {
            return $modwheel->throw('repository-open-error',
                $filename, $flags, $OS_ERROR);
        }

        if (-f $filename && $hdev && $hino) {
            ($hdev, $hino) = stat $fh;
            if (!$hdev || !$hino) {
                return $modwheel->throw('repository-open-can-not-stat-fh',
                    $filename, $OS_ERROR);
            }
            if (!($fdev == $hdev) || ($fino == $hino)) {
                return $modwheel->throw('repository-open-race-condition',
                    $filename, $fdev, $hdev, $fino, $hino);
            }
        }

        return $fh;
    }

}

1;

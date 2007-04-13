package Modwheel::Repository;
use strict;
use warnings;
use Fcntl      ();
use FileHandle ();
our @ISA = qw(Modwheel::Instance);

sub get
{
    my ($self, $parent, $active_only) = @_;
    my $modwheel = $self->modwheel;
    my $db       = $self->db;

    my $fetch = {
        parentobj => '?',
    };
    $fetch->{active} = 1 if $active_only;
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

sub uriForId
{
    my ($self, $id) = @_;
    my $modwheel    = $self->modwheel;
    my $db          = $self->db;
    return undef unless $id;

    my $query = $db->build_select_q('repository',
        [ qw(name parentobj) ],
        { id=>'?' }
    );
    my $entry = $db->fetchonerow_hash($query, $id);
    my $uri   = $modwheel->siteconfig->{repositoryurl}. '/'. $entry->{parentobj}. '/'. $entry->{name};
    
    return $uri;
}

sub upload
{
    my ($self, $infh, %argv) = @_;
    my $modwheel = $self->modwheel;
    my $db = $self->db;

    foreach (qw(filename mimetype parent)) {
        unless ($argv{$_}) {
            $modwheel->throw('repository-upload-missing-argument');
            return $modwheel->logerror('Repository upload: Missing argument: $_');
        }
    }

    unless ($argv{parent} =~ m/^\d+$/) {
        $modwheel->throw('repository-upload-parent-id-not-digit');
        return $modwheel->logerror('Repository upload: Parent for upload must be a digit.');
    }

    # untaint user input:    
    my ($filename) = $argv{filename} =~ m/^([ \w\d\.\-\(\)\_\+\#\,]+)$/;
    return undef unless $filename;
    my ($parent)   = $argv{parent}   =~ m/^(\d+)$/;
    return undef unless $parent;

    my $repository = $modwheel->siteconfig->{repository};
    my $dir        = $repository. '/'. $parent;
    my $filepath   = $dir. '/'. $filename;
    unless (-d $dir) {
        unless (mkdir $dir, 0755) {
            $modwheel->throw('repository-upload-mkdir-error');
            return $modwheel->logerror("Repository upload: Couldn't create directory '$dir': $!");
        }
    }

    my $outfh = $self->safeopen($filepath, Fcntl::O_WRONLY|Fcntl::O_CREAT);    
    return undef unless $outfh;
    binmode $outfh;
    while (<$infh>) {
        print $outfh $_;
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
    $db->exec_query($query, 1, $timestamp, $timestamp, $id, $argv{mimetype}, $filename, $parent, $filepath);

    return $id;
}

sub delete
{
    my ($self, $id) = @_;
    my $modwheel = $self->modwheel;
    my $db       = $self->db;
    return undef unless $id;

    my $getpathq = $db->build_select_q('repository',
        [ qw(path) ], { id => '?', }
    );
    my $path     = $db->fetch_singlevar($getpathq, $id);

    if (-f $path) {
        unless (unlink($path)) {
            $modwheel->throw('repository-could-not-delete-file');
            $modwheel->logerror("Repository Delete: Couldn't delete file (rep id: $id, filepath: $path): $!");
            return undef;
        }
    }

    my $deleteq = $db->build_delete_q('repository', {
        id => '?',
    });
    unless ($db->exec_query($deleteq, $id)) {
        $modwheel->throw('repository-could-not-delete-entry');
        $modwheel->logerror("Couldn't delete repository id $id: ", $db->errstr);
        return undef;
    }
    else {
        return 1;
    }
}

sub safeopen
{
    my ($self, $fname, $flags) = @_;
    return undef unless $fname;
    my $fh = new FileHandle;
    my ($fdev, $fino, $hdev, $hino);

    my ($filename) = $fname =~  m/^([\/ \w\d\.\-\(\)\_\+\#\,]+)$/;

    # Clean up bogus bits.
    $flags &= (
        Fcntl::O_RDONLY | Fcntl::O_WRONLY | Fcntl::O_RDWR | Fcntl::O_CREAT | Fcntl::O_APPEND | Fcntl::O_TRUNC
    );

    if ($filename =~ m/(\.\.|\||;)/) {
        $self->modwheel->throw('repository-open-file-shell-escape');
        $self->modwheel->logerror('User tries to shell escape or get parent directory!');
        $self->modwheel->logerror('SHELL ESCAPE POISONING ATTEMPT!');
        return undef;
    }

    if (-f $filename) {
        unless (($fdev, $fino) = stat $filename) {
            $self->modwheel->throw('repository-open-can-not-stat');
            $self->modwheel->logerror("Couldn't stat file $filename: $!");
            return undef;
        }
    }

    unless (sysopen $fh, $filename, $flags) {
        $self->modwheel->logerror("$! ($filename)");
        return undef;
    }

    if (-f $filename and $hdev and $hino) {
        unless (($hdev, $hino) = stat $fh) {
            $self->modwheel->throw('repository-open-can-not-stat');
            $self->modwheel->logerror("Couldn't stat filehandle for $filename: $!");
            return undef;
        }
        unless (($fdev == $hdev) || ($fino == $hino)) {
            $self->modwheel->throw('repository-open-race-condition');
            $self->modwheel->logerror(
                "POSSIBLE RACE ATTEMP. STAT DOESN'T MATCH FOR FILE $filename: ($fdev|$hdev, $fino|$hino)"
            );
            return undef;
        }
    }

    return $fh;
}    

1

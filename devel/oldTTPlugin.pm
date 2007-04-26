  package Modwheel::Template::TT::Plugin;
  use base qw( Template::Plugin Modwheel::Instance );
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/Template/TT/Plugin.pm - Used by the Template Toolkit driver to create the
# functions used in templates.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
use strict;
use Modwheel::Template::TT::Object;
use Modwheel::HTML::Tagset;
use HTML::Entities;

our %cache_id_to_webpath = ();

sub new
{
    my ($class, $context, @instance) = @_;
    
    my $self = bless { }, $class;

    my ($modwheel, $user, $db, $object, $template) = @instance;
    $self->set_modwheel($modwheel);
    $self->setup_instance({
        user        => $user,
        db             => $db,
        object        => $object,
        template     => $template
    });

    my $tagset = new Modwheel::HTML::Tagset();
    $self->set_tagset($tagset);

    return $self;
}

sub tagset
{
    return $_[0]->{_TAGSET_};
}

sub set_tagset
{
    my ($self, $tagset) = @_;
    $self->{_TAGSET_}   = $tagset if ref $tagset;
}

sub striptags
{
    my ($self, $string) = @_;
    my $tagset    = $self->tagset;
    my $shortcuts = $self->template->shortcuts;

    $string = HTML::Entities::encode($string, "\200-\377");
    $string = $tagset->striptags($string) if ref $tagset;
    $string = $shortcuts->parse($string)  if ref $shortcuts;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;

    return $string;
}
sub esc
{
    my ($self, $string) = @_;
    my $tagset    = $self->tagset;
    my $shortcuts = $self->template->shortcuts;

    $string = HTML::Entities::encode($string, "\200-\377");
    $string = $tagset->parse(\$string)   if ref $tagset;
    $string = $shortcuts->parse($string) if ref $shortcuts;

    return $string;
}

sub esc1
{
    my ($self, $string) = @_;
    my $tagset = $self->tagset;

    $string =~ s/&/&amp;/g;     # &
    $string =~ s/\"/&quot;/g;   #"
    $string =~ s/\'/&#39;/g;    # '
    $string =~ s/</&lt;/g;      # <
    $string =~ s/>/&gt;/g;  
    $string =~ s/\n/<br \/>/g;
    $string = HTML::Entities::encode($string, "\200-\377");
    $string = $tagset->parse(\$string) if ref $tagset;

    return $string;
}

sub esc2
{
    my ($self, $string) = @_;
    my $shortcuts = $self->template->shortcuts;
    my $tagset    = $self->tagset; 

    $string =~ s[\n][<br />]gm;
    $string = HTML::Entities::encode($string, "\200-\377");      
    $string =~ s[(http://.+?)(\s+|$)][<a href="$1">$1</a>$2];
    $string = $tagset->parse($string)    if ref $tagset;
    $string = $shortcuts->parse($string) if ref $shortcuts;

    return $string;
}
    

sub fetchObject
{
    my ($self, $argv) = @_;
    return if not UNIVERSAL::isa($argv, 'HASH');

    my $object = $self->object;
    $object    = $object->fetch($argv);
    return if not $object;

    if (ref $object eq 'ARRAY') {
        my @objects = ( );
        foreach my $subobj (@$object) {
            $subobj->set_defaults;
            my $tkobjectwrapper = Modwheel::Template::TT::Object->new($subobj);
            push @objects, $tkobjectwrapper;
        }
        return \@objects;
    }
    else {
        $object->set_defaults;
        my $tkobjectwrapper = Modwheel::Template::TT::Object->new($object);
        return $argv->{id} ? $tkobjectwrapper
                           : [$tkobjectwrapper]
        ;
    }
}

sub fetchObjectTree
{
    my ($self, $parent) = @_;
    return if ref $parent;
    return $self->object->fetch_tree($parent);
}

sub createObject
{
    my ($self, $argv) = @_;
    return if not UNIVERSAL::isa($argv, 'HASH');

    my $object = $self->object;
    $object->set_defaults;
    while (my($key, $value) = each %$argv) {
        if ($object->can($key)) {
            $object->$key($value)
        }
    }
    my $tkobjectwrapper = Modwheel::Template::TT::Object->new($object);

    return $tkobjectwrapper;
}

sub saveObject
{
    my ($self, $tkobject) = @_;
    return if not UNIVERSAL::isa($tkobject, 'Modwheel::Template::TT::Object');

    my $object = $tkobject->object;
    return if not UNIVERSAL::isa($object, 'Modwheel::Object');

    return $object->save;
}

sub postSortDirectoriesFirst
{
    my ($self, $objects) = @_;
    return if not UNIVERSAL::isa($objects, 'ARRAY');

    my @sorted = sort { $b->type eq 'directory' } @$objects;
    undef @$objects;

    return \@sorted;
}

sub trashObject
{
    my ($self, $id) = @_;
    return if ref $id;

    return $self->object->trash($id);
}

sub emptyTrash
{
    my $self = shift;

    return $self->object->empty_trash();
}

sub createUser
{
    my ($self, $argv) = @_;
    return if not UNIVERSAL::isa($argv, 'HASH');

    return $self->user->create(%$argv);
}

sub updateUser
{
    my ($self, $argv) = @_;
    return if not UNIVERSAL::isa($argv, 'HASH');

    return $self->user->update(0, %$argv);
}

sub deleteUser
{
    my ($self, $username) = @_;
    return if ref $username;

    return $self->user->delete($username);
}
    

sub updateUserAndEncipher
{
    my ($self, $argv) = @_;
    return if not UNIVERSAL::isa($argv, 'HASH');

    return $self->user->update(1, %$argv);
}

sub nameByUid
{
    my ($self, $uid) = @_;
    return if ref $uid;

    return $self->user->namebyuid($uid);
}

sub parent
{
    return $_[0]->template->parent;
}

sub getParam
{
    my ($self, $paramname) = @_;

    my $param = $self->template->param;
    if (UNIVERSAL::isa($param, 'Apache2::Request') || UNIVERSAL::isa($param, 'Apache::Request')) {
        return $param->param($paramname);
    }
    if (UNIVERSAL::isa($param, 'HASH')) {
        return $param->{$paramname};
    }
}

sub currentUserName
{
    return $_[0]->user->uname;
}

sub getAllUsers
{
    my $self = shift;
    return $self->user->list(@_);
}

sub getUserInfo
{
    my $self = shift;
    return $self->user->get(@_);
}

sub mkpasswd
{
    my ($self, $length) = @_;
    return $self->user->mkpasswd($length);
}

sub search
{
    my ($self, $searchstr, $limit, $offset, $bool_fetch_data, $bool_active_only) = @_;
    my $db   = $self->db;
    $limit ||= 10;
    my $fetch_data = 'data,' if $bool_fetch_data;

    $searchstr = $db->sqlescape($searchstr);
    #my $query = qq{ 
    #    SELECT SQL_CALC_FOUND_ROWS distinct(name), $fetch_data type, keywords, description, created, changed, id, parent
    #    FROM object
    #    WHERE( name        LIKE('\%$searchstr\%')
    #       OR  keywords    LIKE('\%$searchstr\%')
    #       OR  description LIKE('\%$searchstr\%')
    #       OR  data        LIKE('\%$searchstr\%')
    #    )
    #    AND parent > 0
    #};
    my $query = qq{
        SELECT    SQL_CALC_FOUND_ROWS distinct(name), $fetch_data type, keywords, description, created
                                   changed, id, parent
        FROM    object
        WHERE    MATCH(name, keywords, description, data) AGAINST('$searchstr')
        AND        id > 0
    };
    $query .= ' AND active=1 '   if $bool_active_only;
    $query .= " LIMIT $limit "   if $limit;
    $query .= " OFFSET $offset " if $offset;
    my $sth = $db->prepare($query);
    $sth->execute();
    my @result;
    while (my $href = $db->fetchrow_hash($sth)) {
        push @result, {    
            id          => $href->{id},
            parent      => $href->{parent},
            name        => $href->{name},
            type        => $href->{type},
            keywords    => $href->{keywords},
            description => $href->{description},
            created     => $href->{created},
            changed     => $href->{changed},
            data        => $href->{data},
        };
    };
    $db->query_end($sth);
    my $count = $db->fetch_singlevar('SELECT FOUND_ROWS()');
    $self->lastRowCount($count);

    return \@result;
}

sub lastRowCount
{
    my ($self, $count) = @_;

    $self->{_LAST_ROW_COUNT_} = $count if $count;

    return $self->{_LAST_ROW_COUNT_};
}

# we don't want to import all of the huge POSIX module
# here, so we make our own floor/ceil functions.
sub floor
{
    my ($self, $d) = @_;
    return $d if index($d, '.') == -1;

    my $fract;
    if ($d < 0) {
        $d = -$d;
        ($d, $fract) = split('\.', $d);
        $d += 1 if $fract != 0;
        $d = -$d;
    }
    else {
        ($d) = split('\.', $d);
    }

    return $d;
}

sub ceil
{
    my ($self, $d) = @_;

    return -($self->floor( -$d )); 
}

sub arraySize
{
    my ($self, $aref) = @_;

    if (UNIVERSAL::isa($aref, 'ARRAY')) {
        return scalar @$aref;
    }
    if (UNIVERSAL::isa($aref, 'HASH')) {
        return scalar keys %$aref;
    }

    return;
}

sub abbreviate
{
    my ($self, $string, $maxsize) = @_;
    $maxsize ||= 50;

    if (length $string > $maxsize) {
        $string  = substr($string, 0, $maxsize - 3);
        $string .= '[...]';
    }

    return $string;
}

sub fetchObjectTreeString
{
    my ($self, $parent) = @_;
    return if ref $parent;

    my $treestr;
    my $tree = $self->object->fetch_tree($parent);
    foreach my $node (@$tree) {
        $treestr .= $node->{name}. '::';
    }
    chop $treestr;
    chop $treestr;

    return $treestr;
}

sub abbreviatePath
{
    my ($self, $path, $maxsize) = @_;
    $maxsize ||= 75;

    if (length $path > $maxsize) {
        my $mpos  = length($path) / 2;
        my $ccpos  = rindex $path, '::';
        my $epos   = $ccpos > -1 ? $ccpos : ($mpos + $maxsize /2);
        my $substring = substr($path, 0, $mpos);
        $substring .= '[...]';
        $substring .= substr($path, $epos, length($path));
        $path = $substring;
    }

    return $path;
}

sub getRepository
{
    my ($self, $parent, $bool_activeonly) = @_;
    my $repository = $self->template->repository;

    if (ref $repository) {
        return $repository->get($parent, $bool_activeonly);
    }

    return;
}

sub getRepositoryUrlForId
{
    my ($self, $id) = @_;    
    return if not defined $id;

    my $repository = $self->template->repository;
    if (ref $repository) {
        return $repository->uriForId($id)
    }

    return;
}

sub deleteRepositoryFile
{
    my ($self, $id) = @_;
    return if not defined $id;

    my $repository = $self->template->repository;
    if (ref $repository) {
        return $repository->delete($id);
    }

    return;
}    

sub objectPath
{
    my ($self, $id) = @_;

    my $name = $self->object->expr_by_id($id);

    return $name;
}

sub idToWebPath
{
    my ($self, $id) = @_;

    if ($cache_id_to_webpath{$id}) {
        return $cache_id_to_webpath{$id};
    }
    
    my $name;
    return '/' if $id == 1;
    $name = $self->object->expr_by_id($id);
    $name =~ s/^(.+?):://;
    $name = join '/', split('::', $name);
    $name = '/' . $name . '/';

    $cache_id_to_webpath{$id} = $name;
    
    return $name;
}

sub createTag
{
    my ($self, $tag_name) = @_;

    return $self->object->create_tag($tag_name);
}

sub deleteTag
{
    my ($self, $tag) = @_;

    return $self->object->delete_tag($tag);
}

sub connectWithTag
{
    my ($self, $tag, $objid) = @_;

    return $self->object->connect_with_tag($tag, $objid);
}

sub disconnectFromTag
{
    my ($self, $tag, $objid) = @_;

    return $self->object->disconnect_from_tag($tag, $objid);
}

sub getTagsForObject
{
    my ($self, $objid) = @_;

    my $tags = $self->object->get_tags_for_object($objid);

    return $tags if(UNIVERSAL::isa($tags, 'ARRAY') && @$tags);
}

sub getAllTags
{
    return $_[0]->object->get_all_tags;
}

sub catch
{
    my ($self, $exception) = @_;
    return $self->modwheel->catch($exception) ? 1 : 0;
}

sub catchLike
{
    my ($self, $exception) = @_;
    return $self->modwheel->catch_like($exception) ? 1 : 0;
}

1

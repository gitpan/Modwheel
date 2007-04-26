# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/Template/TT/Plugin.pm - Used by the Template Toolkit driver to create the
# functions used in templates.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# $Id: Plugin.pm,v 1.6 2007/04/25 18:49:17 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/Template/TT/Plugin.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.6 $
# $Date: 2007/04/25 18:49:17 $
#####
package Modwheel::Template::TT::Plugin;
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw(:std);
use base qw(Template::Plugin Modwheel::Instance);
use version; our $VERSION = qv('0.2.1');
{
    use Modwheel::Template::ObjectProxy;
    use Modwheel::HTML::Tagset;
    use HTML::Entities;
    use Scalar::Util qw(blessed);
    use Params::Util ('_HASH', '_ARRAY', '_CODELIKE', '_INSTANCE');
    use namespace::clean;

    #========================================================================
    #                     -- OBJECT ATTRIBUTES --
    #========================================================================
    public tagset       => my %tagset_for,       {is => 'rw'};
    public lastRowCount => my %lastRowCount_for, {is => 'rw'};

    #========================================================================
    #                     -- OBJECT CACHES --
    #========================================================================
    my %cache_id_to_webpath = ();

    #========================================================================
    #                     -- CONSTRUCTOR --
    #========================================================================
    sub new {
        my ($class, $context, @instance) = @_;

        my $self = register($class);

        my ($modwheel, $user, $db, $object, $template)= @instance;
        $self->set_modwheel($modwheel);
        $self->setup_instance(
            {   user        => $user,
                db          => $db,
                object      => $object,
                template    => $template
            }
        );

        my $tagset = Modwheel::HTML::Tagset->new();
        $self->set_tagset($tagset);

        return $self;
    }

    #========================================================================
    #                     -- PUBLIC INSTANCE METHODS --
    #========================================================================
    sub striptags {
        my ($self, $string) = @_;
        my $tagset    = $self->tagset;
        my $shortcuts = $self->template->shortcuts;

        $string = HTML::Entities::encode($string, '\200-\377');
        $string = $tagset->striptags($string);
        $string = $shortcuts->parse($string);
        $string =~ s/^ \s+  //xms;
        $string =~ s/  \s+ $//xms;

        return $string;
    }

    sub esc {
        my ($self, $string) = @_;
        my $tagset    = $self->tagset;
        my $shortcuts = $self->template->shortcuts;

        $string = HTML::Entities::encode($string, '\200-\377');
        $string = $tagset->parse(\$string);
        $string = $shortcuts->parse($string);

        return $string;
    }

    sub esc1 {
        my ($self, $string) = @_;
        my $tagset = $self->tagset;

        $string =~ s/&/&amp;/xmsg;     # &
        $string =~ s/\"/&quot;/xmsg;   #"
        $string =~ s/\'/&#39;/xmsg;    # '
        $string =~ s/</&lt;/xmsg;      # <
        $string =~ s/>/&gt;/xmsg;
        $string =~ s/\n/<br \/>/xmsg;
        $string = HTML::Entities::encode($string, '\200-\377');
        $string = $tagset->parse(\$string);

        return $string;
    }

    sub esc2 {
        my ($self, $string) = @_;
        my $shortcuts = $self->template->shortcuts;
        my $tagset    = $self->tagset;

        $string =~ s{\n}{<br />}xmsg;
        $string = HTML::Entities::encode($string, '\200-\377');
        $string =~ s{(http://.+?)(\s+|$)}{<a href="$1">$1</a>$2}xms;
        $string = $tagset->parse($string);
        $string = $shortcuts->parse($string);

        return $string;
    }

    sub fetchObject {
        my ($self, $argv) = @_;
        return if not _HASH($argv);

        my $object = $self->object;
        $object    = $object->fetch($argv);
        return if not $object;

        if (_ARRAY($object)) {
            my @objects = ();
            foreach my $subobj (@{$object}) {
                $subobj->set_defaults;
                my $proxy = Modwheel::Template::ObjectProxy->new($subobj);
                push @objects, $proxy;
            }
            return \@objects;
        }
        else {
            $object->set_defaults;
            my $proxy = Modwheel::Template::ObjectProxy->new($object);
            return $argv->{id}
                ? $proxy
                : [$proxy];
        }
    }

    sub fetchObjectTree {
        my ($self, $parent) = @_;
        return $self->object->fetch_tree($parent);
    }

    sub createObject {
        my ($self, $argv) = @_;
        return if not _HASH($argv);

        my $object = $self->object;
        $object->set_defaults;
        while (my($key, $value) = each %{$argv}) {
            my $field = 'set_' . $key;
            if ($object->can($key)) {
                $object->$field(
                    $value);
            }
        }
        my $proxy = Modwheel::Template::ObjectProxy->new($object);

        return $proxy;
    }

    sub saveObject {
        my ($self, $objectproxy) = @_;
        return
            if not _INSTANCE($objectproxy,'Modwheel::Template::ObjectProxy');

        my $object = $objectproxy->object;

        return $object->save;
    }

    sub postSortDirectoriesFirst {
        my ($self, $objects) = @_;
        return if not _ARRAY($objects);

        my @sorted
            = sort { $a->type eq 'directory' || $b->type eq 'directory' }
            @{$objects};

        return \@sorted;
    }

    sub trashObject {
        my ($self, $id) = @_;
        my $object = $self->object;

        return $object->trash($id);
    }

    sub emptyTrash {
        my ($self) = @_;
        my $object = $self->object;
        return $object->empty_trash();
    }

    sub createUser {
        my ($self, $argv) = @_;
        return if not _HASH($argv);

        my $user = $self->user;
        return $user->create($argv);
    }

    sub updateUser {
        my ($self, $argv) = @_;
        return if not _HASH($argv);

        my $user = $self->user;
        return $user->update(0, %{$argv});
    }

    sub deleteUser {
        my ($self, $username) = @_;
        my $user = $self->user;
        return $user->delete_user($username);
    }

    sub updateUserAndEncipher {
        my ($self, $argv) = @_;
        return if not _HASH($argv);

        my $user = $self->user;
        return $user->update(1, %{$argv});
    }

    sub nameByUid {
        my ($self, $uid) = @_;
        my $user = $self->user;

        return $user->namebyuid($uid);
    }

    sub parent {
        my ($self) = @_;
        my $template = $self->template;
        return $template->parent;
    }

    sub getParam {
        my ($self, $paramname) = @_;
        my $template = $self->template;

        my $param = $template->param;
        if (blessed $param) {
            return $param->param($paramname);
        }
        if (_HASH($param)) {
            return $param->{$paramname};
        }
        if (_CODELIKE($param)) {
            return $param->($paramname);
        }
    }

    sub currentUserName {
        my ($self) = @_;
        my $user = $self->user;
        return $user->uname;
    }

    sub getAllUsers {
        my $self = shift;
        my $user = $self->user;
        return $user->list(@_);
    }

    sub getUserInfo {
        my $self = shift;
        my $user = $self->user;
        return $user->get(@_);
    }

    sub mkpasswd {
        my ($self, $length) = @_;
        my $user = $self->user;
        return $user->mkpasswd($length);
    }

    sub search {
        my ($self, $searchstr, $limit, $offset, $bool_fetch_data,
            $bool_active_only)
            = @_;
        my $db   = $self->db;
        $limit ||= 10;
        my $fetch_data =
            $bool_fetch_data
            ? 'data,'
            : q{};

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
        if ($bool_active_only) {
            $query .= ' AND active=1 ';
        }
        if ($limit) {
            $query .= " LIMIT $limit ";
        }
        if ($query) {
            $query .= " OFFSET $offset ";
        }
        my $sth = $db->prepare($query);
        $sth->execute();
        my @result;
        while (my $href = $db->fetchrow_hash($sth)) {
            push @result,
                {
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
        }
        $db->query_end($sth);
        my $count = $db->fetch_singlevar('SELECT FOUND_ROWS()');
        $self->set_lastRowCount($count);

        return \@result;
    }

    # we don't want to import all of the huge POSIX module
    # here, so we make our own floor/ceil functions.
    sub floor {
        my ($self, $d) = @_;
        my $has_dot = index $d, q{.};
        return $d if $has_dot == -1;

        my $fract;
        if ($d < 0) {
            $d = -$d;
            my @temp = split m/[ . ]/xms, $d;
            ($d, $fract) = @temp;

# Perl::Critic thinks my($a, $b) = split(..) is statements separated by comma,
# so we use a temporary array to make perlcritic happy.
            if ($fract != 0) {
                $d += 1;
            }
            $d = -$d;
        }
        else {
            my @temp = split m/[ . ]/xms, $d;
            $d = $temp[0];

            # same as above.
        }

        return $d;
    }

    sub ceil {
        my ($self, $d) = @_;

        return -($self->floor( -$d ));
    }

    sub arraySize {
        my ($self, $aref) = @_;

        if (_ARRAY($aref)) {
            return scalar @{$aref};
        }
        if (_HASH($aref)) {
            return scalar keys %{$aref};
        }

        return;
    }

    sub abbreviate {
        my ($self, $string, $maxsize) = @_;
        $maxsize ||= 50;

        if (length $string > $maxsize) {
            $string  = substr $string, 0, $maxsize - 3;
            $string .= '[...]';
        }

        return $string;
    }

    sub fetchObjectTreeString {
        my ($self, $parent) = @_;
        my $object = $self->object;

        my $treestr;
        my $tree = $object->fetch_tree($parent);
        foreach my $node (@{$tree}) {
            $treestr .= $node->{name}. q{::};
        }
        chop $treestr;
        chop $treestr;

        return $treestr;
    }

    sub abbreviatePath {
        my ($self, $path, $maxsize) = @_;
        $maxsize ||= 75;

        my $path_len = length $path;

        if (length $path > $maxsize) {
            my $mpos  = $path_len / 2;
            my $ccpos  = rindex $path, q{::};
            my $epos   = $ccpos > -1 ? $ccpos : ($mpos + $maxsize /2);
            my $substring = substr $path, 0, $mpos;
            $substring .= '[...]';
            $substring .= substr $path, $epos, $path_len;
            $path = $substring;
        }

        return $path;
    }

    sub getRepository {
        my ($self, $parent, $bool_activeonly) = @_;
        my $template   = $self->template;
        my $repository = $template->repository;

        if (blessed $repository) {
            return $repository->get_file($parent, $bool_activeonly);
        }

        return;
    }

    sub getRepositoryUrlForId {
        my ($self, $id) = @_;
        my $template   = $self->template;
        my $repository = $template->repository;
        return if not defined $id;

        if (blessed $repository) {
            return $repository->uri_for_id(
                $id);
        }

        return;
    }

    sub deleteRepositoryFile {
        my ($self, $id) = @_;
        my $template   = $self->template;
        my $repository = $template->repository;
        return if not defined $id;

        if (blessed $repository) {
            return $repository->delete_file($id);
        }

        return;
    }

    sub objectPath {
        my ($self, $id) = @_;
        my $object = $self->object;

        my $name = $object->expr_by_id($id);

        return $name;
    }

    sub idToWebPath {
        my ($self, $id) = @_;
        my $object = $self->object;

        if ($cache_id_to_webpath{$id}) {
            return $cache_id_to_webpath{$id};
        }

        my $name;
        return q{/} if $id == 1;
        $name = $object->expr_by_id($id);
        $name =~ s/^ (.+?) :: //xms;
        $name = join q{/}, (split m/::/xms, $name);
        $name = q{/} . $name . q{/};

        $cache_id_to_webpath{$id} = $name;

        return $name;
    }

    sub createTag {
        my ($self, $tag_name) = @_;
        my $object = $self->object;

        return $object->create_tag($tag_name);
    }

    sub deleteTag {
        my ($self, $tag) = @_;
        my $object = $self->object;

        return $object->delete_tag($tag);
    }

    sub connectWithTag {
        my ($self, $tag, $objid) = @_;
        my $object = $self->object;

        return $object->connect_with_tag($tag, $objid);
    }

    sub disconnectFromTag {
        my ($self, $tag, $objid) = @_;
        my $object = $self->object;

        return $object->disconnect_from_tag($tag, $objid);
    }

    sub getTagsForObject {
        my ($self, $objid) = @_;
        my $object = $self->object;

        my $tags = $object->get_tags_for_object($objid);

        if (_ARRAY($tags)  && @{$tags}) {
            return $tags;
        }

        return;
    }

    sub getAllTags {
        my ($self) = @_;
        my $object = $self->object;
        return $object->get_all_tags;
    }

    sub catch {
        my ($self, $exception) = @_;
        my $modwheel = $self->modwheel;
        return $modwheel->catch($exception) ? 1 : 0;
    }

    sub catchLike {
        my ($self, $exception_regexp) = @_;
        my $modwheel = $self->modwheel;
        return $modwheel->catch_like($exception_regexp) ? 1 : 0;
    }

    sub getAllPrototypes {
        my ($self) = @_;
        my $object = $self->object;
        return $object->get_all_prototypes();
    }

    sub createPrototype {
        my ($self, $arg_ref) = @_;
        my $object = $self->object;

        my $type = delete $arg_ref->{type};
        return if not defined $type;
        return $object->create_prototype($type, $arg_ref);
    }

    sub removePrototypeForType {
        my ($self, $type) = @_;
        my $object = $self->object;
        return if not defined $type;
        return $object->remove_prototype_for_type($type);
    }

    sub getPrototypeForType {
        my ($self, $type) = @_;
        my $object = $self->object;
        return if not defined $type;
        return $object->get_prototype_for_type($type);
    }

}

1;

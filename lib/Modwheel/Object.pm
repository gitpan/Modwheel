package Modwheel::Object;
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/Object.pm - Work with Modwheel-objects.
# Modwheel-objects are abstract representation of data. 
# (c) 2007 Ask Solem Hoel <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####
use Class::Struct;
use Data::Dumper;
use Carp;
use strict;

# ########################################
# Dictonary entry for Object :
#
# 1. A focus of attention, feeling, thought, or action: an object of contempt.
# 2. The purpose, aim, or goal of a specific action or effort: the object of the game.
# 3. Grammar:
#    a. A noun, pronoun, or noun phrase that receives or is affected by the action of a verb within a sentence.
#    b. A noun or substantive governed by a preposition.
# 4. Philosophy: Something intelligible or perceptible by the mind.
# 5. Computer Science: A discrete item that can be selected and maneuvered, such as an onscreen graphic.
#   In object-oriented programming, objects include data and the procedures necessary to operate on that data.

sub MW_TREE_ROOT        {  1   }; # Root node of the tree.
sub MW_TREE_TRASH       { -1   }; # ID of the Trashbin.
sub MW_TREE_NOPARENT    { -10  }; # Maintainance script moves objects with no parent here (XXX: Not Yet Implemented)
sub ITERATE_TAGS_MAX    { 1000 }; # Maximum number of tags get_all_tags can return.

our %methods = (
    modwheel    => '$',            # Modwheel instance objects.
    user        => '$',
    db          => '$',

    id          => '$',            # Object ID.
    parent      => '$',            # ID of object parent.
    active      => '$',            # Is this object active? (1/0)
    created     => '$',            # When was this object created?
    changed     => '$',            # When was this object changed?
    owner       => '$',            # User ID of object owner.
    groupo      => '$',            # ID of the group this object belong to.
    revised_by  => '$',            # The laster user (ID) that changed this object.
    "sort"      => '$',            # Sort priority.
    template    => '$',            # Path to the object's template.
    type        => '$',            # The objects type.
    name        => '$',            # The object name (or title).
    description => '$',            # Description of the object. (Could be used for things like article synopsis).
    keywords    => '$',            # Keywords related to this object.
    data        => '$',            # The main data associated with this object. (Could be an article, a uniform resource locator ++).
    detach      => '$',            # Detach this object from the tree? (1/0)
    degree      => '$',            # Number of nodes directly below this node.
);

struct('Modwheel::Object' => [ %methods ]);

# ### Object structure.
# This defines the  structure of the object database table.
# It is mostly used in database queries.
our %objstruct = (
    id          =>  qw{%d},
    parent      =>  qw{%d},
    active      =>  qw{%d},
    created     =>  qw{'%s'},
    changed     =>  qw{'%s'},
    owner       =>  qw{%d},
    keywords    =>  qw{'%s'},
    groupo      =>  qw{%d},
    revised_by  =>  qw{%d},
    "sort"      =>  qw{%d},
    template    =>  qw{'%s'},
    type        =>  qw{'%s'},
    name        =>  qw{'%s'},
    description =>  qw{'%s'},
    data        =>  qw{'%s'},
    detach      =>  qw{%d},
);

sub setup_instance
{
    my ($self, %argv) = @_;
    $self->modwheel( $argv{modwheel} );
    $self->user( $argv{user} );
    $self->db( $argv{db} );
}

# ### XXX: Object permissions not yet implemented.
# ### XXX: Move the db functionality into the db class.
sub check_object_privs { return 1 }

# XXX: Now this function isn't really portable, now is it?
sub set_defaults
{
    my $self = shift;
    my $mw = $self->modwheel;
    my $db = $self->db;
    my $user = $self->user;
    my $default = $mw->config->{default};

    if (defined $default->{inherit} && $self->parent)
    {
        my $query = $db->build_select_q(
            'object',
            [qw(active owner groupo sort template)],
            {id => '?'}
        );
        my $sth = $db->prepare($query);
        $sth->execute($self->parent);
        my $values = $db->fetchrow_hash($sth);
        $db->query_end($sth);

        unless (ref $values) {
            $mw->throw('object-can-not-get-parent');
            $mw->logerror("Couldn't fetch parent for object id", $self->id, "parent was", $self->parent);
            return undef;
        }

        foreach my $field (qw(active owner groupo sort template)) {
            if ($self->can($field)) {
                $self->$field( $values->{field} ) unless $self->$field;
            }
        }
    }

    unless (defined $self->detach) {
        $self->detach(0);
    }

    if (ref $user && $user->uname) {
        #$self->groupo($user->getuser_primary_group($user->uname));
        $self->revised_by($user->uid);
    }

    $self->parent( $default->{parent} ) unless $self->parent;
    $self->active( $default->{active} ) unless $self->active;
    $self->owner ( $default->{owner}  ) unless $self->owner;
    $self->groupo( $default->{groupo} ) unless $self->groupo;

    return 1;
}

sub fetch
{
    my($self, $match, $select, $options, $table) = @_;
    my $mw   = $self->modwheel;
    my $user = $self->user;
    my $db   = $self->db;

    $table  ||= 'object';
    $select ||= '*';

    # ## Build the query
    my @objects;
    my $query = $db->build_select_q($table, $select, $match, $options);

    my $sth = $db->query($query) or return undef;
    while (my $result = $db->fetchrow_hash($sth)) {
        my $new_object = Modwheel::Object->new(modwheel=>$mw, user=>$user, db=>$db);

        ### store the values
        while (my ($field, $value) = each %$result) {
            if (defined $value && $new_object->can($field)) {
                $new_object->$field($value)
            }
        }
        push @objects, $new_object;
    }
    $db->query_end($sth);

    return undef unless scalar @objects;

    if (scalar @objects == 1) {
        return $objects[0];
    }
    else {
        return \@objects;
    }
}

sub save
{
    my $self = shift;
    my $mw   = $self->modwheel;
    my $user = $self->user;
    my $db   = $self->db;

    foreach my $field (qw(name type)) {
        unless ($self->$field) {
            $mw->throw('object-save-missing-field');
            $mw->logerror("Missing required field: \u$field");
            return undef;
        }
    }

    # ## save current timestamps.
    $self->created( $db->current_timestamp ) unless $self->created;
    $self->changed( $db->current_timestamp );

    #$self->revised_by($user->uid) if defined $user->uid;

    if (defined $self->active) {
        $self->active(0) if $self->active =~ m/false | no  | off/ix;
        $self->active(1) if $self->active =~ m/true  | yes | on /ix;
    }

    unless (defined $self->detach) {
        $self->detach(0);
    }

    # XXX: EXPR_BY_ID, ID_BY_EXPR to be implemented here...

    # build the query
    my ($query, $save_mode);
    if ($self->id) {
        $query = $db->build_update_q('object', \%objstruct, {id => '?'});
        if ($self->parent == $self->id) {
            $mw->throw('object-parent-loop');
            $mw->logerror("Object can't have itself as parent.");
            return undef; 
        }
        $save_mode = 'update';
    }
    else {
        $self->owner( $user->uid ) if $user->uid;
        # the database could do this automaticly, but we like to do it anyway :-)
        # seriously: the db that can do it, can override this functionality.
        $self->id($db->fetch_next_id('object'));
        $query = $db->build_insert_q('object', \%objstruct);
        $save_mode = 'insert';
    }

    my @values;
    foreach my $attribute (sort keys %objstruct) {
        if ($self->can($attribute)) {
            push @values, $self->$attribute;
        }
    }

    my $sth;
    if ($save_mode eq 'update') {    
        $sth = $db->query($query, @values, $self->id);
    }
    else {
        $sth = $db->query($query, @values);
    }
    $db->query_end($sth);

    return $self->id;
}

sub fetch_tree
{
    my ($self, $parent) = @_;
    my $modwheel        = $self->modwheel;
    my $db              = $self->db;

    # keep track of parents we have visited, to be sure we don't
    # enter a infinite loop.
    my %seen;
    
    my @names;
    my $obj = Modwheel::Object->new(modwheel => $modwheel, db => $db, user => $self->user);
    while (defined $parent) {
        $seen{$obj->parent}++;

        $obj    = $obj->fetch({id=>$parent});

        if (ref $obj) {
            $parent = $obj->parent;
        }
        else {
            last;
        }

        if ($seen{$obj->parent}) {
            $modwheel->throw('object-parent-loop');
            $modwheel->logerror("Fetch Object Tree: Infinite loop in tree. Currently at id $parent.");
            return [ ];
        }
        push @names, {id => $obj->id, name => $obj->name};

        if ($obj->detach) {
            last unless $modwheel->siteconfig->{NeverDetach} eq 'Yes' ;
        }
    }

    undef $obj;
    @names = reverse @names;
    return \@names;
}

sub webpath_to_id
{
    my ($self, $path) = @_;
    my $db            = $self->db;

    $path   =~ s#^/##;
    $path   =~ s#/$##;
    my @dir = split '/', $path;
    my $id  = MW_TREE_ROOT;
    return $id unless @dir;

    # remember that hashes are not in order, so the values fed to execute must be sorted
    # by the name of the match field of buildq.
    my $query = $db->build_select_q('object',
        [ qw(id type active) ],
        { 'LOWER(name)' => '?', parent => '?' } 
    );
    
    my $c;
    my $left;
    my $sth = $db->prepare($query);
    foreach my $d (@dir) {
        my $lcd = lc $d;
        last unless $lcd;

        $sth->execute($lcd, $id);
        return undef unless $sth->rows;

        my $row = $sth->fetchrow_hashref;
        $id  = $row->{id};
        return undef if $row->{active} == 0;
    }
    $db->query_end($sth);

    return undef if $id == MW_TREE_ROOT;
    return wantarray ? ($id, $left)
                     : $id
    ;
}

sub expr_by_id
{
    my ($self, $id) = @_;
    my $modwheel    = $self->modwheel;
    my $db          = $self->db;

    return undef unless $id;

    # keep track of which id's we've seen, so we don't go into an infinite loop.
    my %seen; 

    my @expr = ();
    
    my $query = $db->build_select_q('object', [ qw(name  parent  type) ], { id => '?' });
    my $sth   = $db->prepare($query);
    while ($id) {
        $seen{$id}++;

        if ($seen{$id}) {
            $modwheel->throw('object-exprbyid-loop');
            $modwheel->logerror("Object: exprbyid for id $id went into an infinite loop!");
            return undef;
        }

        $sth->execute($id);

        my $hres = $db->fetchrow_hash($sth);
        if ($hres->{name}) {    
            push @expr, $hres->{name};
        }
        else {
            last;
        }

        if ($hres->{parent}) {
            $id = $hres->{parent};
        }
        else {
            last;
        }
    }
    $db->query_end($sth);

    return join('::', reverse @expr);
}

sub trash
{
    my ($self, $id) = @_;
    my $db          = $self->db;

    # set object parent to trash.
    my $query = $db->build_update_q('object', { parent => '?' }, { id => '?' });

    return $db->exec_query($query, MW_TREE_TRASH, $id);
}

sub empty_trash
{
    my $self  = shift;
    my $db    = $self->db;

    my $query = $db->build_delete_q('object', {
        parent => MW_TREE_TRASH,
    });

    $db->exec_query($query);

    return undef;
}

sub create_tag
{
    my ($self, $tag_name) = @_;
    my $modwheel          = $self->modwheel;
    my $db                = $self->db;

    unless ($tag_name) {
        $modwheel->throw('object-tag-create-missing-field');
        $modwheel->logerror('Create Tag: Missing tag name.');
        return undef;
    }

    my $itq = $db->build_insert_q('tags', {
        name => '?',
    });
    
    return $db->exec_query($itq, $tag_name);
}

sub get_tagid_by_name
{
    my ($self, $tag_name) = @_;
    my $modwheel          = $self->modwheel;
    my $db                = $self->db;

    return $tag_name if $tag_name =~ m/^\d+$/;

    my $q = $db->build_select_q('tags', 'tagid', {
        name => '?',
    });

    my $tag = $db->fetch_singlevar($q, $tag_name);

    unless ($tag) {
        $modwheel->error('Get tagid by name: No such tag.');
        return undef;
    }
    else {
        return $tag;
    }    
}

sub delete_tag
{
    my ($self, $tag) = @_;
    my $modwheel     = $self->modwheel;
    my $db           = $self->db;

    unless ($tag) {
        $modwheel->throw('object-tag-delete-missing-field');
        $modwheel->logerror('Delete Tag: Missing tag name or id.');
        return undef;
    }

    # Delete by id if the argument is a number, by name otherwise.
    my $dtq;
    if ($tag =~ m/^\d$/) {
        $dtq = $db->build_delete_q('tags', {
            tagid => '?',
        });
    }
    else {
        $dtq = $db->build_delete_q('tags', {
            name  => '?',
        });
    }

    return $db->exec_query($dtq, $tag);
}

sub connect_with_tag
{
    my ($self, $tag, $objid) = @_;
    my $modwheel             = $self->modwheel;
    my $db                   = $self->db;

    unless ($tag) {
        $modwheel->throw('object-tag-connect-missing-field');
        $modwheel->logerror('Connect Object With Tag: Missing tag name or id.');
        return undef;
    }

    # if the tag is not a number, try to get the id by the name.
    $tag = $self->get_tagid_by_name($tag) unless $tag =~ m/^\d+$/;
    unless ($tag) {
        $modwheel->throw('object-tag-no-such-tag');
        $modwheel->logerror('Connect Object With Tag: No tag with name', $tag);
        return undef;
    }

    $objid = $self->id unless $objid;
    unless ($objid) {
        $modwheel->throw('object-tag-connect-missing-field');
        $modwheel->logerror('Connect Object With Tag: Missing object id.');
        return undef;
    }

    my $q = $db->build_insert_q('objtagmap', {
        objid => '?', tagid => '?',
    });
    
    return $db->exec_query($q, $objid, $tag);
}

sub disconnect_from_tag
{
    my ($self, $tag, $objid) = @_;
    my $modwheel             = $self->modwheel;
    my $db                   = $self->db;

    unless ($tag) {
        $modwheel->throw('object-tag-disconnect-missing-field');
        $modwheel->logerror('Disconnect Object From Tag: Missing tag name or id.');
        return undef;
    }

    # if the tag is not a number, try to get the id by the name.
    $tag = $self->get_tagid_by_name($tag) unless $tag =~ m/^\d+$/;
    unless ($tag) {
        $modwheel->throw('object-tag-no-such-tag');
        $modwheel->logerror('Disconnect Object From Tag: No tag with name', $tag);
        return undef;
    }

    $objid = $self->id unless $objid;
    unless ($objid) {
        $modwheel->throw('object-tag-disconnect-missing-field');
        $modwheel->logerror('Disconnect Object From Tag: Missing object id.');
        return undef;
    }

    my $q = $db->build_delete_q('objtagmap', {
        objid => '?', tagid => '?',
    });
    
    return $db->exec_query($q, $objid, $tag);
}

sub get_all_tags
{
    my $self = shift;
    my $db   = $self->db;

    my $q = $db->build_select_q('tags',
        ['tagid', 'name'], {}, {limit => ITERATE_TAGS_MAX(), order => 'name'}
    );

    my @tags;
    my $sth = $db->prepare($q) or return undef;
    $sth->execute();
    if ($sth->rows) {
        while (my $hres = $db->fetchrow_hash($sth)) {
            push(@tags, { id => $hres->{tagid}, name => $hres->{name} });
        }
    }
    $db->query_end($sth);
    
    return \@tags
}

sub get_tags_for_object
{
    my ($self, $objid) = @_;
    my $modwheel       = $self->modwheel;
    my $db             = $self->db;

    $objid = $self->id unless $objid;
    unless ($objid) {
        $modwheel->throw('object-tags-missing-field');
        $modwheel->logerror('Get Tags For Object: Missing object id.');
        return undef;
    }
        
    my $q = $db->build_select_q (
        { objtagmap => 'm' ,  tags     => 't'       },
        ['DISTINCT(t.name)', 't.tagid'              ],
        {'m.objid'  => '?' , 't.tagid' => 'm.tagid' }
    );

    my @tags;
    my $sth = $db->prepare($q);
    $sth->execute($objid);
    if ($sth->rows) {
        while (my $hres = $db->fetchrow_hash($sth)) {
            push(@tags, { id => $hres->{tagid}, name => $hres->{name} });
        }
    }
    $db->query_end($sth);
        
    return \@tags;    
}

sub get_all_children
{
    my ($self, $id, $handlers, $get_ref, $max_levels) = @_;
    my $db = $self->db;
    
    $get_ref     ||= [ qw(id name type) ];
    my $query      = $db->build_select_q('object', $get_ref, {
        parent => '?'}
    );
    
    my $result     = $db->prepare($query);
    my $cur_levels = 0;
    
    my ($handler_init, $handler, $handler_end);
    if (UNIVERSAL::isa($handlers, 'HASH')) {
        $handler_init = $handlers->{init};
        $handler      = $handlers->{handler};
        $handler_end  = $handlers->{end};    
    }
    
    # run initalization handler.
    $handler_init->(@_) if UNIVERSAL::isa($handler_init, 'CODE');
    
    my @stream    = ($id);
    my @out       = ();
    
    STREAM:
    while (my $atom = shift @stream)
    {
        next STREAM unless $atom;
        $cur_levels++;
        # have we exceeded the max limit?
        if ($max_levels && $cur_levels >= $max_levels) {
            $self->modwheel->throw('object-stream-max');
            $self->modwheel->logerror('Object get all children: Max levels exceeded.');
            return [];
        }

        $result->bind_param(1, $atom);
        $result->execute;
        while (my $hres = $db->fetchrow_hash($result)) {
            if ($hres->{type} eq 'directory') {
                push @stream, $hres->{id};
            }
            if (UNIVERSAL::isa($handler, 'CODE')) {
                my $ret = $handler->($self, $hres->{id}, $hres, $cur_levels);
                push @out, $ret if $ret;
            }
            else {
                push @out, $hres->{id};
            }
        }
        $db->query_end($result);

        $cur_levels--;
        redo STREAM
    }
        
    if (UNIVERSAL::isa($handler_end, 'CODE')) {
        return $handler_end->($self, \@out);
    }
    else {
        return \@out;
    }
}
1

# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/Object.pm - Work with Modwheel-objects.
# Modwheel-objects are abstract representation of data.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# $Id: Object.pm,v 1.13 2007/05/19 13:02:50 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/Object.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.13 $
# $Date: 2007/05/19 13:02:50 $
#####
package Modwheel::Object;
use strict;
use warnings;
use version; our $VERSION = qv('0.3.3');
use base 'Modwheel::Instance';
use Class::InsideOut::Policy::Modwheel qw(:std);
{
    use Carp qw(carp croak confess cluck);
    use Params::Util ('_HASH', '_ARRAY', '_CODELIKE', '_INSTANCE');
    use Readonly;
    use Data::Dumper;
    use Scalar::Util qw(blessed weaken);
    use Perl6::Export::Attrs;
    use Digest::SHA1;
    use JSON::Syck;
    use namespace::clean;

    # #####################
    # MW_TREE_ROOT      Root node of the tree.
    # MW_TREE_TRASH     ID of the Trashbin
    # MW_TREE_NOPARENT  Maintaince moves objects with no parent here.
    # ITERATE_TAGS_MAX  Maximum number of tags.
    sub MW_TREE_ROOT     : Export       {
        return  1;
    }

    sub MW_TREE_TRASH    : Export       {
        return -1;
    }

    sub MW_TREE_NOPARENT : Export       {
        return -10;
    }

    sub ITERATE_TAGS_MAX : Export       {
        return  1000;
    }

    Readonly my @INHERIT_FROM_PARENT=> qw(active owner sort template);
    Readonly my @PROTOTYPE_FIELDS=>
        qw(data description id keywords name type);

    #========================================================================
    #                       -- OBJECT ATTRIBUTES --
    #========================================================================

    Readonly our %attributes => (
        id          => q{$},  # Object ID.
        parent      => q{$},  # ID of object parent.
        active      => q{$},  # Is this object active? (1/0)
        created     => q{$},  # When was this object created?
        changed     => q{$},  # When was this object changed?
        owner       => q{$},  # User ID of object owner.
        groupo      => q{$},  # ID of the group this object belong to.
        revised_by  => q{$},  # The laster user (ID) that changed this object.
        'sort'      => q{$},  # Sort priority.
        karma       => q{$},
        template    => q{$},  # Path to the object's template.
        type        => q{$},  # The objects type.
        name        => q{$},  # The object name (or title).
        description => q{$},  # Description of the object.
        keywords    => q{$},  # Keywords related to this object.
        data        => q{$},  # The main data associated with this object.
        detach      => q{$},  # Detach this object from the tree? (1/0)
        degree      => q{$},  # Number of nodes directly below this node.
    );

    public id           => my %id_for,          {is => 'rw'};
    public parent       => my %parent_for,      {is => 'rw'};
    public active       => my %active_for,      {is => 'rw'};
    public created      => my %created_for,     {is => 'rw'};
    public changed      => my %changed_for,     {is => 'rw'};
    public owner        => my %owner_for,       {is => 'rw'};
    public groupo       => my %groupo_for,      {is => 'rw'};
    public revised_by   => my %revised_by_for,  {is => 'rw'};
    public 'sort'       => my %sort_for,        {is => 'rw'};
    public template     => my %template_for,    {is => 'rw'};
    public type         => my %type_for,        {is => 'rw'};
    public name         => my %name_for,        {is => 'rw'};
    public description  => my %description_for, {is => 'rw'};
    public keywords     => my %keywords_for,    {is => 'rw'};
    public data         => my %data_for,        {is => 'rw'};
    public detach       => my %detach_for,      {is => 'rw'};
    public karma        => my %karma_for,       {is => 'rw'};
    public degree       => my %degree_for,      {is => 'rw'};

    # ### Object structure.
    # This defines the  structure of the object database table.
    # It is mostly used in database queries.
    Readonly my %objstruct => (
        id          =>  q{%d},
        parent      =>  q{%d},
        active      =>  q{%d},
        created     =>  q{'%s'},
        changed     =>  q{'%s'},
        owner       =>  q{%d},
        keywords    =>  q{'%s'},
        groupo      =>  q{%d},
        revised_by  =>  q{%d},
        'sort'      =>  q{%d},
        template    =>  q{'%s'},
        type        =>  q{'%s'},
        name        =>  q{'%s'},
        description =>  q{'%s'},
        data        =>  q{'%s'},
        detach      =>  q{%d},
        karma       =>  q{%d},
    );

    #========================================================================
    #                     -- PUBLIC INSTANCE METHODS --
    #========================================================================

    #------------------------------------------------------------------------
    # ->set_defaults( )
    #
    #------------------------------------------------------------------------ 
    sub set_defaults {
        my ($self)  = @_;
        my $mw      = $self->modwheel;
        my $db      = $self->db;
        my $user    = $self->user;
        my $default = $mw->config->{default};

        if (!$parent_for{ident $self}) {
            $parent_for{ident $self} = $default->{parent};
        }

        if ($db->connected && $default->{inherit} && $parent_for{ident $self}) {
            my $inherit_query
                = $db->build_select_q('object',[@INHERIT_FROM_PARENT],
                [qw(id)]);
            my $sth    = $db->prepare($inherit_query);
            $sth->execute($self->parent);
            my $inherited_values = $db->fetchrow_hash($sth);
            $db->query_end($sth);

            foreach my $field (@INHERIT_FROM_PARENT) {
                my $set_field = 'set_' . $field;
                if (ref $inherited_values && defined $inherited_values->{$field}) {
                    if ($self->can($set_field) && !defined $self->$field) {
                        $self->$set_field( $inherited_values->{$field} );
                    }
                }
            }
        }

        if (blessed $user && $user->uname) {
            $revised_by_for{ident $self} = $user->uid;
            $owner_for{ident $self}      = $user->uid;
        }

        if (!defined $detach_for{ident $self}) {
            $detach_for{ident $self} = $default->{detach};
        }
        if (!defined $active_for{ident $self}) {
            $active_for{ident $self} = $default->{active};
        }
        if (!defined $owner_for{ident $self}) {
            $owner_for{ ident $self} = $default->{owner};
        }
        if (!defined $groupo_for{ident $self}) {
            $groupo_for{ident $self} = $default->{groupo};
        }
        if (!defined $detach_for{ident $self}) {
            $detach_for{ident $self} = 0;
        }
        if (!defined $active_for{ident $self}) {
            $active_for{ident $self} = 1;
        }

        return 1;
    }

    #------------------------------------------------------------------------ 
    # ->fetch(\%match, \@select, \%options, $table)
    #------------------------------------------------------------------------ 
    sub fetch {
        my($self, $match, $select, $options, $table) = @_;
        my $mw   = $self->modwheel;
        my $user = $self->user;
        my $db   = $self->db;

        $table  ||= 'object';
        $select ||= q{*};

        # ## Build the query
        my @objects;
        my $query = $db->build_select_q($table, $select, $match, $options);

        my $sth = $db->query($query);
        while (my $result = $db->fetchrow_hash($sth)) {
            my $new_object = Modwheel::Object->new(
                {   modwheel    => $mw,
                    user        => $user,
                    db          => $db,
                }
            );

            ### store the values
            while (my ($field, $value) = each %{$result}) {
                my $set_field = 'set_' . $field;
                if (defined $value && $new_object->can($set_field)) {
                    $new_object->$set_field(
                        $value);
                }
            }
            push @objects, $new_object;
        }
        $db->query_end($sth);

        return if not scalar @objects;

        return scalar @objects == 1
            ? $objects[0]
            : \@objects;
    }

    #------------------------------------------------------------------------ 
    # > _find_bool_value($string)
    #------------------------------------------------------------------------ 
    sub _find_bool_value {
        my ($string) = @_;
        return if !defined $string;

        return 0 if $string eq '0';
        return 1 if $string eq '1';

        if ($string =~ m/false | no  | off/xmsi) {
            return 0;
        }
        if ($string =~ m/true  | yes | on /xmsi) {
            return 1;
        }

        # Any true number is also True.
        if ($string =~ m/^\d+$/xms) {
            return 1;
        }

        if ($string eq 'Inf') {
            return 1;
        }

        return;
    }

    #------------------------------------------------------------------------ 
    # ->save( )
    #------------------------------------------------------------------------ 
    sub save {
        my ($self) = @_;
        my $mw     = $self->modwheel;
        my $user   = $self->user;
        my $db     = $self->db;

        foreach my $field (qw(name type parent)) {
            if (!$self->$field) {
                return $mw->throw('object-save-missing-field', uc $field);
            }
        }

        # ## save current timestamps.
        if (!$self->created) {
            $self->set_created( $db->current_timestamp );
        }
        $self->set_changed( $db->current_timestamp );

        #$self->set_revised_by($user->uid) if defined $user->uid;

        $self->set_active( _find_bool_value( $self->active ) );

        if (!defined $self->detach) {
            $self->set_detach(0);
        }
        if (!defined $self->active) {
            $self->set_active(1);
        }

        # build the query
        my ($query, $save_mode);
        if ($self->id) {
            $query = $db->build_update_q('object', \%objstruct, ['id']);
            if ($self->parent == $self->id) {
                return $mw->throw('object-save-parent-loop');
            }
            $save_mode = 'update';
        }
        else { # If this is a new object.
            # The object is owned by the user that is currently logged in.
            if ($user->uid) {
                $self->set_owner( $user->uid );
            }

     # the database could do this automaticly, but we like to do it anyway :-)
     # seriously: the db that can do it, can override this functionality.
            $self->set_id($db->fetch_next_id('object'));
            $query = $db->build_insert_q('object', \%objstruct);
            $save_mode = 'insert';
        }

        my @values;
        foreach my $attribute (sort keys %objstruct) {
            push @values, $self->$attribute;
        }

        my $sth =
              $save_mode eq 'update'
            ? $db->query($query, @values, $self->id)
            : $db->query($query, @values);
        $db->query_end($sth);

        return $self->id;
    }

    #------------------------------------------------------------------------ 
    # ->fetch_tree($id)
    #------------------------------------------------------------------------ 
    sub fetch_tree {
        my ($self, $parent) = @_;
        my $modwheel        = $self->modwheel;
        my $db              = $self->db;

        # keep track of parents we have visited, to be sure we don't
        # enter a infinite loop.
        my %seen  = ();

        # This is the list of names we return.
        my @names = ();

        # If the NeverDetach option is set, we don't stop
        my $opt_never_detach = _find_bool_value(
            $modwheel->siteconfig->{NeverDetach});

        NODE:
        while (defined $parent) {
            if ( $seen{$parent}++ ) {
                return $modwheel->throw('object-tree-parent-loop', $parent);
            }

            my $node = $self->fetch({ id => $parent} );

            $parent =
                blessed $node
                ? $node->parent
                : last NODE;

            push @names,
                {
                id   => $node->id,
                name => $node->name,
                type => $node->type,
                };

            if ($node->detach && !$opt_never_detach) {
                last NODE;
            }
        }

        @names = reverse @names;
        return \@names;
    }

    #------------------------------------------------------------------------ 
    # ->path_to_id($path, $opt_path_delimiter)
    #------------------------------------------------------------------------ 
    sub path_to_id {
        my ($self, $path, $opt_path_delimiter) = @_;
        my $db           = $self->db;

        my $id  = MW_TREE_ROOT;
        return $id if not $path;

        # Default path delimiter is / (forward slash).
        my $path_delimiter   = $opt_path_delimiter
                ? quotemeta $opt_path_delimiter
                : q{/};

        # Remove leading  / (path delimiter)
        $path   =~ s{^$path_delimiter$}{}xms;

        # Remove trailing / (path delimiter)
        $path   =~ s{$path_delimiter$}{}xms;

        # split by path delimiter
        my @dir = split m{$path_delimiter}xms, $path;

# remember that hashes are not in order, so the values fed to execute must be sorted
# by the name of the match field of buildq.
        my $query = $db->build_select_q('object',[qw(id type active)],
            { 'LOWER(name)' => q{?}, parent => q{?} });

        my $c;
        my $sth = $db->prepare($query);
        DIRECTORY:
        foreach my $directory (@dir) {
            my $directory_lc = lc $directory;
            last DIRECTORY if not $directory_lc;

            $sth->execute($directory_lc, $id);
            last DIRECTORY if not $db->rows($sth);

            my $row = $sth->fetchrow_hashref;
            last DIRECTORY if $row->{active} == 0;
            $id  = $row->{id};
        }
        $db->query_end($sth);

        return $id;
    }

    #------------------------------------------------------------------------ 
    # ->expr_by_id($id, $opt_delimiter)
    #------------------------------------------------------------------------ 
    sub expr_by_id {
        my ($self, $id, $opt_delimiter) = @_;
        my $modwheel     = $self->modwheel;
        my $db           = $self->db;
        $opt_delimiter ||= q{::};

        return if not $id;

# keep track of which id's we've seen, so we don't go into an infinite loop.
        my %seen = ();
        my @expr = ();

        my $query
            = $db->build_select_q('object',[qw(name  parent  type)], ['id']);
        my $sth   = $db->prepare($query);

        NODE:
        while ($id) {

            $sth->execute($id);

            my $hres = $db->fetchrow_hash($sth);
            last NODE if !_HASH($hres);

            push @expr, $hres->{name};

            $id = $hres->{parent}
                ? $hres->{parent}
                : last NODE;

            if ( $seen{$id}++ ) {
                return $modwheel->throw('object-exprbyid-loop', $id);
            }

        }
        $db->query_end($sth);

        my $final_expression = join $opt_delimiter, reverse @expr;

        return $final_expression;
    }

    #------------------------------------------------------------------------ 
    # ->trash($id)
    #------------------------------------------------------------------------ 
    sub trash {
        my ($self, $id) = @_;
        my $db          = $self->db;

        # set object parent to trash.
        my $query = $db->build_update_q('object', ['parent'], ['id']);

        return $db->exec_query($query, MW_TREE_TRASH, $id);
    }

    #------------------------------------------------------------------------ 
    # ->empty_trash( )
    #------------------------------------------------------------------------ 
    sub empty_trash {
        my ($self) = @_;
        my $db     = $self->db;

        my $query = $db->build_delete_q('object', {parent => MW_TREE_TRASH,});

        $db->exec_query($query);

        return 1;
    }

    #------------------------------------------------------------------------ 
    # ->create_tag($tag_name)
    #------------------------------------------------------------------------ 
    sub create_tag {
        my ($self, $tag_name) = @_;
        my $modwheel          = $self->modwheel;
        my $db                = $self->db;

        if (!$tag_name) {
            return $modwheel->throw('object-tag-create-missing-name');
        }

        my $itq = $db->build_insert_q('tags', ['name']);

        return $db->exec_query($itq, $tag_name);
    }

    #------------------------------------------------------------------------ 
    # ->get_tagid_by_name($tag_name)
    #------------------------------------------------------------------------ 
    sub get_tagid_by_name {
        my ($self, $tag_name) = @_;
        my $modwheel          = $self->modwheel;
        my $db                = $self->db;

        return $tag_name if $tag_name =~ m/^\d+$/xms;

        my $q = $db->build_select_q('tags', 'tagid', ['name']);

        my $tag = $db->fetch_singlevar($q, $tag_name);

        if (!$tag) {
            return $modwheel->throw('object-no-such-tag', $tag);
        }

        return $tag;
    }

    #------------------------------------------------------------------------ 
    # ->delete_tag($tag)
    #------------------------------------------------------------------------ 
    sub delete_tag {
        my ($self, $tag) = @_;
        my $modwheel     = $self->modwheel;
        my $db           = $self->db;

        if (!$tag) {
            return $modwheel->throw('object-tag-delete-missing-field');
        }

        # Delete by id if the argument is a number, by name otherwise.
        my $tag_is_id = 0;
        if ($tag =~ m/^[\d]+$/xms) {
            $tag_is_id = 1;
        }
        my $dtq = $tag_is_id
            ? $db->build_delete_q('tags', ['tagid'])
            : $db->build_delete_q('tags', ['name']);
        
        return $db->exec_query($dtq, $tag);
    }

    #------------------------------------------------------------------------ 
    # ->connect_with_tag($tag, $object_id)
    #------------------------------------------------------------------------ 
    sub connect_with_tag {
        my ($self, $tag, $objid) = @_;
        my $modwheel             = $self->modwheel;
        my $db                   = $self->db;

        if (!$tag) {
            return $modwheel->throw('object-tag-connect-missing-field');
        }

        # if the tag is not a number, try to get the id by the name.
        if ($tag !~ m/^\d+$/xms) {
            $tag = $self->get_tagid_by_name($tag);
        }
        if (!$tag) {
            return $modwheel->throw('object-no-such-tag', $tag);
        }

        # The object id can optionally be set as an argument, else we use
        # the id in this object instance.
        if (!$objid) {
            $objid = $self->id;
        }

        # ...if we still have no object id, throw an error.
        if (!$objid) {
            return $modwheel->throw('object-tag-connect-missing-object');
        }
        my $id = $db->fetch_next_id('objtagmap');
        my $q  = $db->build_insert_q('objtagmap', [qw(id objid tagid)]);

        return $db->exec_query($q, $id, $objid, $tag);
    }

    #------------------------------------------------------------------------ 
    # ->disconnect_from_tag($tag, $object_id)
    #------------------------------------------------------------------------ 
    sub disconnect_from_tag {
        my ($self, $tag, $objid) = @_;
        my $modwheel             = $self->modwheel;
        my $db                   = $self->db;

        if (!$tag) {
            return $modwheel->throw('object-tag-disconnect-missing-field');
        }

        # if the tag is not a number, try to get the id by the name.
        if ($tag !~ m/^\d+$/xms) {
            $tag = $self->get_tagid_by_name($tag);
        }
        if (!$tag) {
            return $modwheel->throw('object-no-such-tag', $tag);
        }

        # The object id can optionally be set as an argument, if it isn't
        # get the object id from this objects instance.
        if (!$objid) {
            $objid = $self->id;
        }

        # ...if we still have no object id, throw an error.
        if (!$objid) {
            return $modwheel->throw('object-tag-disconnect-missing-object');
        }

        my $q = $db->build_delete_q('objtagmap', [qw(objid tagid)]);

        return $db->exec_query($q, $objid, $tag);
    }

    #------------------------------------------------------------------------ 
    # ->get_all_tags( )
    #------------------------------------------------------------------------ 
    sub get_all_tags {
        my ($self) = @_;
        my $db     = $self->db;

        my $q = $db->build_select_q('tags',[qw(tagid name)], {},
            {limit => ITERATE_TAGS_MAX(), order => 'name'});

        my @tags;
        my $sth = $db->prepare($q);
        $sth->execute();
        if ($db->rows($sth)) {
            while (my $hres = $db->fetchrow_hash($sth)) {
                push @tags, { id => $hres->{tagid}, name => $hres->{name} };
            }
        }
        $db->query_end($sth);

        return \@tags;
    }

    #------------------------------------------------------------------------ 
    # ->get_tags_for_object($object_id)
    #------------------------------------------------------------------------ 
    sub get_tags_for_object {
        my ($self, $objid) = @_;
        my $modwheel       = $self->modwheel;
        my $db             = $self->db;

        if (!$objid) {
            $objid = $self->id;
        }

        return $modwheel->throw('object-tags-missing-field')
            if !$objid;

        my $q = $db->build_select_q(
            { objtagmap => 'm',  tags     => 't'       },
            ['DISTINCT t.name', 't.tagid'              ],
            {'m.objid'  => q{?}, 't.tagid' => 'm.tagid' }
        );

        my @tags;
        my $sth = $db->prepare($q);
        $sth->execute($objid);
        if ($db->rows($sth)) {
            while (my $hres = $db->fetchrow_hash($sth)) {
                push @tags, { id => $hres->{tagid}, name => $hres->{name} };
            }
        }
        $db->query_end($sth);

        return \@tags;
    }

    #------------------------------------------------------------------------ 
    # ->get_prototype_for_type($type)
    #------------------------------------------------------------------------ 
    sub get_prototype_for_type {
        my ($self, $type) = @_;
        my $modwheel      = $self->modwheel;
        my $db            = $self->db;
        return $modwheel->throw('object-prototype-get-missing-field')
            if not defined $type;

        my $q
            = $db->build_select_q('prototype',[@PROTOTYPE_FIELDS], ['type']);

        my $prototype = $db->fetchonerow_hash($q, $type);

        return $prototype;
    }

    #------------------------------------------------------------------------ 
    # ->remove_prototype_for_type($type)
    #------------------------------------------------------------------------ 
    sub remove_prototype_for_type {
        my ($self, $type) = @_;
        my $modwheel      = $self->modwheel;
        my $db            = $self->db;
        return $modwheel->throw('object-prototype-remove-missing-field')
            if not defined $type;

        my $q = $db->build_delete_q('prototype', [qw(type)]);

        my $ret = $db->exec_query($q, $type);

        return $ret
            ? 1
            : 0;
    }

    #------------------------------------------------------------------------ 
    # ->create_prototype($type, {name => '..', keywords => '..', [...]})
    #------------------------------------------------------------------------ 
    sub create_prototype {
        my ($self, $type, $arg_ref) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;

        # We need a type to create.
        return $modwheel->throw('object-create_prototype-missing_type')
            if not $type;

        # Check for duplicate.
        if ($self->get_prototype_for_type($type)) {
            return $modwheel->throw('object-create_prototype-already_exists', $type);
        }

        # Get next ID available.
        my $new_proto_id = $db->fetch_next_id('prototype');

        # Create the INSERT query.
        my $q = $db->build_insert_q('prototype',
            [qw(id type name keywords description data)]);

        # Execute the query, with bind variables.
        my $ret = $db->exec_query($q,$new_proto_id,$type,$arg_ref->{name},
            $arg_ref->{keywords},$arg_ref->{description},
            $arg_ref->{data},);

        return $new_proto_id;
    }

    #------------------------------------------------------------------------ 
    # ->get_all_prototypes( )
    #------------------------------------------------------------------------ 
    sub get_all_prototypes {
        my ($self) = @_;
        my $db     = $self->db;

        my $q = $db->build_select_q('prototype', [@PROTOTYPE_FIELDS]);

        my @prototypes;
        my $sth = $db->prepare($q);
        $sth->execute();
        if ($db->rows($sth)) {
            while (my $hres = $db->fetchrow_hash($sth)) {
                push @prototypes,
                    {map { $_ => $hres->{$_} } @PROTOTYPE_FIELDS};
            }
        }
        $db->query_end($sth);

        return \@prototypes;
    }

    #------------------------------------------------------------------------ 
    # ->traverse(int $id, \%handlers, \@get, int $max_levels)
    #------------------------------------------------------------------------ 
    sub traverse {
        my ($self, $id, $handlers, $get_ref, $max_levels) = @_;
        my $db = $self->db;

        $get_ref     ||= [qw(id name type)];
        my $query
            = $db->build_select_q('object', $get_ref, [qw(parent)]);

        my $result     = $db->prepare($query);
        my $cur_levels = 0;

        my ($handler_init, $handler, $handler_end);
        if (_HASH($handlers)) {
            $handler_init = $handlers->{init};
            $handler      = $handlers->{handler};
            $handler_end  = $handlers->{end};
        }

        # run initalization handler.
        if (_CODELIKE($handler_init)) {
            $handler_init->(@_);
        }

        my @stream       = ($id);
        my @out          = ();
        my $has_exceeded = 0;

        STREAM:
        while (my $atom = shift @stream){
            next STREAM if !$atom;

            # have we exceeded the max limit?
            if ($max_levels && $cur_levels++ >= $max_levels) {
                $has_exceeded = 1;
                $self->modwheel->throw('object-stream-max-depth');
                if (_CODELIKE($handler_end)) {
                    return $handler_end->($self, \@out, $cur_levels, $has_exceeded);
                }
                return;
            }

            $result->bind_param(1, $atom);
            $result->execute;
            while (my $hres = $db->fetchrow_hash($result)) {
                if ($hres->{type} && $hres->{type} eq 'directory') {
                    push @stream, $hres->{id};
                }
                else {
                    push @stream, $hres->{id};
                }

                if (_CODELIKE($handler)) {
                    my $ret
                        = $handler->($self, $hres->{id}, $hres, $cur_levels);
                    push @out, $ret;
                }
                else {
                    push @out, $hres->{id};
                }
            }
            $db->query_end($result);

            $cur_levels--;
            redo STREAM;
        }

        return _CODELIKE($handler_end)
            ? $handler_end->($self, \@out, $cur_levels, $has_exceeded)
            : \@out;
    }

    #------------------------------------------------------------------------ 
    # ->serialize($the_object, \%options)
    #------------------------------------------------------------------------ 
    sub serialize {
        my ($self, $the_object, $options_ref) = @_;
        my $textual;
        my $checksum;
        $the_object          ||= $self;
        $options_ref         ||= { };
        $options_ref->{sign} ||=  1;

        if (_INSTANCE($the_object, 'Modwheel::Object')) {
            my %hash_copy_of_the_object;
            for my $attribute (keys %objstruct) {
                if ($the_object->can($attribute)) {
                    my $attribute_value = $the_object->$attribute;
                    if (defined $attribute_value) {
                        $hash_copy_of_the_object{$attribute}
                            = $attribute_value;
                    }
                }
            }
            if (_find_bool_value($options_ref->{sign})) {
                my $sum = join q{}, values %hash_copy_of_the_object;
                #print "-- SENDING SUM: $sum\n";
                $checksum = Digest::SHA1::sha1_hex($sum);
                #print "-- SENDING CHECKSUM: $checksum\n";
                $hash_copy_of_the_object{_CHECKSUM} = $checksum;
            }
                            
            $textual = JSON::Syck::Dump(\%hash_copy_of_the_object);
        }
       
        return wantarray    ? ($textual, $checksum)
                            : $textual;
    }

    #------------------------------------------------------------------------ 
    # deserialize($serialized, $target_object)
    #------------------------------------------------------------------------ 
    sub deserialize {
        my ($self, $textual, $target) = @_;
        my $modwheel = $self->modwheel;
        $target    ||= $self;

        my $freezed_ref = JSON::Syck::Load($textual);
        return $modwheel->throw('object-deserialize-parse-error')
            if !_HASH($freezed_ref);

        # Verify checksum.
        my $checksum = delete $freezed_ref->{_CHECKSUM};
        #print "-- INCOMING CHECKSUM: $checksum\n";
        my $sum      = join q{}, values %{ $freezed_ref };
        #print "-- THIS SUM: $sum\n\n";
        my $verify   = Digest::SHA1::sha1_hex($sum);
        #print "-- THIS CHECKSUM: $verify\n";
        #if ($checksum ne $verify) {
        #    return $modwheel->throw('object-deserialize-checksum-error');
        #}
        
        for my $attr (keys %objstruct) {
            if (defined $freezed_ref->{$attr} && $target->can($attr)) {
                my $set_attr = 'set_' . $attr;
                $target->$set_attr( $freezed_ref->{$attr} );
            }
        }

        return $target if defined wantarray;
        return;
                
    }

    #------------------------------------------------------------------------ 
    # ->diff($old_object, $new_object)
    #------------------------------------------------------------------------ 
    sub diff {
        my ($self, $old, $new) = @_;
        my $modwheel = $self->modwheel;
        
        my %diff = ( );

        ATTRIBUTE:
        while (my($attr, $data_type) = each %objstruct) {
            if ($new->can($attr)) {
                # if the old object does not implement this method, it's a
                # difference.
                if (! $old->can($attr)) {
                    $diff{$attr} = $new->$attr;
                    next ATTRIBUTE;
                }

                # Check if any of the attributes are undefined.
                # This will foremost spare us for a lot of warnings. :-)
                if (! defined $old->$attr) {
                    if (defined $new->$attr) {
                        $diff{$attr} = $new->$attr;
                    }
                    next ATTRIBUTE;
                }
                if (! defined $new->$attr) {
                    if (defined $old->$attr) {
                        $diff{$attr} = q{};
                    }
                    next ATTRIBUTE;
                }
                        
            }

            # Choose how to compare based on the type of data this attribute
            # holds.
            if ($data_type eq '%d') {
                if ($new->$attr != $old->$attr) {
                    $diff{$attr} = $new->$attr;
                }
            }
            elsif ($data_type eq q{'%s'}) {
                if ($new->$attr ne $old->$attr) {
                    $diff{$attr} = $new->$attr;
                }
            }
            else {
               $modwheel->logwarn(
                    'No datatype defined for object attribute:', $attr,
                    'Please contact a Modwheel developer.'
                );
            }
        }

        if (wantarray) {
            return %diff;
        }
        elsif (defined wantarray) {
            my $sum      = join q{}, values %diff;
            my $checksum = Digest::SHA1::sha1_hex($sum);
            $diff{_CHECKSUM} = $checksum;
            return JSON::Syck::Dump(\%diff);
        }
    }

    #------------------------------------------------------------------------ 
    # ->apply_path($diff)
    #------------------------------------------------------------------------ 
    sub apply_patch {
        my ($self, $diff) = @_;

        $self->deserialize($diff);
    
        return $self->save( );
    }


    #------------------------------------------------------------------------ 
    # ->create_revision($textual_diff, $checksum, float $version, int $approved)
    #------------------------------------------------------------------------ 
    sub create_revision {
        my ($self, $textual_diff, $checksum, $version, $approved) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;
        $approved  ||= 1;
        $version   ||= 1.0;

        return $modwheel->throw('object-revision-create-missing-checksum')
            if !$checksum;

        my $q = $db->build_insert_q('revision', [
            qw(id version approved objid checksum diff)
        ]);

        my $new_id = $db->fetch_next_id('revision');

        my $ret = $db->exec_query($q,
            $new_id,
            $version,
            $approved,
            $self->id,
            $checksum,
            $textual_diff,
        );
        
        return $new_id if $ret;
        return;
    }

}
1;

__END__

=pod


=head1 NAME

Modwheel::Object - Work with Modwheel data objects.

=head1 SYNOPSIS

    # [....]
    use Modwheel::Object;

    my $object = Modwheel::Object->new({
        modwheel => $modwheel,
        db       => $db,
        user     => $user,
    });

    # fetch all objects in the top directory.
    my @objects = $object->fetch(
        parent => Modwheel::Object::MW_CAT_TOP,
    );

    for my $child (@objects) {
        print $child->name, "\n";
    }
        

=head1 DESCRIPTION

=head1 INHERITANCE

Modwheel::Object inherits from Modwheel::Instance.

=head1 SUBROUTINES/METHODS


=head2 ATTRIBUTES


=over 4

=item C<-E<gt>id>

=item C<-E<gt>set_id(int $id)>

=item C<-E<gt>parent>

=item C<-E<gt>set_parent(int $parent)>

=item C<-E<gt>name>

=item C<-E<gt>set_name(scalar $name)>

=item C<-E<gt>type>

=item C<-E<gt>set_type(scalar $type)>

=item C<-E<gt>description>

=item C<-E<gt>set_description(scalar $description)>

=item C<-E<gt>keywords>

=item C<-E<gt>set_keywords(scalar $keywords)>

=item C<-E<gt>data>

=item C<-E<gt>set_data(scalar $data)>

=item C<-E<gt>detach>

=item C<-E<gt>set_detach(int $detach)>

=item C<-E<gt>active>

=item C<-E<gt>set_active($bool_active)>

=item C<-E<gt>created>

=item C<-E<gt>set_created(scalar $created)>

=item C<-E<gt>changed>

=item C<-E<gt>set_changed(scalar $changed)>

=item C<-E<gt>owner>

=item C<-E<gt>set_owner(int $owner)>

=item C<-E<gt>groupo>

=item C<-E<gt>set_groupo(int $groupo)>

=item C<-E<gt>revised_by>

=item C<-E<gt>set_revised_by(int $revised_by)>

=item C<-E<gt>sort>

=item C<-E<gt>set_sort(int $sort)>

=item C<-E<gt>template>

=item C<-E<gt>set_template(scalar $template)>

=back


=head2 INSTANCE METHODS


=over 4

=item C<-E<gt>set_defaults()>

=item C<-E<gt>fetch(\%match, \@select, \%options, $opt_table)>

=item C<-E<gt>save()>

=item C<-E<gt>fetch_tree($id)>

=item C<-E<gt>webpath_to_id($path)>

=item C<-E<gt>expr_by_id($id)>

=item C<-E<gt>trash($id)>

=item C<-E<gt>empty_trash()>

=item C<-E<gt>create_tag($tag_name)>

=item C<-E<gt>get_tagid_by_name($tag_name)>

=item C<-E<gt>delete_tag($tag)>

=item C<-E<gt>connect_with_tag($tag, $objid)>

=item C<-E<gt>disconnect_from_tag($tag, $objid)>

=item C<-E<gt>get_all_tags()>

=item C<-E<gt>get_tags_for_object($objid)>

=item C<-E<gt>get_prototype_for_type($type)>

=item C<-E<gt>remove_prototype_for_type($type)>

=item C<-E<gt>create_prototype($type, \%fields)>

=item C<-E<gt>get_all_prototypes()>

=item C<-E<gt>traverse($id, \%opt_handlers, \@select, int $max_levels)>

=back


=head2 PRIVATE INSTANCE METHODS


=over 4

=item C<-E<gt>_find_bool_value()>

=back

=head1 EXPORT


=over 4

=item C<MW_TREE_ROOT>

Returns the id of the root directory.

=item C<MW_TREE_TRASH>

Returns the id of the trash directory.

=item C<MW_TREE_NOPARENT>

Returns the id of the directory the maintainance script moves objects without
parent to.

=item C<ITERATE_TAGS_MAX>

Maxiumum number of tags allowed.

=back



=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES


=over 4

=item Params::Util

=item Perl6::Export::Attrs

=item Readonly

=item version

=back


=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

=over 4

=item * Modwheel::Manual

The Modwheel manual.

=item * L<http://www.0x61736b.net/Modwheel/>

The Modwheel website.

=back

=head1 VERSION

v0.3.3


=head1 AUTHOR

Ask Solem, L<< ask@0x61736b.net >>.


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 by Ask Solem L<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

# Local variables:
# vim: ts=4

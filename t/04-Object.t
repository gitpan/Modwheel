#!/usr/bin/perl

use Test::More tests => 194;
use strict;
use warnings;

BEGIN {
    use lib '/opt/devel/Modwheel/lib';
    use lib './t';
    use_ok('Modwheel::Object');
}

use Modwheel::Session;
use Modwheel::HTML::Tagset;
use Test::Modwheel qw( :boolean );
use English qw( -no_match_vars );
use Params::Util ('_HASH', '_ARRAY', '_CODELIKE', '_INSTANCE');
use Readonly;

our $THIS_BLOCK_HAS_TESTS;

Readonly my $TEST_PREFIX     => './';
Readonly my $TEST_CONFIGFILE => 't/modwheelconfig.yml';
Readonly my $TEST_SITE       => 'modwheeltest';
Readonly my $TEST_LOCALE     => 'en_EN';
Readonly my $TEST_LOGMODE    => 'off';

my $modwheel_config = {
    prefix               => $TEST_PREFIX,
    configfile           => $TEST_CONFIGFILE,
    site                 => $TEST_SITE,
    locale               => $TEST_LOCALE,
    logmode              => $TEST_LOGMODE,
};

my $test_modwheel = Test::Modwheel->new({config => $modwheel_config,});

my $DATABASE_AVAILABLE;
my $MISSING_DB_MODULE;
if ($test_modwheel->database_driver) {                                                                                                       
    $DATABASE_AVAILABLE = 1;                                                                                                                 
}

my $modwheel    = Modwheel->new($modwheel_config);
my $db;
if ($DATABASE_AVAILABLE) {
    $db         = Modwheel::DB->new({modwheel => $modwheel,});
    $MISSING_DB_MODULE = $test_modwheel->db_missing_required_module($db);
}
my $user        = Modwheel::User->new(
    {   modwheel    => $modwheel,
        db          => $db,
    }
);
my $object      = Modwheel::Object->new(
    {   modwheel    => $modwheel,
        db          => $db,
        user        => $user,
    }
);

ok( Modwheel::Object::_find_bool_value(1),       'find bool value: 1'       );
ok( Modwheel::Object::_find_bool_value('yes'),   'find bool value: yes'     );
ok( Modwheel::Object::_find_bool_value('true'),  'find bool value: true'    );
ok( Modwheel::Object::_find_bool_value('Inf'),   'find bool value: Inf'     );
ok( Modwheel::Object::_find_bool_value('on'),    'find bool value: on'      );
ok(!Modwheel::Object::_find_bool_value(0),       'find bool value: 0'       );
ok(!Modwheel::Object::_find_bool_value('no'),    'find bool value: no'      );
ok(!Modwheel::Object::_find_bool_value('false'), 'find bool value: false'   );
ok(!Modwheel::Object::_find_bool_value('off'),   'find bool value: off'     );
ok( Modwheel::Object::_find_bool_value(100),
    'find bool value: positive integer');
ok(!Modwheel::Object::_find_bool_value('The quick brown fox...'),
    'Find bool value bogus');

foreach my $method (keys %Modwheel::Object::attributes) {
    my $set_method = 'set_' . $method;
    ok( $object->can($method),     "Modwheel::Object->can: $method()"     );
    ok( $object->can($set_method), "Modwheel::Object->can: set_$method()" );
}

ok( Modwheel::Object::MW_TREE_ROOT,'Is constant MW_TREE_ROOT defined?');
ok( Modwheel::Object::MW_TREE_TRASH,'Is constant MW_TREE_TRASH defined?');
ok( Modwheel::Object::MW_TREE_NOPARENT,
    'Is constant MW_TREE_NOPARENT defined?'
);

ok( Modwheel::Object::ITERATE_TAGS_MAX,
    'Is constant ITERATE_TAGS_MAX defined?'
);

ok( $object->set_defaults, 'Set defaults without db connected' );

# ### Features that require database goes below here.
$THIS_BLOCK_HAS_TESTS = 120;
SKIP:
{
    if ( not $ENV{MODWHEEL_DBTEST} ) {
        my $msg = 'Database test.  Set $ENV{MODWHEEL_DBTEST} to a ' .
                  'true value to run. If you do: be sure to set up a TEST ' .
                  'database in the configuration files in t/*.yml and ' .
                  'to not use a live production database.';
        skip $msg, $THIS_BLOCK_HAS_TESTS;
    }
    if ($DATABASE_AVAILABLE) {                                      # TEST 9
        pass();
    }
    else {
        skip 'Database not available. This is not an error.',
            $THIS_BLOCK_HAS_TESTS;
        fail();
    }

    if ($MISSING_DB_MODULE) {
       skip "The database driver used in the test configuration "   .
            "file ($TEST_CONFIGFILE) requires the external module " .
            "$MISSING_DB_MODULE, please install via CPAN or "       .
            "change to another database driver.\n",
            $THIS_BLOCK_HAS_TESTS - 1;
    } 

    $db->connect();

    if ($db->connected) {                                           # TEST 10
        pass();
    }
    else {
        skip "Could not connect to the database. Please change the"
            ."database configuration in $TEST_CONFIGFILE to run this test.\n",
            $THIS_BLOCK_HAS_TESTS - 1;
        fail();
    }

    ok( $object->set_defaults, 'Set defaults with db connected'  );

    my $new_id = $object->save;
    ok(!$new_id, 'Object->save() must have name' );
    $object->set_name('TESTOBJ');
    $object->set_parent(Modwheel::Object::MW_TREE_NOPARENT);
    $new_id = $object->save;
    ok(!$new_id, 'Object->save() must have type' );
    $object->set_type('testobject');
    $new_id    = $object->save;
    ok(  $new_id, 'Object->save()' );

    my $root_object = $object->fetch({id => Modwheel::Object::MW_TREE_ROOT});
    ok($root_object, 'Get Root node');

    ok( $object->fetch_tree($new_id) );

    # delete stale tag
    $object->delete_tag('#TEST_TAG01#');
    ok(!$object->create_tag( ), 'create_tag bail without name' );
    ok( $object->create_tag('#TEST_TAG01#', 'create_tag') );
    ok( $object->get_tagid_by_name(1000) );
    ok(!$object->get_tagid_by_name('a/b/bb/c/c/a/a//c/c//d/d/e/e/e/ad/@$##%#%!#$@!#!@#@$%#%'));
    ok(!$object->delete_tag( ), 'delete_tag bail without tag');
    ok( $object->get_tagid_by_name('#TEST_TAG01#', 'get_tagid_by_name') );
    ok( $object->connect_with_tag('#TEST_TAG01#', $new_id, 'connect_with_tag') );
    $object->set_id($new_id);
    ok( $object->connect_with_tag('#TEST_TAG01#'),
        'connect_with_tag, using attribute id'
    );
    ok( _ARRAY($object->get_all_tags), 'get_all_tags' );
    ok( _ARRAY($object->get_tags_for_object($new_id)), 'get_tags_for_object' );
    ok( $object->disconnect_from_tag('#TEST_TAG01#', $new_id),
        'disconnect_from_tag'
    );
    ok( $object->delete_tag('#TEST_TAG01#'), 'delete_tag' );

    ok( $object->create_tag('#TEST_TAG02#') );
    my $tag2id = $object->get_tagid_by_name('#TEST_TAG02#');
    ok( $tag2id );
    ok(!$object->connect_with_tag( ), 'connect_with_tag bail without tag' );
    ok(!$object->connect_with_tag('a//x/x/s/as/we&#$#($(#E/adADASDASDASDasDASD'),
        'connect_with_tag no such tag'
    );
    ok( $object->connect_with_tag('#TEST_TAG02#') );
    ok( $object->get_tags_for_object( ) );
    ok( $object->disconnect_from_tag('#TEST_TAG02#'),
        'disconnect_from_tag using id attribute'
    );
    my $zero = Modwheel::Object->new({
        modwheel=>$modwheel, user=>$user,db=>$db
    });
    ok(!$zero->connect_with_tag($tag2id), 'connect_with_tag, bail without object id' );
    ok(!$zero->disconnect_from_tag('a/c/a/a/d/d/we*&)(#&)(&(@&($^*(@^$^T@#',
        1), 'disconnect_from_tag no such tag'
    );
    ok(!$zero->disconnect_from_tag($tag2id),
        'disconnect_from_tag, bail without object id'
    );
    ok(!$zero->disconnect_from_tag( ),
        'disconnect_from_tag, bail without tag'
    );
    ok(!$zero->get_tags_for_object( ),
        'get_tags_for_object bail without object id'
    );
   
    my $z = $object->fetch(
        { id => Modwheel::Object::MW_TREE_ROOT }, ['type'], undef, 'object'
    );


    ok( $z->type );
    ok(!$z->name );

    my $ZZ = Modwheel::Object->new({modwheel => $modwheel, db => $db});
    ok( $ZZ->set_defaults );
    
    ok( $object->delete_tag($tag2id) );
    ok(!$object->get_tagid_by_name('#TEST_TAG02#'));

    ok( $object->trash($new_id), 'trash');
    ok( $object->empty_trash(), 'empty_trash' );
    ok(!$object->fetch({id => $new_id}), 'ensure object was deleted' );

    our $global_object_count = 0;
    $object->traverse(
        Modwheel::Object::MW_TREE_ROOT(),
        {   handler => sub { $global_object_count++ }
        },
        [qw(id type name)]
    );
    ok( $global_object_count,
        "Get all children: $global_object_count objects(s) in db." );
    our $global_object_count2 = 0;
    our $global_init_exe      = 0;
    our $global_end_exe       = 0;
    $object->traverse(
        Modwheel::Object::MW_TREE_ROOT(),
        {   init    => sub { $global_init_exe = 1    },
            handler => sub { $global_object_count2++ },
            end     => sub { $global_end_exe = 1     },
        },
        [qw(id name)]
    );
    ok( $global_object_count2,
        "Get all children without type: $global_object_count objects(s) in db."
    );
    is( $global_object_count2, $global_object_count);
    ok( $global_init_exe, 'Get all children: init executed' );
    ok( $global_end_exe,  'Get all children: end  executed' );
    ok( _ARRAY( $object->traverse(Modwheel::Object::MW_TREE_ROOT) ),
        'Get all children without handler');

    ok( $object->traverse(-99999999) );
    ok( $object->traverse(0xffffffff) );

    # Test max_levels
    our $global_object_count3 = 0;
    our $global_init_executed = 0;
    our $global_end_executed  = 0;
    our $global_has_exceeded  = 0;
    $object->traverse(
        Modwheel::Object::MW_TREE_ROOT(),
        {   init            => sub { $global_init_executed = 1 },
            handler         => sub { $global_object_count3++   },
            end             => sub {
                my ($object, $out_ref, $cur_levels, $has_exceeded) = @_;
                $global_end_executed  = 1;
                $global_has_exceeded  = 1;
                return;
            },
        },
        [qw(id name)],
        1,
    );
    ok( $global_init_executed, 'Get all children: init handler' );
    ok( $global_end_executed,  'Get all children: end  handler' );
    ok( $global_has_exceeded,  'Get all children: has exceeded max levels' );

    # ####### Test Prototypes

    # Remove stail test prototypes if any.
    my @test_prototypes = ('#TESTPROTO01#');
    for my $testproto (@test_prototypes) {
        $object->remove_prototype_for_type($testproto);
    }

    # test argument input for prototype functions.
    ok(!$object->create_prototype(),
        'Not allowed to create_prototype without type');

    my $new_proto_id = $object->create_prototype(
        '#TESTPROTO01#',
        {   name        => 'Test Title',
            keywords    => 'Test Keywords',
            description => 'Test Description',
            data        => 'Test Data',
        }
    );

    ok( $new_proto_id, 'Create new prototype');

    # shouldn't be allowed to make duplicate'.
    ok( !$object->create_prototype(
            '#TESTPROTO01#',
            {   name        => 'Test Title',
                keywords    => 'Test Keywords',
                description => 'Test Description',
                data        => 'Test Data',
            }
        ),
        'Not allowed to make duplicate prototype'
    );

    ok( _ARRAY($object->get_all_prototypes), 'get_all_prototypes()' );

    ok(! $object->get_prototype_for_type( ),
        'get_prototype_for_type bail without type'
    );
    ok(! $object->remove_prototype_for_type( ),
        'remove_prototype_for_type bail without type'
    );
    ok(! $object->create_prototype( ),
        'create_prototype bail without type'
    );
    my $prototype = $object->get_prototype_for_type('#TESTPROTO01#');
    ok( UNIVERSAL::isa($prototype, 'HASH'),'Get prototype for type');
    is( $prototype->{name},         'Test Title' );
    is( $prototype->{keywords},     'Test Keywords' );
    is( $prototype->{description},   'Test Description' );
    is( $prototype->{data},         'Test Data' );

    ok( $object->remove_prototype_for_type('#TESTPROTO01#'),
        'Remove Prototype');
    ok(!$object->get_prototype_for_type('#TESTPROTO01#'),
        'Ensure prototype was removed');

    # ######## Test path_to_id
    my $owp = Modwheel::Object->new(
        {   modwheel => $modwheel,
            user     => $user,
            db       => $db,
        }
    );

    ok($owp->path_to_id('/1/2/3/4/5/6/7/8/9/1/2/3/4/5/6/7/8/9'),
        'path_to_id with nonexisting path'
    );
    ok( $owp->path_to_id( ), 'path_to_id without argument returns root id ');

    # get the root name
    my $o_root = $owp->fetch({id => Modwheel::Object::MW_TREE_ROOT });

    # ### Test Serialization.
    my $textual = $o_root->serialize;
    
    ok( $o_root->serialize );
    ok( $o_root->serialize( $o_root ) );
    ok( $o_root->serialize( $o_root, { DummyPlaceHolder => 'Bogus' } ) );
    $textual = $o_root->serialize( $o_root, { sign => 0 } );
    isnt($textual, qr/^_CHECKSUM:/xms );

    # ### Test Deserialization
    
    my $oo = Modwheel::Object->new({
        modwheel => $modwheel,
        db       => $db,
        user     => $user,
    });
    $oo->set_name('Testing Serialization');
    $oo->set_parent(1);
    $oo->set_type('testobject');
    $oo->set_description('The quick brown fox jumps over the lazy dog.');
    $oo->set_data('.god yzal eht revo spmuj xof nworb kciuq ehT');
    $textual = $oo->serialize( );
    my $oo2 = Modwheel::Object->new({
        modwheel => $modwheel,
        db       => $db,
        user     => $user,
    });
    $oo2->deserialize($textual);

    is( $oo2->name, 'Testing Serialization', 'deserialize');
    is( $oo2->parent, 1 );
    is( $oo2->type, 'testobject' );
    is( $oo2->description, 'The quick brown fox jumps over the lazy dog.' );
    is( $oo2->data, '.god yzal eht revo spmuj xof nworb kciuq ehT' );

    my $oo3 = Modwheel::Object->new({
        modwheel => $modwheel,
        db       => $db,
        user     => $user,
    });
    $oo2->deserialize($textual, $oo3);
    is( $oo3->name, 'Testing Serialization', 'deserialize');
    is( $oo3->parent, 1 );
    is( $oo3->type, 'testobject' );
    is( $oo3->description, 'The quick brown fox jumps over the lazy dog.' );
    is( $oo3->data, '.god yzal eht revo spmuj xof nworb kciuq ehT' );

    # ### Test diff
    $oo3->set_data('The data field has now changed');
    $oo3->set_description();
    $oo3->set_parent(9999);
    $oo3->set_detach(1);
    my %diff = $oo2->diff($oo2, $oo3);
    ok( scalar keys %diff, 'diff' );
    ok( exists $diff{data} );
    ok( exists $diff{parent} );
    ok( exists $diff{detach} );
    ok( exists $diff{description} );
    ok( defined $diff{data} );
    ok( defined $diff{parent} );
    ok( defined $diff{detach} );
    is($diff{description}, q{} );
    

    my $root_name = $o_root->name;

    # create a new directory under root.
    my $test_dir = Modwheel::Object->new(
        {   modwheel => $modwheel,
            user     => $user,
            db       => $db,
        }
    );
    $test_dir->set_defaults();
    my $test_dir_name = 'TestDirectory';
    $test_dir->set_name($test_dir_name);
    $test_dir->set_active(1);
    $test_dir->set_type('directory');
    my $test_dir_id = $test_dir->save;
    ok($test_dir_id);


    # Using default delimiter
    my $path  = join q{/}, $test_dir_name;
    my $wtoid = $owp->path_to_id($path);
    is($wtoid, $test_dir_id,'path_to_id( $path ) (default delimiter: "/")');

    # Using user specified delimiter
    $path  = join q{::}, $test_dir_name;
    $wtoid = $owp->path_to_id( $path, q{::} );
    is($wtoid, $test_dir_id,
        'path_to_id( $path ) (with delimiter:    "::")');

    my $we_think_expr_is = join q{::}, $root_name, $test_dir_name;
    my $expr = $owp->expr_by_id($test_dir_id);
    is($expr, $we_think_expr_is, 'expr_by_id( $id )' );

    $we_think_expr_is = join q{/}, $root_name, $test_dir_name;
    $expr = $owp->expr_by_id($test_dir_id, q{/});
    is($expr, $we_think_expr_is, 'expr_by_id( $id, $opt_delimiter )' );
    
    $test_dir->set_active( 0 );
    ok( $test_dir->save( ) );
    $path  = join q{/}, $test_dir_name;
    my $id = $owp->path_to_id($test_dir_id, q{/});
    is($id, Modwheel::Object::MW_TREE_ROOT,
        'expr_by_id bail if not active'
    );

    # ######### Fetch_tree( )
    my $test_dir_child = Modwheel::Object->new(
        {   modwheel => $modwheel,
            user     => $user,
            db       => $db,
        }
    );
    my $test_dir_child_name = 'TestDirChild';
    $test_dir_child->set_name($test_dir_child_name);
    $test_dir_child->set_parent( $test_dir->id );
    $test_dir_child->set_type('directory');
    $test_dir_child->set_active(1);
    $test_dir_child->set_detach(1);
    my $test_dir_child_id = $test_dir_child->save;

    # Test fetch for multiple objects.
    my $objects = $object->fetch({parent => Modwheel::Object::MW_TREE_ROOT,});
    ok( _ARRAY($objects), 'fetch multiple objects' );
    undef $objects;

    # ### Test with NeverDetach on
    $modwheel->siteconfig->{NeverDetach} = 1;
    my $tree = $owp->fetch_tree($test_dir_child_id);
    ok( _ARRAY($tree) );
    my $tree_expr;
    for my $node (@{$tree}) {
        $tree_expr .= $node->{name};
        $tree_expr .= q{/};
    }
    $we_think_expr_is = join q{/},
        ($o_root->name,$test_dir->name,$test_dir_child->name,q{});
    ok($we_think_expr_is);
    is( $tree_expr, $we_think_expr_is,
        'fetch_tree, detached && NeverDetach 1');

    # ### Test  with never detach off.
    $modwheel->siteconfig->{NeverDetach} = 0;
    my $dtree = $owp->fetch_tree($test_dir_child_id);
    ok( _ARRAY($tree) );
    my $dtree_expr;
    for my $node (@{$dtree}) {
        $dtree_expr .= $node->{name};
        $dtree_expr .= q{/};
    }
    $we_think_expr_is = join q{/}, ($test_dir_child->name,q{});
    ok($we_think_expr_is);
    is( $dtree_expr, $we_think_expr_is,
        'fetch_tree, detached && NeverDetach 0');

    ok( !$owp->expr_by_id( ), 'expr_by_id bail without id' );

    # ### Does fetch_tree catch infinite loops?
    my $loop_o_1 = Modwheel::Object->new(
        {   modwheel => $modwheel,
            user     => $user,
            db       => $db,
        }
    );
    my $loop_o_2 = Modwheel::Object->new(
        {   modwheel => $modwheel,
            user     => $user,
            db       => $db,
        }
    );
    $loop_o_1->set_name('TestLoopObject 01');
    $loop_o_2->set_name('TestLoopObject 02');
    $loop_o_1->set_type('directory');
    $loop_o_2->set_type('directory');
    $loop_o_1->set_parent(Modwheel::Object::MW_TREE_ROOT);
    $loop_o_2->set_parent(Modwheel::Object::MW_TREE_ROOT);
    my $loop_o_1_id = $loop_o_1->save();
    my $loop_o_2_id = $loop_o_2->save();

    # this is where we make them infinite loops
    $loop_o_1->set_parent( $loop_o_2->id );
    $loop_o_1->save();
    $loop_o_2->set_parent( $loop_o_1->id );
    $loop_o_2->save();

    ok( !$owp->fetch_tree( $loop_o_2->id ),
        'fetch_tree( ) detects infinite loops'
    );
    ok( !$owp->expr_by_id( $loop_o_2->id ),
        'expr_by_id( ) detects infinite loops'
    );

    # Clean up:
    $test_dir       = undef;
    $test_dir_child = undef;
    $loop_o_1       = undef;
    $loop_o_2       = undef;
    ok( $owp->trash($test_dir_id)       );
    ok( $owp->trash($test_dir_child_id) );
    ok( $owp->trash($loop_o_1_id)       );
    ok( $owp->trash($loop_o_2_id)       );
    ok( $owp->empty_trash() );

    # ######## Test set defaults

    # ### Inherited fields.
    my $defaults = $modwheel->config->{default};
    ok( _HASH($defaults) );
    $defaults->{inherit} = 1;
    $defaults->{active}  = 0;

    my $owp_parent = $object->fetch({id => Modwheel::Object::MW_TREE_ROOT});

    $owp = Modwheel::Object->new(
        {   modwheel => $modwheel,
            user     => $user,
            db       => $db,
        }
    );
    $owp->set_parent( $owp_parent->id );
    $owp->set_defaults;
    is( $owp->active,   $owp_parent->active,'inherited defaults: active'   );
    is( $owp->owner,    $owp_parent->owner,'inherited defaults: owner'    );
    is( $owp->sort,     $owp_parent->sort,'inherited defaults: sort'     );
    is( $owp->template, $owp_parent->template,
        'inherited defaults: template' );

    # ### Without Inherit
    $defaults->{inherit} = 0;
    $defaults->{active}  = 1;
    $owp = Modwheel::Object->new(
        {   modwheel => $modwheel,
            user     => $user,
            db       => $db,
        }
    );
    $owp->set_defaults;

    is( $owp->detach, $defaults->{detach}, 'defaults: detach' );
    is( $owp->active, $defaults->{active}, 'defaults: active' );
    is( $owp->groupo, $defaults->{groupo}, 'defaults: groupo' );
    is( $owp->owner,  $defaults->{owner},  'defaults: owner'  );
    is( $owp->parent, $defaults->{parent}, 'defaults: parent' );

    # ### Without any defaults.
    delete $defaults->{owner};
    delete $defaults->{active};
    delete $defaults->{parent};
    delete $defaults->{groupo};
    delete $defaults->{detach};
    $owp = Modwheel::Object->new(
        {   modwheel => $modwheel,
            user     => $user,
            db       => $db,
        }
    );
    ok( $owp->set_defaults );

    # ### Inherit without working parent and test inherited user.
    my $ox = Modwheel::Object->new(
        {   modwheel => $modwheel,
            user     => $user,
            db       => $db,
        }
    );
    $defaults->{inherit} = 1;
    $user->set_uname('Test');
    $user->set_uid(0xff);
    $ox->set_parent(0xffffffff);
    ok( $ox->set_defaults, 'inherit without parent'   );
    is( $ox->owner,      0xff, 'inherited user'       );
    is( $ox->revised_by, 0xff, 'inherited revised by' );

    # Set defaults without any defaults.
    undef $defaults->{inherit};
    undef $defaults->{parent};
    undef $defaults->{detach};
    undef $defaults->{active};
    undef $defaults->{groupo};
    undef $defaults->{owner};
    my $ZZZ = Modwheel::Object->new({
        modwheel => $modwheel,
        db       => $db,
        user     => $user,
    });
    ok( $ZZZ->set_defaults, 'set_defaults with _no_ defaults' );

    my $specify_defaults = Modwheel::Object->new({
        modwheel => $modwheel,
        db       => $db,
    });
    $specify_defaults->set_parent(1);
    $specify_defaults->set_detach(1);
    $specify_defaults->set_active(1);
    $specify_defaults->set_owner(1);
    $specify_defaults->set_groupo(1);
    ok( $specify_defaults->set_defaults );
    is( $specify_defaults->parent, 1 );
    is( $specify_defaults->detach, 1 );
    is( $specify_defaults->active, 1 );
    is( $specify_defaults->owner,  1 );
    is( $specify_defaults->groupo, 1 );
    

    ### Check arguments to save.
    my $savetest = Modwheel::Object->new(
        {   modwheel => $modwheel,
            user     => $user,
            db       => $db,
        }
    );
    ok(!$savetest->save, 'Do not save without name');
    $savetest->set_name('The quick brown fox...');
    ok(!$savetest->save, 'Do not save without type');
    $savetest->set_type('testobject');
    ok(!$savetest->save, 'Do not save without parent');
    $savetest->set_parent(Modwheel::Object::MW_TREE_TRASH);
    my $created = $db->current_timestamp;
    $savetest->set_changed($db->current_timestamp);
    $savetest->set_created($created);
    my $savetest_id = $savetest->save();
    ok(  $savetest_id, 'New...' );
    my $changed = $db->current_timestamp;
    $savetest->set_changed($changed);

    # Do not save when parent is itself.
    $savetest->set_parent($savetest_id);
    ok( !$savetest->save, 'Do not save if has itself as parent' );
    ok( $modwheel->catch('object-parent-loop') );
    $savetest->set_parent(Modwheel::Object::MW_TREE_ROOT);

    my $update_id = $savetest->save;
    is( $update_id, $savetest_id, 'Update...' );
    $savetest = $savetest->fetch({ id => $savetest_id});
    is($savetest->changed, $changed);

    ok( $savetest->trash( $savetest->id ) );
    ok( $savetest->empty_trash() );

    undef $owp;

    $db->disconnect() if $db->connected;
}

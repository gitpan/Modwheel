# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/Template/TT.pm - Create and init the Modwheel Template Toolkit wrapper.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# $Id: TT.pm,v 1.8 2007/04/28 13:13:05 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/Template/TT.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.8 $
# $Date: 2007/04/28 13:13:05 $
#####
package Modwheel::Template::TT;
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw(:std);
use base 'Modwheel::Instance';
use version; our $VERSION = qv('0.2.3');
{
    use Template::Stash::XS;
    use Template::Context;
    use Template::Plugin;
    use Modwheel::Template::TT::Plugin;
    use Modwheel::Template::Shortcuts;
    use URI::Escape  qw( );
    use Scalar::Util qw(blessed);
    use Params::Util ('_HASH', '_ARRAY', '_CODELIKE');
    use Carp         qw(carp croak cluck confess);

    #========================================================================
    #                     -- OBJECT ATTRIBUTES --
    #========================================================================

    public errstr      => my %errstr_for,      {is => 'rw'};
    public input       => my %input_for,       {is => 'rw'};
    public context     => my %context_for,     {is => 'rw'};
    public stash       => my %stash_for,       {is => 'rw'};
    public plugins     => my %plugins_for,     {is => 'rw'};
    public param       => my %param_for,       {is => 'rw'};
    public shortcuts   => my %shortcuts_for,   {is => 'rw'};
    public parent      => my %parent,          {is => 'rw'};
    public tkmodwheel  => my %tkmodwheel_for,  {is => 'rw'};
    public objectproxy => my %objectproxy_for, {is => 'rw'};

    sub new {
        my ($class, $arg_ref) = @_;

        my $self = $class->SUPER::new($arg_ref);

        $self->init($arg_ref);

        return $self;
    }

    #========================================================================
    #                     -- PUBLIC INSTANCE METHODS --
    #========================================================================

    #------------------------------------------------------------------------
    # ->init({ input => 'mytemplate.html', parent => 1, param => $r })
    #
    # Initialize template for processing.
    # input is the template file to process, parent is the Modwheel object
    # to process the template for, and param is a object that has a param
    # method for accessing variables (i.e Apache2::Request or CGI).
    #------------------------------------------------------------------------
    sub init {
        my ($self, $arg_ref) = @_;
        my $modwheel = $self->modwheel;
        my $user     = $self->user;
        my $db       = $self->db;
        my $object   = $self->object;

        # load user plugins from config...
        my $plugins = $self->get_user_plugins();

        # ..and always make sure to include our Modwheel plugin.
        $plugins->{Modwheel} = 'Modwheel::Template::TT::Plugin';

        # save the list of plugins for later use.
        $self->set_plugins($plugins);

        # Get compile-dir from config.
        my $tt_conf = $modwheel->siteconfig->{TT};
    
        my ($compile_dir, $interpolate, $post_chomp, $relative, $absolute);
        if (_HASH($tt_conf)) {
            $compile_dir = $tt_conf->{COMPILE_DIR};
            $interpolate = $tt_conf->{INTERPOLATE};
            $post_chomp  = $tt_conf->{POST_CHOMP};
            $relative    = $tt_conf->{RELATIVE};
            $absolute    = $tt_conf->{ABSOLUTE};
        }

        my $stash  = Template::Stash::XS->new();
        my $config = {
            INCLUDE_PATH     => $modwheel->siteconfig->{templatedir},
            INTERPOLATE      => $interpolate  || 0, # expand "$var" in plain text
            POST_CHOMP       => $post_chomp   || 1,  # cleanup whitespace
            RELATIVE         => $relative     || 1,
            ABSOLUTE         => $absolute     || 1,
            COMPILE_DIR      => $compile_dir,
            STASH            => $stash,
            PLUGINS          => $plugins,
        };

        my $context = Template::Context->new($config);
        return $self->set_errstr($Template::Context::ERROR) if not $context;

        # create and load new Modwheel::Template::TT::Plugin template toolkit
        # plugin object with our current Modwheel instance.

        # save the object as a template toolkit variable so the user
        # doesn't need to load the instance explicitly.
        if (!$arg_ref->{DontCreateInitialModwheelObject}) {
            my $tkmodwheel = $context->plugin('Modwheel',
                [$modwheel, $user, $db, $object, $self]);
            $self->set_tkmodwheel($tkmodwheel);
            $stash->set('modwheel', $tkmodwheel);
            $stash->set('mw', $tkmodwheel);

        }
        $stash->set('MODWHEEL_VERSION', $Modwheel::VERSION);

        # Param is a object handling arguments from the request.
        #   (i.e from Apache2::Request or CGI).
        # Parent is the current directory object.
        # input is the template to process..
        if ($arg_ref->{param}) {
            $self->set_param(  $arg_ref->{param}  );
        }
        if ($arg_ref->{parent}) {
            $self->set_parent( $arg_ref->{parent} );
        }
        if ($arg_ref->{input}) {
            $self->set_input(  $arg_ref->{input}  );
        }

        # save context and stash for later use.
        $self->set_context($context);
        $self->set_stash($stash);

        my $shortcuts = Modwheel::Template::Shortcuts->new({
            modwheel => $modwheel,
            template => $self
        });
        $self->set_shortcuts($shortcuts);

        return 1;
    }

    #------------------------------------------------------------------------
    # ->process(\%additional_args)
    #
    # Process the template, returning text string.
    #------------------------------------------------------------------------
    sub process {
        my ($self, $additional_args) = @_;
        my $context = $self->context;
        return $context->process($self->input, $additional_args);
    }

    #------------------------------------------------------------------------
    # ->get_user_plugins()
    #
    # Find and install plug-ins to the Template-Toolkit that the user
    # has listed in modwheelconfig.yml's TT:Plugin: sections.
    #
    # It finds plugins listed in both global and site configuration context.
    #------------------------------------------------------------------------
    sub get_user_plugins {
        my ($self)   = @_;
        my $modwheel = $self->modwheel;

        my $plugins;
        my $global_user_plugins;
        my $site_user_plugins;
        if (_HASH($modwheel->config->{global}{TT})) {
            $global_user_plugins = $modwheel->config->{global}{TT}{plugins};
        }
        if (_HASH($modwheel->siteconfig->{TT}{plugins})) {
            $site_user_plugins = $modwheel->siteconfig->{TT}{plugins};
        }

        foreach my $current_plugin_list_ref (
            ($global_user_plugins, $site_user_plugins))
        {
            if (_HASH($current_plugin_list_ref)) {
                while (my ($alias, $pconfig)
                    = each %{$current_plugin_list_ref})
                {
                    $plugins->{$alias} = $pconfig;
                }
            }
        }

        return $plugins;
    }

    #------------------------------------------------------------------------
    # ->uri_escape($uri)
    #
    # Escape unsafe characters in a string to be used in a URI.
    #------------------------------------------------------------------------
    sub uri_escape {
        my ($self, $uri) = @_;
        return URI::Escape::uri_escape($uri, '^A-Za-z0-9');
    }

};

1;
__END__

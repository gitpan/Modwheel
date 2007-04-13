package Modwheel::Template::TT;
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/Template/TT.pm - Create and init the Modwheel Template Toolkit wrapper.
# (c) 2007 Ask Solem Hoel <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####
use strict;

use Template::Stash::XS;
use Template::Context;
use Template::Plugin;
use Modwheel::Template::TT::Plugin;
use Modwheel::Template::Shortcuts;
use URI::Escape ();
our @ISA = qw(Modwheel::Instance);

sub init
{
    my ($self, %argv) = @_;
    my $modwheel = $self->modwheel;
    my $user     = $self->user;
    my $db       = $self->db;
    my $object   = $self->object;

    # load user plugins from config...
    my $plugins = $self->get_user_plugins();

    # ..and always make sure to include our Modwheel plugin.
    $plugins->{Modwheel} = 'Modwheel::Template::TT::Plugin';

    # save the list of plugins for later use.
    $self->plugins($plugins);

    my $stash = Template::Stash::XS->new();
    my $config = {
        INCLUDE_PATH     => $modwheel->siteconfig->{templatedir},
        INTERPOLATE      => 0,               # expand "$var" in plain text
        POST_CHOMP       => 1,               # cleanup whitespace
        RELATIVE         => 1,
        ABSOLUTE         => 1,
        STASH            => $stash,
        PLUGINS          => $plugins,
    };

    my $context = Template::Context->new($config);
    return $self->set_errstr($Template::Context::ERROR) unless $context;

    # create and load new Modwheel::Template::TT::Plugin template toolkit
    # plugin object with our current Modwheel instance.
    my $tkmodwheel = $context->plugin('Modwheel', [$modwheel, $user, $db, $object, $self]);
    $self->tkmodwheel($tkmodwheel);

    # save the object as a template toolkit variable so the user doesn't need to load the instance explicitly.
    unless ($argv{DontCreateInitialModwheelObject}) {
        $stash->set('modwheel', $tkmodwheel);
        $stash->set('mw', $tkmodwheel);
    }
    $stash->set('MODWHEEL_VERSION', $Modwheel::VERSION);

    # Param is a object handling arguments from the request. (i.e from Apache2::Request or CGI).
    $self->set_param( $argv{param} )    if $argv{param};
    # Parent is the current directory object.
    $self->parent( $argv{parent} )      if $argv{parent};
    # input is the template to process..
    $self->input( $argv{input} )        if $argv{input};

    # save context and stash for later use.
    $self->context($context);
    $self->stash($stash);

    my $shortcuts = Modwheel::Template::Shortcuts->new($self);
    $self->set_shortcuts($shortcuts);

    return 1;
}

# ## ACCESSORS

sub errstr
{
    return $_[0]->{_ERRSTR_}
}

sub set_errstr
{
    $_[0]->{_ERRSTR_} = $_[1];
    return undef
}

sub input
{
    my ($self, $input) = @_;
    $self->{_INPUT_}   = $input if $input;
    return $self->{_INPUT_};
}

sub context
{
    my ($self, $context)  = @_;
    $self->{_TT_CONTEXT_} = $context if ref $context;
    return $self->{_TT_CONTEXT_};
}

sub stash
{
    my ($self, $stash)  = @_;
    $self->{_TT_STASH_} = $stash if ref $stash;
    return $self->{_TT_STASH_};
}

sub plugins
{
    my ($self, $plugins)  = @_;
    $self->{_TT_PLUGINS_} = $plugins if ref $plugins;
    return $self->{_TT_PLUGINS_};
}

sub param
{
    return $_[0]->{_TEMPLATE_PARAM_};
}

sub set_param
{
    my ($self, $param) = @_;
    $self->{_TEMPLATE_PARAM_} = $param if ref $param;
}

sub shortcuts
{
    return $_[0]->{_TEMPLATE_SHORTCUTS_};
}

sub set_shortcuts
{
    my ($self, $shortcuts) = @_;
    $self->{_TEMPLATE_SHORTCUTS_} = $shortcuts if ref $shortcuts;
}

sub parent
{
    my ($self, $parent) = @_;
    $self->{_SELECTED_PARENT_OBJ_} = $parent if $parent;
    return $self->{_SELECTED_PARENT_OBJ_}
}

sub tkmodwheel
{
    my ($self, $tkmodwheel) = @_;
    $self->{_TTMODWHEEL_} = $tkmodwheel if $tkmodwheel;
    return $self->{_TTMODWHEEL_}
}

# ### METHODS

sub process
{
    my ($self, $args) = @_;
    return $self->context->process($self->input, $args);
}


sub get_user_plugins
{
    my $self     = shift;
    my $modwheel = $self->modwheel;

    my $plugins;
    my $globalUserPlugins = $modwheel->siteconfig->{TT}{plugins}{plugin};
    my $siteUserPlugins   = $modwheel->siteconfig->{TT}{plugins}{plugin};
    foreach my $currentPluginListRef ($globalUserPlugins, $siteUserPlugins) {
        if (UNIVERSAL::isa($currentPluginListRef, 'HASH')) {
            while (my($alias, $pconfig) = each %$currentPluginListRef) {
                $plugins->{$alias} = $pconfig->{class};
            }
        }
    }
    
    return $plugins;
}

sub uri_escape
{
    my ($self, $string) = @_;
    return URI::Escape::uri_escape($string, "^A-Za-z0-9");
}

1

package Modwheel;
use version; $VERSION = qv('0.2.3');

use strict;
use warnings;
use 5.00800;
use Carp;
use YAML;
use Readonly;
use POSIX   qw(  locale_h );
use English qw( -no_match_vars );
use List::MoreUtils qw( any );


# ### Default Modwheel installation directory.
Readonly my $DEFAULT_PREFIX        => '/opt/Modwheel';

# ### YAML Configuration File options
Readonly my $DEFAULT_CONFIGFILE    => 'modwheelconfig.yml';

# # Configuration Cache:
# XXX: Not yet implemented.
# The configuration cache can be of the types:
#   storable, memshare or memcopy
Readonly my $DEFAULT_CONFIG_CACHE_TYPE => 'memshare';

Readonly my $DEFAULT_LOGMODE           => 'stderr';

Readonly my %LOG_HANDLER => (
    stderr => sub {
        my ($self, $log_string) = @_;
        print STDERR $log_string, "\n";
        return;
    },
    apache => sub {
        my ($self, $log_string) = @_;
        my $apache_request = $self->apache;
        $apache_request->log_error($log_string);
        return;
    },
    off    => sub { },
);


sub new
{
    my ($class, $arg_ref) = @_;

    $arg_ref->{ logmode } ||= $DEFAULT_LOGMODE;

    my $self = { };
    bless $self, $class;
    
    # set logging mode. logmode can be 'stderr', 'apache' or 'off'.
    $self->set_logmode( $arg_ref->{logmode} );
    # if logging is set to apache, we need the request object to log trough.
    $self->set_apache( $arg_ref->{apache} )   if $arg_ref->{apache};

    if ($self->logmode eq 'apache' && ! blessed $self->apache) {
        $self->set_logmode('stderr');
        $self->logwarn("Log mode is set to Apache but Modwheel is " ,
                       "missing the apache request object. " , 
                       "If you're a user, please contact the developer of this",
                       "application. Logging will be sent to standard error",
                       "for now"
        );
    }

    if (!$arg_ref->{prefix}) {
        $self->logwarn('No prefix specified. Using internal default.
            This is probably not what you want.'
        );
    }

    $self->set_prefix(     $arg_ref->{prefix} );
    $self->set_configfile( $arg_ref->{configfile} );
    $self->set_config(     $self->parseconfig() );
    return if not ref $self->config;

    $self->set_site( $arg_ref->{site} );
    if (! ref $self->siteconfig) {
        $self->throw('modwheel-no-site-selected');
        $self->logerror('No site selected. Please configure Modwheel.');
        return;
    }

    $arg_ref->{locale}
        ?  $self->set_locale( $arg_ref->{locale} )
        :  $self->setup_locale_globally
    ;

    $self->debug( $self->config->{global}{debug} );

    return $self;
}


sub debug
{
    my ($self, $debug) = @_;
    $self->{_DEBUG_} = $debug if defined $debug;
    return $self->{_DEBUG_};    
}


sub logmode
{
    my ($self) = @_;
    return $self->{_LOGMODE_}
}


sub set_logmode
{
    my ($self, $logmode) = @_;
    $self->{_LOGMODE_} = $logmode if $logmode;
}


sub prefix
{
    my $self = shift;
    return $self->{_PREFIX_} || $DEFAULT_PREFIX;
}


sub set_prefix
{
    my ($self, $prefix) = @_;
    $self->{_PREFIX_} = $prefix if $prefix;
}


sub config
{
    my $self = shift;
    return $self->{_CONFIGREF_}
}


sub set_config
{
    my ($self, $configref) = @_;
    confess 'Configuration from YAML is not a reference.'
        if not ref $configref;
    $self->{_CONFIGREF_} = $configref;
}


sub configfile
{
    my ($self) = @_;

    return $self->{_CONFIGFILE_}    ? $self->{_CONFIGFILE_}
                                    : $DEFAULT_CONFIGFILE
    ;
}


sub set_configfile
{
    my ($self, $configfile) = @_;
    $self->{_CONFIGFILE_}   = $configfile;
}


sub configcachetype
{
    my ($self, $type) = @_;

    if (defined $type) {
        $self->{_CONFIGCACHETYPE_} = $type;
    }
    else {
        if($self->{_CONFIGCACHETYPE_}) {
            return $self->{_CONFIGCACHETYPE_}
        }
        else {
            return $DEFAULT_CONFIG_CACHE_TYPE;
        }
    }
}


sub site
{
    my ($self) = @_;
    return $self->{_SITE_} || $self->config->{global}{defaultsite};
}


sub set_site
{
    my ($self, $site) = @_;
    $self->{_SITE_}   = $site if defined $site;
}


sub siteconfig
{
    my ($self) = @_;
    my $site   = $self->site;
    return $self->config->{site}{$site};
}


sub apache
{
    my ($self) = @_;
    return $self->{_APACHE_};
}


sub set_apache
{
    my ($self, $apache) = @_;
    $self->{_APACHE_}   = $apache if ref $apache;
}


sub error
{
    my ($self, $error)  = @_;
    $self->{_STRERROR_} = $error if $error;
    return $self->{_STRERROR_};
}


sub locale
{
    my ($self) = @_;
    return $self->{_LOCALE_};
}


sub set_locale
{
    my ($self, $locale) = @_;

    if ($locale) {
        setlocale(LC_ALL, $locale);
    }

    $self->{_LOCALE_} = $locale;
}


sub setup_locale_globally
{
    my ($self) = @_;

    my $siteconfig = $self->siteconfig;
    if ($siteconfig->{locale}) {
        $self->set_locale( $siteconfig->{locale} );
    }
    elsif ($self->config->{global}{locale}) {
        $self->set_locale( $self->config->{global}{locale} );
    }

    return;
}


sub parseconfig
{
    my ($self) = @_;

    my $configfile = $self->configfile;
    if ($configfile !~ m#^/#) {
        $configfile = $self->prefix . '/' . $configfile;
    }
    if (! -f $configfile) {
        print STDERR "Fatal error: Couldn't open configuration file ",
            "('$configfile'): $OS_ERROR\n";
        return;
    }

    my $ref = YAML::LoadFile($configfile);

    return $ref;
}


sub dumpconfig
{
    my ($self) = @_;
    return YAML::Dump( [$self->config] );
}


sub logerror
{
    my ($self) = @_;
    return $self->log("Error", @_);
}


sub logwarn
{
    my ($self) = @_;
    return $self->log("Warning", @_);
}


sub loginform
{
    my ($self) = @_;
    return $self->log("Info", @_);
}

sub log
{
    my ($self, $facility, @log_strings) = @_;
    my $log_string   = join q{ }, @log_strings;
    return if !$log_string;

    if ($self->debug) {
        my ($package, $filename, $line) = caller;
        $log_string = sprintf("[%s: %s: %d]: %s: %s",
            $package, $filename, $line, $facility, $log_string
        );
    }
    else {
        $log_string = sprintf("%s: %s\n", $facility, $log_string);
    }

    $self->error($log_string) if $facility eq 'Error';

    # default mode of logging is to output to stderr.
    my $logmode = $self->logmode || 'stderr';

    # get the handler for this log mode.
    my $loghandler_ref = $LOG_HANDLER{$logmode};

    unless ($loghandler_ref) {
        print STDERR "Warning: Unknown logmode '$logmode'. Using stderr",
                     "instead.\n";
        $loghandler_ref = $LOG_HANDLER{stderr};
    }
        
    # do something with the freshly formatted log message:
    $loghandler_ref->($self, $log_string);

    return;
}


sub throw
{
    my ($self, $exception) = @_;

    if (ref $self->{_EXCEPTIONS_} eq 'array') {
        push @{ $self->{_EXCEPTIONS_} }, $exception;
    }
    else {
        $self->{_EXCEPTIONS_} = [$exception];
    }

    return;
}


sub exception
{
    my $self = shift;

    if (ref $self->{_EXCEPTIONS_} eq 'array') {
        return pop @{ $self->{_EXCEPTIONS_} }
    }

    return;
}


sub catch
{
    my ($self, $catch) = @_;
    my $exceptions = $self->{_EXCEPTIONS_};
    return 0 if ref $exceptions ne 'ARRAY';

    # catch any error.
    if (!$catch) {
        return 1 if scalar @$exceptions;
    }

    # catch the exception in $catch.    
    return 1 if any { $_ eq $catch } @$exceptions;

    return 0;
}


sub catch_like
{
    my ($self, $catch) = @_;
    my $exceptions = $self->{_EXCEPTIONS_};
    return 0 if ref $exceptions ne 'ARRAY';
   
    return 1 if any { m/$catch/xms } @$exceptions;

    return 0;
}

1;
__END__

=head1 NAME

Modwheel - Very extensible publishing-system

=head1 SYNOPSIS

    A CGI session of Modwheel can be written like this:

    use Modwheel::Session;
    use IO::Handle;
    use CGI;
    *STDOUT->autoflush( );

    my $modwheel_config = {
        prefix          => '/opt/modwheel',
        configfile      => 'modwheelcfg.yml',
        site            => 'modwheeltest',
        locale          => 'en_EN',
    };

    my ($modwheel, $db, $user, $object, $template) =
        modwheel_session($modwheel_config, qw(db user template object));

    $db->connect or exit;

    # A user-session can also be created, if there is none, the session is anonymous.
    #$user->login($username, $password);

    # The page is the page to process, it has to be in the templatedir directory.
    my $page           = shift @ARGV || 'index.html';
    my $directory_id   = $db->path_to_id($directory_path);
    $directory_id    ||= Modwheel::Object::MW_TREE_ROOT;

    my $cgi = new CGI;

    $template->init(input => $page, parent => $directory_id, param => $cgi);
    print $template->process();

    $db->disconnect;


=head1 DESCRIPTION

Modwheel is a publishing system for use with web, print, TeX, or whatever medium you have
a need to publish in. It is designed to be very extensible and will in the future have 
drop-in support for several relational databases and templating systems.

Modwheel is currently in a very early alpha development stage.

The current development version of Modwheel should work with MySQL/PostgreSQL and the TemplateToolkit,
although porting to other databases or templating systems. shouldn't be much work.


=head1 CONSTRUCTOR

=over 4

=item C<Modwheel-E<gt>new()>

Creates a new Modwheel object.

Arguments:

It requires a hash of configuration options as argument.
The configuration keys are:

    prefix         - The base Modwheel directory. (i.e /opt/modwheel)
    configfile     - Name of the configuration file. (i.e config/modwheelconfig.yml)
    logmode        - Where log messages goes. Can be stderr, apache, or off.
    site           - The site to use. Must have a corresponding site directive in the config file.
    locale         - The locale to use. (i.e en_EN)
    debug          - Turn on debugging features.    
    apache         - Apache request object, required if logmode is apache.

Returns:

A new Modwheel object if everything was OK. Returns no value if there was an error.

=back

=head1 ACCESSORS

=over 4

=item C<$modwheel-E<gt>debug()>


Sets the debug status to either on or off. (1/0).
If used without an argument returns the current debug status.

=item C<$modwheel-E<gt>logmode()>

How to log errors and warnings.



=item C<$modwheel-E<gt>set_logmode($mode)>

Sets the current logmode.
Can be: stderr, apache or off.
If logmode is apache, the apache request object must be set with set_apache.
If logmode is off no logging will happen, but error() will still be set on error.

=item C<$modwheel-E<gt>prefix()>

Where to search for relative files.

=item C<$modwheel-E<gt>set_prefix($prefix)>

Set the current prefix.

=item %{C<$modwheel-E<gt>config()>}

The configuration data structure returned by YAML.
Returns hash reference.

=item C<$modwheel-E<gt>set_config($href)>

Save the configuration data structure.

=item C<$modwheel-E<gt>configfile()>

 The YAML configuration file to use.

=item C<$modwheel-E<gt>set_configfile($file)>

Set the YAML configuration file to use.

=item C<$modwheel-E<gt>configcachetype($type)>

Not yet implemented.

=item C<$modwheel-E<gt>site()>

The name of the current site to use. This is the name
used when getting site configuration with siteconfig().
If no site is specified, it uses the defaultsite specified
in the global section of the configuration.

=item C<$modwheel-E<gt>set_site($site)>

Set the current site.

=item {C<$modwheel-E<gt>siteconfig()>

Returns the current siteconfig using the site() name..

=item $r = C<$modwheel-E<gt>apache()>

We use the log_error method in this object to log errors and warning
if we are running under the Apache environment and logmode is set to 'apache'.

=item C<$modwheel-E<gt>set_apache(Apache::*$r)>

Save the apache request object to use.

=item C<$modwheel-E<gt>error()>

Holds the last error string passed to log().

=item C<$modwheel-E<gt>locale()>

The locale to use.

=back

=head1 INSTANCE METHODS

=over 4

=item C<$modwheel-E<gt>set_locale($locale)>

Sets the current locale using POSIX::setlocale.

=item C<$modwheel-E<gt>setup_locale_globally()>

If no custom locale is passed when creating a Modwheel object,
it sets up the locale using either the locale specified in the current siteconfig
or the locale specified in the global section of the configuration file.

=item C<$modwheel-E<gt>parseconfig()>

Example: 

    $modwheel->set_config("/opt/modwheel/testconfig.yml");
    my $config = $modwheel->parseconfig();
    $modwheel->set_config($config);
    
We use YAML for parsing our configuration file specified in configfile().
Exits if the configuration file does not exist.
Returns: Hashref to the data structure returned by YAML::LoadFile.

=item C<$modwheel-E<gt>dumpconfig()>

Dumps a scalar string representation of the configurations YAML data structure.

=item C<$modwheel-E<gt>logerror(@strings)>

Log an error.

=item C<$modwheel-E<gt>logwarn(@strings)>

Log a warning.

=item C<$modwheel-E<gt>loginform(@strings)>

Log some informative text.

=item C<$modwheel-E<gt>log(string facility, string logstr)>

The private logging function, shouldn’t be used directly.
Use the logerror/logwarn/loginform functions instead.

=item C<$modwheel-E<gt>throw($exception)>

Throw an exception.
Adds the exception to the exceptions array.

=item C<$modwheel-E<gt>exception()>

Pop a exception off the exceptions array.

=item C<$modwheel-E<gt>catch($exception)>

Search the exceptions array for an exception.
Returns 1 if found and 0 if not found.

=item C<$modwheel-E<gt>catch_like($regex)>

Like catch() but searches the exceptions array by using regular expression.

=back

=head1 EXPORT

None.

=head1 HISTORY

=over 8

=item 0.01

Initial version.

=back

=head1 SEE ALSO

The README included in the Modwheel distribution.

The Modwheel website: http://www.0x61736b.net/Modwheel/


=head1 AUTHORS

Ask Solem, F<< ask@0x61736b.net >>.

=head1 COPYRIGHT, LICENSE

Copyright (C) 2007 by Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

# Local variables:
# vim: ts=4
}

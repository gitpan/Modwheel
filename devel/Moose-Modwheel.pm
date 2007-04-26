
  package Modwheel;
  use version; $VERSION = qv('0.2.1');
  use Moose::Policy 'Modwheel::Policy';
  use Moose;
  

use strict;
use warnings;
use 5.00800;
use Carp;
use YAML;
use POSIX                           qw( locale_h );
use English                         qw( -no_match_vars );
use Readonly;
use Scalar::Util                    qw( blessed );
use List::MoreUtils                 qw( any );
use namespace::clean;

extends 'Moose::Object';

has 'debug'             => (isa => 'Int',      is => 'rw');
has 'prefix'            => (isa => 'Str',      is => 'rw');
has 'logmode'           => (isa => 'Str',      is => 'rw');
has 'configfile'        => (isa => 'Str',      is => 'rw');
has 'site'              => (isa => 'Str',      is => 'rw');
has 'error'             => (isa => 'Str',      is => 'rw');
has 'locale'            => (isa => 'Str',      is => 'rw');
has 'config'            => (isa => 'Any',      is => 'rw');
has 'logobject'         => (isa => 'Any',      is => 'rw');
has 'loghandlers'       => (isa => 'HashRef',  is => 'rw');
has 'exceptions'        => (isa => 'ArrayRef', is => 'rw');
Modwheel->meta->make_immutable();

Readonly my $DEFAULT_PREFIX        => '/opt/modwheel';
Readonly my $DEFAULT_CONFIGFILE    => 'modwheelconfig.yml';
Readonly my $DEFAULT_LOGMODE       => 'stderr';

Readonly my $LOGHANDLER_STDERR => sub {
    my ($self, $log_string) = @_;
    print STDERR $log_string, "\n";
    return;
};
Readonly my $LOGHANDLER_OFF   => sub { };

sub BUILD {
    my ($self, $arg_ref) = @_;
    #$arg_ref->{ logmode    } ||= $DEFAULT_LOGMODE;
    #$arg_ref->{ configfile } ||= $DEFAULT_CONFIGFILE;

    # install default logging handlers 
    my $loghandlers = {
        stderr  => $LOGHANDLER_STDERR,
        off     => $LOGHANDLER_OFF,
    };
    $self->set_loghandlers($loghandlers);
    # install user-specified log_handlers 
    my $add_loghandlers = $arg_ref->{add_loghandlers};
    if (UNIVERSAL::isa($add_loghandlers, 'HASH')) {
        while (my($lh_name, $lh_code_ref) = each %$add_loghandlers) {
           $self->install_loghandler($lh_name, $lh_code_ref);
        }
    } 

    # set logging mode. logmode can be 'stderr', 'off' or a mode installed
    # with the option add_loghandlers { }.
    $self->set_logmode( $arg_ref->{logmode} );
    $self->set_logobject( $arg_ref->{logobject} )   if $arg_ref->{logobject};

    # ### Set prefix
    my $prefix = $arg_ref->{prefix};
    if (! $prefix) {
        $prefix = $DEFAULT_PREFIX;
        $self->logwarn('No prefix specified. Using internal default.
            This is probably not what you want.'
        );
    }
    $self->set_prefix($prefix);

    # Find configuration file.
    $self->set_configfile( $arg_ref->{configfile} );

    # Parse and save access to config.
    my $config = $self->parseconfig( );
    $self->set_config($config);
    return if not ref $self->config;

    # ## Set up the Site for this instance.
    my $site   = $arg_ref->{site};
       $site ||= $self->config->{global}{defaultsite};
    $self->set_site($site);
    if (! ref $self->siteconfig) {
        $self->throw('modwheel-no-site-selected');
        $self->logerror('No site selected. Please configure Modwheel.');
        return;
    }

    # ## Set up the locale for this instance.
    $arg_ref->{locale}
        ?  $self->set_locale( $arg_ref->{locale} )
        :  $self->setup_locale_globally
    ;

    # ## Debugging on/off
    my $debug   = $arg_ref->{debug};
       $debug ||= $self->config->{global}{debug};
    $self->set_debug($debug);

    return;
}

sub set_locale {
    my ($self, $locale) = @_;

    if ($locale) {
        setlocale(LC_ALL, $locale);
        $self->{locale} = $locale;
    }
}

sub setup_locale_globally {
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

sub siteconfig {
    my ($self) = @_;
    my $site   = $self->site;
    return $self->config->{site}{$site};
}

sub parseconfig {
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


sub dumpconfig {
    my ($self) = @_;
    return YAML::Dump( [$self->config] );
}

sub set_loghandlers {
    my ($self, $loghandlers) = @_;
    $self->loghandlers($loghandlers) if defined $loghandlers;
}

sub install_loghandler
{
    my ($self, $name, $code_ref) = @_;
    croak "loghandler $code_ref is not a sub routine"
        unless ref $code_ref eq 'CODE';
   
    $self->loghandlers->{$name} = $code_ref;

    return 1;
}

sub remove_loghandler
{
    my ($self, $name) = @_;
    my $loghandlers = $self->loghandlers;

    delete $loghandlers->{$name};

    return 1;
}

sub logerror {
    my ($self) = @_;
    return $self->log("Error", @_);
}


sub logwarn {
    my ($self) = @_;
    return $self->log("Warning", @_);
}


sub loginform {
    my ($self) = @_;
    return $self->log("Info", @_);
}

sub log {
    my ($self, $facility, @log_strings) = @_;
    my $loghandlers = $self->loghandlers;
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

    $self->set_error($log_string) if $facility eq 'Error';

    # default mode of logging is to output to stderr.
    my $logmode = $self->logmode || 'stderr';

    # get the handler for this log mode.
    my $loghandler_ref = $loghandlers->{$logmode};

    unless ($loghandler_ref) {
        print STDERR "Warning: Unknown logmode '$logmode'. Using stderr ",
                     "instead.\n";
        $loghandler_ref = $loghandlers->{stderr};
    }
        
    # do something with the freshly formatted log message:
    $loghandler_ref->($self, $log_string);

    return;
}


sub throw {
    my ($self, $exception) = @_;
    my $exceptions_ref   = $self->exceptions;
       $exceptions_ref ||= [ ]; 

    push @$exceptions_ref, $exception;

    return;
}


sub exception {
    my ($self) = @_;
    my $exceptions_ref = $self->exceptions;

    if (ref @$exceptions_ref eq 'ARRAY') {
        return pop @$exceptions_ref;
    }

    return;
}


sub catch {
    my ($self, $catch) = @_;
    my $exceptions_ref = $self->exceptions;
    return 0 if ref $exceptions_ref ne 'ARRAY';

    # catch any error.
    if (!$catch) {
        return 1 if scalar @$exceptions_ref;
    }

    # catch the exception in $catch.    
    return any { $_ eq $catch } @$exceptions_ref ? 1 : 0;
}


sub catch_like {
    my ($self, $catch) = @_;
    my $exceptions_ref = $self->exceptions;
    return 0 if ref $exceptions_ref ne 'ARRAY';
   
    return any { m/$catch/xms } @$exceptions_ref ? 1 : 0;
}


1;
__END__

=head1 NAME

Modwheel - Web framework.

=head1 DESCRIPTION

Modwheel is a publishing system for use with web, print, TeX, or whatever medium you have
a need to publish in. It is designed to be very extensible and will in the future have 
drop-in support for several relational databases and templating systems.

Modwheel is currently in a very early alpha development stage.

The current development version of Modwheel should work with MySQL/PostgreSQL and the TemplateToolkit,
although porting to other databases or templating systems. shouldn't be much work.



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


=head1 CONSTRUCTOR

=over 4

=item C<Modwheel-E<gt>new()>

Creates a new Modwheel object.

Arguments:

It requires a hash of configuration options as argument.
The configuration keys are:

    prefix         - The base Modwheel directory. (i.e /opt/modwheel)
    configfile     - Name of the configuration file. (i.e config/modwheelconfig.yml)
    logmode        - Where log messages goes. Can be stderr, off or you can
                     install your own loghandler with install_loghandler().
    site           - The site to use. Must have a corresponding site directive in the config file.
    locale         - The locale to use. (i.e en_EN)
    debug          - Turn on debugging features.    
    logobject      - A object that can be used in your loghandler for logging.

Returns:

A new Modwheel object if everything was OK. Returns no value if there was an error.

=back

=head1 ATTRIBUTES

=over 4

=item C<$modwheel-E<gt>debug()>

=item C<$modwheel-E<gt>set_debug()>

If this is on (set to a true value), the modwheel components
will print various debugging messages. Turn this off for production
environments as it can reveal sensitive information.

=item C<$modwheel-E<gt>logmode()>

How to log errors and warnings.

=item C<$modwheel-E<gt>set_logmode($mode)>

Sets the current logmode.
Default log modes are: stderr and off.
Modwheel-Apache installs the log mode: apache2
If logmode is off no logging will happen, but error() will still be set on error.

=item C<$modwheel-E<gt>prefix()>

=item C<$modwheel-E<gt>set_prefix($prefix)>

The path to search for relative files.

=item %{C<$modwheel-E<gt>config()>}

The configuration data structure returned by YAML.
Returns hash reference.

=item C<$modwheel-E<gt>set_config($href)>

Save the configuration data structure.
You rarely want to use this.

=item C<$modwheel-E<gt>configfile()>

=item C<$modwheel-E<gt>set_configfile($filename)>

The L<YAML> configuration file to use.
For more information about YAML please see: L<http://www.yaml.org>.

=item C<$modwheel-E<gt>site()>

=item C<$modwheel-E<gt>set_site($site)>

The name of the current site to use. This is the name
used when getting site configuration with siteconfig().
If no site is specified, it uses the defaultsite specified
in the global section of the configuration.


=item C<$modwheel-E<gt>logobject()>
=item C<$modwheel-E<gt>set_logobject($your_object)>

If you install a log handler with C<$modwheel-E<gt>install_loghandler()> you
save a object here for use within your log handler.

=item C<$modwheel-E<gt>error()>

Holds the last error string passed to log().


=item C<$modwheel-E<gt>locale()>

Current locale in use.

=back

=head1 INSTANCE METHODS

=over 4

=item C<$modwheel-E<gt>set_locale($locale)>

Sets the current locale using POSIX::setlocale.

=item C<$modwheel-E<gt>setup_locale_globally()>

If no custom locale is passed when creating a Modwheel object,
it sets up the locale using either the locale specified in the current siteconfig
or the locale specified in the global section of the configuration file.

=item C<$modwheel-E<gt>siteconfig()>

Returns the current siteconfig using the site name in C<$self->site>.

=item C<$modwheel-E<gt>install_loghandler($name, $code_ref)>

Installs new log handler, $code_ref must be an anonymous subroutine.

This is and example how Apache2-Modwheel can make an handler to log messages
with the apache2 request object's Apache2::Log::log_error();

    my $log_handler_ref = sub {
        my ($modwheel, $log_string) = @_;
        my $apache2_request = $modwheel->logobject;
        $apache2_request->log_error( $log_string );
        return;
    }
    $modwheel->set_logobject($r);
    $modwheel->install_handler('apache2', $log_handler_ref);
    $modwheel->logmode('apache2');

Or to install the handlers when calling C<Modwheel-E<gt>new>
        
    my $modwheel = Modwheel->new(
        # [....]
        logobject       => $r,
        add_loghandlers => {
            apache2         => $log_handler_ref;
        },
        logmode         => 'apache2',
        # [....]

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

=head1 PRIVATE ATTRIBUTES AND METHODS

=over 4

=item C<$modwheel-E<gt>set_error()>

Set the error message.
This is a private function, use the C<log*> methods instead.

=item @{ C<$modwheel-E<gt>exceptions()> }

This is the internal array used by the exceptions system.
Use C<$modwheel-E<gt>throw()>, C<$modwheel-E<gt>catch()>,
C<$modwheel-E<gt>catch_like()> and C<$modwheel-E<gt>exception()> instead.

=back

=head1 EXPORT

None.

=head1 HISTORY

=over 8

=item v0.2.1

Now it's possible to create your own object types.

=item 0.01 

Initial version.

=back

=head1 SEE ALSO

=over 4

=item * L<Modwheel::Object>

=item * L<Modwheel::DB::Base>

=item * L<Modwheel::Template>

=item * L<Modwheel::Session>

=item * L<Modwheel::Repository>

=item * L<Modwheel::User>

=item * L<Apache2::Modwheel>: L<http://search.cpan.org/~asksh/Modwheel-Apache2-0.01/>

=back

The README included in the Modwheel distribution.

The Modwheel website: L<http://www.0x61736b.net/Modwheel/>


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

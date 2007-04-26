# $Id: Modwheel.pm,v 1.6 2007/04/25 18:49:13 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.6 $
# $Date: 2007/04/25 18:49:13 $
#
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel.pm - Web framework.
#   This class has methods for parsing configuration files, setting locale,
#   logging features and more.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
package Modwheel;
use strict;
use warnings;
use 5.00800;
use version; our $VERSION = qv('0.2.1');
use Class::InsideOut::Policy::Modwheel qw(:std);
{

    use Carp            qw(cluck carp croak confess);
    use Readonly;
    use YAML::Syck      qw();
    use POSIX           qw( locale_h );
    use English         qw( -no_match_vars );
    use Scalar::Util    qw( blessed );
    use List::MoreUtils qw( any );
    use File::Spec      qw();
    use Params::Util    ('_ARRAY', '_HASH', '_CODELIKE');
    use namespace::clean;

    #========================================================================
    #                     -- CONSTANTS --
    #========================================================================

    # Default configfile:
    #   Path must be absolute or relative to prefix.
    Readonly my $DEFAULT_CONFIGFILE => 'modwheelconfig.yml';

    # Default logmode:
    #   Which log handler to use. The default log handlers
    #   are stderr and off.
    Readonly my $DEFAULT_LOGMODE => 'stderr';

    # Loghandler for stderr:
    Readonly my $LOGHANDLER_STDERR => sub {
        my ( $self, $log_string ) = @_;
        warn $log_string, "\n";
        return;
    };
    Readonly my $LOGHANDLER_DEBUG  => sub {
        my ( $self, $log_string, $facility ) = @_;
        $facility eq 'Error'    ? cluck $log_string
                                : carp  $log_string
        ;
        return;
    };

    # Loghandler for off (no output of log messages).
    Readonly my $LOGHANDLER_OFF => sub { };

    #========================================================================
    #                     -- OBJECT ATTRIBUTES --
    #========================================================================

    public debug       => my %debug_for,       { is => 'rw' };
    public prefix      => my %prefix_for,      { is => 'rw' };
    public logmode     => my %logmode_for,     { is => 'rw' };
    public configfile  => my %configfile_for,  { is => 'rw' };
    public site        => my %site_for,        { is => 'rw' };
    public error       => my %error_for,       { is => 'rw' };
    public locale      => my %locale_for,      { is => 'rw' };
    public config      => my %config_for,      { is => 'rw' };
    public logobject   => my %logobject_for,   { is => 'rw' };
    public loghandlers => my %loghandlers_for, { is => 'rw' };
    public exceptions  => my %exceptions_for,  { is => 'rw' };

    #========================================================================
    #                     -- CONSTRUCTOR --
    #========================================================================

    sub new {
        my ( $class, $arg_ref ) = @_;

        my $self = register($class);

        $arg_ref->{logmode}    ||= $DEFAULT_LOGMODE;
        $arg_ref->{configfile} ||= $DEFAULT_CONFIGFILE;

        # install default logging handlers
        my $loghandlers = {
            stderr => $LOGHANDLER_STDERR,
            debug  => $LOGHANDLER_DEBUG,
            off    => $LOGHANDLER_OFF,
        };
        $self->set_loghandlers($loghandlers);

        # install user-specified log_handlers
        my $add_loghandlers = $arg_ref->{add_loghandlers};
        if (_HASH($add_loghandlers) ) {
            while (my ($lh_name, $lh_code_ref ) = each %{$add_loghandlers} ) {
                $self->install_loghandler( $lh_name, $lh_code_ref );
            }
        }

        # set logging mode. logmode can be 'stderr', 'off' or a mode installed
        # with the option add_loghandlers { }.
        $self->set_logmode( $arg_ref->{logmode} );
        if ($arg_ref->{logobject}) {
            $self->set_logobject( $arg_ref->{logobject} );
        }

        # ### Set prefix
        my $prefix   = $arg_ref->{prefix};
        croak 'Missing prefix. Please edit your settings.'
            if not $prefix;
        $self->set_prefix($prefix);

        # Find configuration file.
        $self->set_configfile( $arg_ref->{configfile} );

        # Parse and save access to config.
        # parseconfig dies on error.
        my $config = $self->parseconfig();
        $self->set_config($config);

        # ## Set up the Site for this instance.
        my $site = $arg_ref->{site};
        $site ||= $self->config->{global}{defaultsite};
        $self->set_site($site);
        if (!ref $self->siteconfig) {
            croak 'No configuration for site'. $self->site.
                  'Please configure Modwheel.'
        }

        # ## Set up the locale for this instance.
        $arg_ref->{locale}
            ? $self->locale_setup_with_locale( $arg_ref->{locale} )
            : $self->locale_setup_from_config();

        # ## Debugging on/off
        my $debug = $arg_ref->{debug};
        $debug ||= $self->config->{global}{debug};
        $self->set_debug($debug);

        return $self;
    }

    #========================================================================
    #                     -- PUBLIC INSTANCE METHODS --
    #========================================================================

    #------------------------------------------------------------------------
    # ->locale_setup_with_locale($locale)
    #
    # Set locale for the current instance using POSIX::setlocale().
    #------------------------------------------------------------------------
    sub locale_setup_with_locale {
        my ($self, $locale) = @_;

        return $self->_setlocale($locale);
    }

    #------------------------------------------------------------------------
    # ->locale_setup_from_config()
    #
    # Look for locale setting in 1) site configuration and then 2) global
    # configuration. Set the first locale found with POSIX::setlocale().
    #------------------------------------------------------------------------
    sub locale_setup_from_config {
        my ($self) = @_;

        my $siteconfig = $self->siteconfig;
        if ($siteconfig->{locale}) {
            $self->_setlocale( $siteconfig->{locale} );
        }
        elsif ($self->config->{global}{locale}) {
            $self->_setlocale( $self->config->{global}{locale} );
        }

        return;
    }

    #------------------------------------------------------------------------
    # ->siteconfig()
    #
    # Return hash reference to the site configuration for this instance.
    # It actually just a shortcut to $config->{site}{ $self->site() }.
    #------------------------------------------------------------------------
    sub siteconfig {
        my ($self) = @_;
        my $site = $self->site;
        return $self->config->{site}{$site};
    }

    #------------------------------------------------------------------------
    # ->parseconfig()
    #
    # Crates a data structure out of the configuration file in ->configfile
    # with YAML::Syck. Returns hash reference to that config.
    #
    # If the file name in ->configfile is relative, it looks in ->prefix.
    #------------------------------------------------------------------------
    sub parseconfig {
        my ($self) = @_;

        my $configfile = $self->configfile( );
        if (! File::Spec->file_name_is_absolute($configfile)) {
            $configfile = File::Spec->catfile( $self->prefix, $configfile );
        }
        if (!-f $configfile) {
            croak 'Fatal error: Could not open configuration file '
                . "($configfile): $OS_ERROR";
        }
        my $ref = YAML::Syck::LoadFile($configfile);

        return $ref;
    }

    #------------------------------------------------------------------------
    # ->dumpconfig()
    #
    # Dumps the data structure in ->config to a string.
    # This string can be saved to disk and then loaded back again with
    # ->parseconfig().
    #------------------------------------------------------------------------
    sub dumpconfig {
        my ($self) = @_;
        return YAML::Syck::Dump( [ $self->config ] );
    }

    #------------------------------------------------------------------------
    # ->install_loghandler($name, \&code_ref)
    #
    # Install a log handler to be used with ->log* and friends.
    #------------------------------------------------------------------------
    sub install_loghandler {
        my ($self, $name, $code_ref) = @_;
        croak 'missing loghandler name' if not defined $name;
        croak "loghandler $code_ref is not a sub routine"
            if !_CODELIKE($code_ref);

        $self->loghandlers->{$name} = $code_ref;

        return 1;
    }

    #------------------------------------------------------------------------
    # ->remove_loghandler($name)
    #
    # Remove a log handler by it's name.
    #   i.e ->remove_loghandler('stderr');
    #------------------------------------------------------------------------
    sub remove_loghandler {
        my ($self, $name) = @_;
        croak 'missing loghandler name' if not defined $name;
        
        my $loghandlers = $self->loghandlers;

        delete $loghandlers->{$name};

        return 1;
    }

    #------------------------------------------------------------------------
    # ->logerror(@messages)
    #
    # Log an error.   (Facility: 'Error')
    #------------------------------------------------------------------------
    sub logerror {
        my $self = shift;
        return $self->_log('Error', @_);
    }

    #------------------------------------------------------------------------
    # ->logwarn(@messages)
    #
    # Log a warning. (Facility: 'Warning')
    #------------------------------------------------------------------------
    sub logwarn {
        my $self = shift;
        return $self->_log('Warning', @_);
    }

    #------------------------------------------------------------------------
    # ->loginform(@messages)
    #
    # Log informational message. (Facility: 'Info')
    #------------------------------------------------------------------------
    sub loginform {
        my $self = shift;
        return $self->_log('Info', @_);
    }

    #------------------------------------------------------------------------
    # ->throw($exception)
    #
    # Throw an exception.
    # Exception names are usually in the format:
    #   class-method-error_type
    # i.e:
    #   user-login-incorrect
    #
    # This function pushes the exception onto the exceptions array.
    #------------------------------------------------------------------------
    sub throw {
        my ($self, $exception) = @_;
        my $exceptions_ref = $self->exceptions;
        $exceptions_ref ||= [];

        push @{$exceptions_ref}, $exception;

        $self->set_exceptions($exceptions_ref);

        return;
    }

    #------------------------------------------------------------------------
    # ->exception()
    #
    # Return the last exception ->throw'ed.
    #
    # This function pops the last element from the exceptions array.
    #------------------------------------------------------------------------
    sub exception {
        my ($self) = @_;
        my $exceptions_ref = $self->exceptions;

        if (_ARRAY($exceptions_ref)) {
            return pop @{$exceptions_ref};
        }

        return;
    }

    #------------------------------------------------------------------------
    # ->catch($exception_type)
    #
    # Catch an exception of type $exception_type.
    #   i.e: ->catch('user-login-incorrect')
    #
    # This function searches the exceptions array for a element equal to
    # $exception_type. Returns true if one is found, 0 otherwise.
    #
    # If no exception type is provided it returns true on any exception.
    #------------------------------------------------------------------------
    sub catch {
        my ($self, $catch) = @_;
        my $exceptions_ref = $self->exceptions;
        return 0 if !_ARRAY($exceptions_ref);


        # catch any error.
        return 1 if !$catch;

        for my $e (@{$exceptions_ref}) {
            return 1 if $e eq $catch;
        }

        return 0;

        # catch the exception in $catch.
        #return any { $_ eq $catch } @$exceptions_ref ? 1 : 0;
    }

    #------------------------------------------------------------------------
    # ->catch_like($exception_regex)
    #
    # Search for an exception by a regular expression.
    #   i.e: ->catch('^user-')
    # will catch all exceptions that starts with 'user-'.
    #
    # This function searches the exceptions array for and element that
    # matches $exception_regex. Returns true if one is found, 0 otherwise.
    #
    # If no exception type is provided it returns true on any exception.
    #------------------------------------------------------------------------
    sub catch_like {
        my ( $self, $catch ) = @_;
        my $exceptions_ref = $self->exceptions;
        return 0 if !_ARRAY($exceptions_ref);

        return 1 if !$catch;

        $catch = quotemeta $catch;
        foreach my $e (@{$exceptions_ref}) {
            return 1 if $e =~ m/$catch/xms;
        }

        return 0;

        # return any { m/$catch/xms } @$exceptions_ref ? 1 : 0;
    }

    #========================================================================
    #                     -- PRIVATE INSTANCE METHODS --
    #========================================================================

    #------------------------------------------------------------------------
    # ->_log($facility, @messages)
    #
    # The function that actually does the logging.
    # Use ->logerror(), ->logwarn() and ->loginform() instead.
    #
    # This function formats the strings to a nicely formatted message.
    # The message is more verbose if ->debug is on.
    # It finds a loghandler with the name in ->logmode() to send the
    # formatted message to. The loghandlers are anonymous subroutines that
    # are called with the following arguments:
    #   $self       - the modwheel object.
    #   $message    - the formatted log message.
    #   $facility   - the facility (Error, Info or Warning).
    #   @raw        - the raw unformatted message input to the log* functions.
    #------------------------------------------------------------------------
    sub _log {
        my ($self, $facility, @log_strings) = @_;
        my $loghandlers = $self->loghandlers;
        my $log_string = join q{ }, @log_strings;
        $log_string ||= 'Tried to log, but no message specified.';

        # Format the log message.
        if ($self->debug) {

            # Add some extra debugging information if debugging is on.
            my ($package, $filename, $line) = caller;
            $log_string = sprintf '[%s: %s: %d]: %s: %s', $package, $filename,
                $line, $facility, $log_string;
        }
        else {
            $log_string = sprintf '%s: %s', $facility, $log_string;
        }

       # Save the error message in our error attribute when facility is error.
        if ($facility eq 'Error') {
            $self->set_error($log_string);
        }

        # default mode of logging is to output to stderr.
        my $logmode = $self->logmode;

        # get the handler for this log mode.
        my $loghandler_ref = $loghandlers->{$logmode};

        if (!$loghandler_ref) {
            print {*STDERR}
                "Warning: Unknown logmode '$logmode'. Using stderr ",
                "instead.\n";
            $loghandler_ref = $loghandlers->{stderr};
        }

        # do something with the freshly formatted log message:
        $loghandler_ref->( $self, $log_string, $facility, @log_strings );

        return;
    }

    #------------------------------------------------------------------------
    # ->_setlocale($locale)
    #
    # Private method: Use ->set_locale_with_locale($locale) instead.
    #
    # This function sets the locale using POSIX::setlocale.
    #------------------------------------------------------------------------
    sub _setlocale {
        my ($self, $locale) = @_;

        if (defined $locale) {
            POSIX::setlocale(LC_ALL, $locale);
            $self->set_locale($locale);
        }

        return;
    }

};

1;
__END__

=head1 NAME

Modwheel - Web framework.

=head1 VERSION

This document describes Modwheel version 0.2.1

=head1 DESCRIPTION

Modwheel is a publishing system for use with web, print, TeX, or whatever medium you have
a need to publish in. It is designed to be very extensible and will in the future have 
drop-in support for several relational databases and templating systems.

Modwheel is currently in a very early alpha development stage.

The current development version of Modwheel should work with MySQL and the TemplateToolkit,
although porting to other databases or representation engines shouldn't be much work.

=head1 SYNOPSIS

    #!/usr/bin/perl -T
    use strict;
    use warnings;
    use Modwheel::Session;
    use IO::Handle;
    use CGI;
    *STDOUT->autoflush( );

    my $modwheel_config = {
        prefix          => '/opt/modwheel',
        configfile      => 'modwheelcfg.yml',
        site            => 'modwheeltest',
        locale          => 'en_EN',
        logmode         => 'stderr',
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

=head1 SUBROUTINES/METHODS

=head2 CONSTRUCTOR

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

=head2 ATTRIBUTES

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

=head2 INSTANCE METHODS

=over 4

=item C<$modwheel-E<gt>locale_setup_with_locale($locale)>

Sets the current locale using POSIX::setlocale.

=item C<$modwheel-E<gt>locale_setup_from_config()>

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

=item C<$modwheel-E<gt>remove_loghandler($name)>

Remove a log handler previously installed with C<-E<gt>install_loghandler()>.

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

=head2 PRIVATE ATTRIBUTES AND METHODS

=over 4

=item C<$modwheel-E<gt>set_error()>

Set the error message.
This is a private function, use the C<log*> methods instead.

=item @{ C<$modwheel-E<gt>exceptions()> }

This is the internal array used by the exceptions system.
Use C<$modwheel-E<gt>throw()>, C<$modwheel-E<gt>catch()>,
C<$modwheel-E<gt>catch_like()> and C<$modwheel-E<gt>exception()> instead.

=item C<$modwheel-E<gt>_setlocale($locale)>

Internal method for setting locale. C<Use locale_setup_with_locale($locale)>
instead.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Modwheel requires a configuration file in the YAML format.
For more info on the configuration syntax see the manual:

=over 4

=item L<Modwheel::Manual::Config>

=back

=head1 SEE ALSO

The Modwheel manual is a good place to start:

=over 4

=item L<Modwheel::Manual>

=back

For a reference on the Modwheel programming interface, see the
respecitive modules:

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

=head1 DIAGNOSTICS

The modwheel test suite.

=head1 DEPENDENCIES

=over 4

=item Perl >= 5.8

=item version

=item namespace::clean

=item Params::Util

=item List::MoreUtils

=item Readonly

=item Perl6::Export::Attrs

=item YAML::Syck

=item DBI

=item Crypt::Eksblowfish

=item HTML::Tagset

=item HTML::Parser

=item URI::Escape

=item Template

=back

=head1 INCOMPATIBILITIES

None known at the moment.

=head1 BUGS AND LIMITATIONS

None known at the moment.

=head1 AUTHOR

Ask Solem, F<< ask@0x61736b.net >>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 by Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# Local variables:
# vim: ts=4

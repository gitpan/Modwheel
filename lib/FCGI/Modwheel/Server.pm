# $Id$
# $Source$
# $Author$
# $HeadURL$
# $Revision$
# $Date$
package FCGI::Modwheel::Server;
use strict;
use warnings;
use English qw( -no_match_vars );
use POSIX qw(setsid);
use FCGI;
use Class::InsideOut::Policy::Modwheel qw( :std );
{

    sub new {
        return register(shift);
    }

    sub run {
        my ($self, $class, $listen, $options_ref) = @_;
        $options_ref ||= {};
        my $sock = 0;
        if ($listen) {
            $sock = FCGI::OpenSocket($listen, 100)
                or die "Failed to open FastCGI socket: $OS_ERROR";
        }

        my %env;
        my $request
            = FCGI::Request( \*STDIN, \*STDOUT, \*STDERR, \%env, $sock,
            ( $options_ref->{nointr} ? 0 : FCGI::FAIL_ACCEPT_ON_INTR ),
            );

        my $process_manager;
        my $manager = $options_ref->{manager};

        if ($listen) {
            $manager ||= "FCGI::ProcManager";
            $options_ref->{nproc}   ||= 1;

            if ($options_ref->{detach}) {
                $self->daemonize();
            }

            eval "use $manager; 1" or die $EVAL_ERROR;

            my $process_manager = $manager->new(
                {   n_processes => $options_ref->{nproc},
                    pidfile     => $options_ref->{pidfile},
                }
            );

            $process_manager->pm_manage();
        }

        while ($request->Accept >= 0) {

            $process_manager && $process_manager->pm_pre_dispatch();

            $class->handle_request($request, \%env);

            $process_manager && $process_manager->pm_post_dispatch();

        }

        return;
    }

    sub write {
        my ($self, $buffer) = @_;
        return *STDOUT->syswrite($buffer);
    }

    sub daemonize {

        my $id = fork;
        die "$0: Error: Can't fork: $OS_ERROR"
            if $id == 1;
        if ($id != 0) {

            # This is parent...
            exit 0;
        }

        # This is child:
        print {*STDERR} "We have launched into the background.\n",
            "Our process-id is: $id. Type `kill $id` to quit",
            "the server.\n\n";
        open STDIN,  "+</dev/null" or die $OS_ERROR;
        open STDOUT, ">&STDIN"     or die $OS_ERROR;
        open STDERR, ">&STDIN"     or die $OS_ERROR;

        POSIX::setsid();

        return;
    }

}

1; # magic true return value.

# $Id: Session.pm,v 1.3 2007/05/19 13:03:01 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/User/Session.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.3 $
# $Date: 2007/05/19 13:03:01 $
package Modwheel::User::Session;
use base 'Modwheel::Instance';
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw( :std );
use version; our $VERSION = qv('0.3.3');
{

    use Readonly;
    Readonly my $DEFAULT_EXPIRE_TIME => 1800;
    Readonly my $SESSION_TABLE_NAME  => 'user_session';
  
    public id       => my %id_for,     {is => 'rw'};
    public expire   => my %expire_for, {is => 'rw'};

    sub new {
        my $class = shift;
        my $self = $class->SUPER::new(@_);
        my ($options_ref) = @_;
        $options_ref    ||= { };

        my $modwheel       = $self->modwheel;
        my $siteconfig_ref = $modwheel->siteconfig;

        # The time it takes before this session expires is taken from
        # argument to object construction, from configfile or the default constant.
        if ($options_ref->{expire}) {
            $expire_for{ident $self} = $options_ref->{expire};
        }
        elsif ($siteconfig_ref && $siteconfig_ref->{session}{expire}) {
            $expire_for{ident $self} = $siteconfig_ref->{session}{expire};
        }
        else {
            $expire_for{ident $self} = $DEFAULT_EXPIRE_TIME;
        }

        return $self;
    }

    sub save_session {
        my ($self, $user_id, $user_addr) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;
        my $user     = $self->user;

        my $user_name = $user->namebyuid($user_id);
        # throw('user-session-open-no-such-uid');

        my $new_id = $db->fetch_next_id($SESSION_TABLE_NAME);
        my $time_start   = time;
        my $time_expires = $time_start + $self->expire;
        my $salt = 'ABCD';
        $user_addr ||= '127.0.0.1';

        my $ret = $db->insert($SESSION_TABLE_NAME, [
            qw(
                id userid username salt addr time_start time_expire
            )],
            $new_id, $user_id, $user_name, $salt, $user_addr, $time_start, $time_expires
        );

        if ($ret) {
            $self->set_id($new_id);
            return $new_id;
        }

        return;

    }
        
    sub delete_session {
        my ($self) = @_;
        my $db     = $self->db;
        return if not defined $self->id;

        return $db->delete($SESSION_TABLE_NAME, ['id'], $self->id);
    }

}

1;
__END__
'now playing: Lackluster: A1_01.10.00';

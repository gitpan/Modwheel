# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/User.pm - Manage users and user sessions.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# $Id: User.pm,v 1.14 2007/05/19 18:46:48 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/User.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.14 $
# $Date: 2007/05/19 18:46:48 $
#####
package Modwheel::User;
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw(:std);
use version; our $VERSION = qv('0.3.3');
use base 'Modwheel::Instance';
{
    use Carp;
    use Readonly;
    use Scalar::Util qw(blessed looks_like_number);
    use Params::Util ('_HASH', '_ARRAY', '_INSTANCE', '_CODELIKE');
    use Modwheel::User::Session;
    use Modwheel::Crypt;
    use namespace::clean;

    public uname => my %uname_for, {is   => 'rw'};
    public uid   => my %uid_for,   {is   => 'rw'};

    sub uidbyname {
        my ($self, $user) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;
        return $modwheel->throw('user-uidbyname-missing-user')
            if !$user;

        # Select id from users where username is $user.
        my $query = $db->build_select_q('users', ['id'], ['username']);
        my $uid   = $db->fetch_singlevar($query, $user);
        return $uid || 0;
    }

    sub namebyuid {
        my ($self, $uid) = @_;
        my $modwheel = $self->modwheel;
        my $db = $self->db;
        return $modwheel->throw('user-namebyuid-missing-uid')
            if !$uid;

        # Select username from users where id is $uid.
        my $query= $db->build_select_q('users', ['username'], ['id']);

        my $username = $db->fetch_singlevar($query, $uid);

        return $username;
    }

    sub list {
        my ($self) = @_;
        my $db     = $self->db;

        # Select everything from users sorted by username in ascending order.
        my $query
            = $db->build_select_q('users', q{*}, [ ], {order=>'username ASC'});
        my $sth   = $db->query($query);
        my @users;
        while (my $hres = $db->fetchrow_hash($sth)) {
            push @users, $hres;
        }
        $db->query_end($sth);

        return \@users;
    }

    sub login {
        my ($self, $username, $password, $ip) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;

        if (! $username || ! $password) {
            $modwheel->throw('user-no-such-user', $username);
            return 0;
        }

        my $query   = $db->build_select_q('users',['id', 'password'],
            { username => q{?} }
        );
        my $href    = $db->fetchonerow_hash($query, $username);
        my ($uid, $cryptpw) = ($href->{id}, $href->{password});
        if (! $cryptpw) {
            $modwheel->throw('user-no-such-user', $username);
            return 0;
        }

        my $crypt = Modwheel::Crypt->new({
            require_type    => 'One-way',
        });
        if ($crypt->compare($cryptpw, $password)) {
            if ($ip) {
                my $uid   = $self->uidbyname($username);
                #  Update users set last_ip to $uid.
                my $query = $db->build_update_q('users', ['last_ip'], ['id']);
                $db->exec_query($query, $ip, $uid);
            }
            $self->set_uid($uid);
            $self->set_uname($username);

            my $session = Modwheel::User::Session->new({
                modwheel => $modwheel,
                db       => $db,
                user     => $self,
            });

            $session->save_session($uid, $ip);

            return 1;
        }
        else {
            $modwheel->throw('user-login-failed', $username);
            return 0;
        }
    }

    sub update {
        my ($self, $bool_encrypt, $arg_ref) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;

        if ($bool_encrypt && $arg_ref->{password}) {
            my $crypt = Modwheel::Crypt->new({
                require_type => 'One-way',
            });
            $arg_ref->{password} = $crypt->encipher( $arg_ref->{password} );
        }

        if  (!$arg_ref->{username} && !$arg_ref->{id}) {
            return $modwheel->throw('user-update-missing-user');
        }

        if (!$arg_ref->{id}) {
            $arg_ref->{id} = $self->uidbyname($arg_ref->{username});
        }

        # Update users set (all fields in %arg_ref->) where id is $arg_ref->{id}.
        my $query = $db->build_update_q('users', $arg_ref, ['id']);
        my @values = map { $arg_ref->{$_} } sort keys %{ $arg_ref };
        $db->exec_query($query, @values, $arg_ref->{id}) or return;

        return $arg_ref->{id};
    }

    sub create {
        my ($self, %argv) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;

        my $username = $argv{username};
        my $password = $argv{password};
        if (!$username || !$password) {
            return $modwheel->throw('user-create-missing-field');
        }

        if ($self->uidbyname( $username )) {
            return $self->modwheel->throw(
                'user-create-already-exists', $username
            );
        }

        my $crypt       = Modwheel::Crypt->new({
            require_type    => 'One-way',
        });
        $argv{password} = $crypt->encipher( $argv{password} );
        $argv{id}       = $db->fetch_next_id('users');
        my $query       = $db->build_insert_q('users', \%argv);
        my @values      = map { $argv{$_} } sort keys %argv;
        $db->exec_query($query, @values) or return;

        return $argv{id};
    }

    sub unametouid {
        my ($self, $uid) = @_;
        my $modwheel = $self->modwheel;

        if (!looks_like_number $uid) {
            my $username = $uid;
            $uid = $self->uidbyname($username);
            return $modwheel->throw('user-u2id-no-such-user', $username)
                if !$uid;
        }

        return int $uid;
    }

    sub get {
        my ($self, $uid) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;

        return $modwheel->throw('user-get-missing-field')
            if !defined $uid;

        $uid = $self->unametouid($uid);
        return if not defined $uid;

        # Select from users where (..) id is $uid.
        my $query = $db->build_select_q(
            'users',
            [   qw(id username password last_ip real_name groups email comments)
            ],
            {id => q{?}}
        );
        my $user = $db->fetchonerow_hash($query, $uid);
        return $modwheel->throw('user-no-such-user', $uid)
            if !_HASH($user);

        return $user;
    }

    sub delete_user {
        my ($self, $uid) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;

        return $modwheel->throw('user-delete-missing-field')
            if !defined $uid;

        $uid = $self->unametouid($uid);
        return if not defined $uid;

        # Delete from users where id is $uid.
        my $query = $db->build_delete_q('users', ['id']);
        my $ret   = $db->exec_query($query, $uid);

        return $ret ? $ret
                    : $modwheel->throw('user-delete-no-such-user', $uid);
    }

    # #### CLASS METHODS

    sub mkpasswd {
        my ($len) = @_;

        $len ||= 8;

        my @chars  = (0 .. 9, q{A}..q{Z}, q{a}..q{z}, q{!}, q{#}, q{$}, q{%});
        my $passwd;
        for (1..$len) {
            $passwd   .= $chars[rand @chars];
        }

        return $passwd;
    }

}

1;

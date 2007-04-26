# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/User.pm - Manage users and user sessions.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# $Id: User.pm,v 1.5 2007/04/25 18:49:14 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/User.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.5 $
# $Date: 2007/04/25 18:49:14 $
#####
package Modwheel::User;
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw(:std);
use version; our $VERSION = qv('0.2.1');
use base 'Modwheel::Instance';
{
    use Carp;
    use Readonly;
    use Scalar::Util qw(blessed looks_like_number);
    use Params::Util ('_HASH', '_ARRAY', '_INSTANCE', '_CODELIKE');
    use Crypt::Eksblowfish::Bcrypt;
    use namespace::clean;

    public uname => my %uname_for, {is   => 'rw'};
    public uid   => my %uid_for,   {is   => 'rw'};

    Readonly my $BLOWFISH_SALT_SIZE     => 0x10;
    Readonly my $BLOWFISH_KEY_SIZE      => 0x48;
    Readonly my $BLOWFISH_BLOCK_SIZE    => 0x08;
    Readonly my $BLOWFISH_OW_SALT_SIZE  => 0x10;
    Readonly my $BLOWFISH_OW_COST       => 0x08;
    Readonly my $BLOWFISH_OW_KEY_NUL    => 0x01;
    Readonly my $BLOWFISH_MAX_PW_LEN    => 0x08;
    Readonly my $BLOWFISH_PADDING_CHAR  => q{~}; # (tilde)

    sub uidbyname {
        my ($self, $user) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;
        if (! $user) {
            $modwheel->throw('user-uidbyname-missing-user');
            $modwheel->logerror('Uidbyname: Missing username');
            return;
        }

        # Select id from users where username is $user.
        my $query = $db->build_select_q('users', ['id'], ['username']);
        my $uid   = $db->fetch_singlevar($query, $user);
        return $uid || 0;
    }

    sub namebyuid {
        my ($self, $uid) = @_;
        my $modwheel = $self->modwheel;
        my $db = $self->db;
        if (! $uid) {
            $modwheel->throw('user-namebyuid-missing-uid');
            $modwheel->logerror('Namebyuid: Missing UID');
            return;
        }
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
            $modwheel->throw('user-no-such-user');
            $modwheel->logerror(
                'No such username or no password set for user: ', $username);
            return 0;
        }

        my $query   = $db->build_select_q('users',['id', 'password'],
            { username => q{?} }
        );
        my $href    = $db->fetchonerow_hash($query, $username);
        my ($uid, $cryptpw) = ($href->{id}, $href->{password});
        if (! $cryptpw) {
            $modwheel->throw('user-no-such-user');
            $modwheel->logerror(
                'No such username or no password set for user: ', $username);
            return 0;
        }

        if (hashcookie_compare($cryptpw, $password)) {
            if ($ip) {
                my $uid   = $self->uidbyname($username);
                #  Update users set last_ip to $uid.
                my $query = $db->build_update_q('users', ['last_ip'], ['id']);
                $db->exec_query($query, $ip, $uid);
            }
            $self->set_uid($uid);
            $self->set_uname($username);

            return 1;
        }
        else {
            $modwheel->throw('user-login-failed');
            $modwheel->logerror('Invalid username or password.');
            return 0;
        }
    }

    sub update {
        my ($self, $bool_encrypt, $arg_ref) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;

        if ($bool_encrypt && $arg_ref->{password}) {
            $arg_ref->{password} = hashcookie_encipher( $arg_ref->{password} );
        }

        if  (!$arg_ref->{username} && !$arg_ref->{id}) {
            $modwheel->throw('user-update-missing-user');
            $modwheel->logerror(
                'Update user: Please specify which user to update.');
            return;
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
        my $db = $self->db;

        if (!$argv{username} || !$argv{password}) {
            $self->modwheel->throw('user-missing-field');
            $self->modwheel->logerror(
                'Save user: Can not create user without username and password.'
            );
            return;
        }

        if ($self->uidbyname( $argv{username} )) {
            $self->modwheel->throw('user-create-already-exists');
            $self->modwheel->logerror('Create user: User with username',
                $argv{username}, 'already exists!'
            );
            return;
        }

        $argv{password} = hashcookie_encipher( $argv{password} );
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
            if (!$uid) {
                $modwheel->throw('user-no-such-user');
                $modwheel->logerror(
                    'Convert username to UID) No such user', $username
                );
                return;
            }
        }

        return int $uid;
    }

    sub get {
        my ($self, $uid) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;

        if (!defined $uid) {
            $modwheel->throw('user-missing-field');
            $modwheel->logerror('Get User: Missing username or uid.');
            return;
        }

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
        if (! _HASH($user)) {
            $modwheel->throw('user-no-such-user');
            $modwheel->logerror('User get: No such user id:', $uid);
            return;
        }

        return $user;
    }

    sub delete_user {
        my ($self, $uid) = @_;
        my $modwheel = $self->modwheel;
        my $db       = $self->db;

        if (!defined $uid) {
            $modwheel->throw('user-missing-field');
            $modwheel->logerror('Delete User: Missing username or uid.');
            return;
        }

        $uid = $self->unametouid($uid);
        return if not defined $uid;

        # Delete from users where id is $uid.
        my $query = $db->build_delete_q('users', ['id']);
        my $ret   = $db->exec_query($query, $uid);

        if (!$ret) {
            $modwheel->throw('user-no-such-user');
            $modwheel->logerror(
                "User delete: Couldn't delete user: No such user id: $uid");
        }
        else {
            return $ret;
        }

        return;
    }

    # #### CLASS METHODS

    sub mkpasswd {
        my $len = shift;

        $len ||= 8;

        my @chars  = (0 .. 9, q{A}..q{Z}, q{a}..q{z}, q{!}, q{#}, q{$}, q{%});
        my $passwd;
        for (1..$len) {
            $passwd   .= $chars[rand @chars];
        }

        return $passwd;
    }

    sub hashcookie_encipher {
        my $password = shift;

        # Enforce blowfish password length limitation.
        $password   = substr $password, 0, $BLOWFISH_MAX_PW_LEN;

        # Pad with '~' (tilde) if password is less than the limit.
        while (length $password < $BLOWFISH_MAX_PW_LEN) {
            $password  .= $BLOWFISH_PADDING_CHAR;
        }
        my $salt    = Modwheel::User::mkpasswd($BLOWFISH_OW_SALT_SIZE);
        my $hash    = Crypt::Eksblowfish::Bcrypt::bcrypt_hash(
            {
                key_nul => $BLOWFISH_OW_KEY_NUL,
                cost    => $BLOWFISH_OW_COST,
                salt    => $salt,
            },
            $password
        );

        my $hashb64    = Crypt::Eksblowfish::Bcrypt::en_base64($hash);
        my $hashcookie = $salt . $hashb64;

        return $hashcookie;
    }

    sub hashcookie_compare {
        my ($hashcookie, $password) = @_;

        # Enforce blowfish password length limitation. 
        $password   = substr $password, 0, $BLOWFISH_MAX_PW_LEN;

        # Pad with '~' (tilde) if password is less than the limit.
        while (length $password < $BLOWFISH_MAX_PW_LEN) {
            $password .= $BLOWFISH_PADDING_CHAR;
        }

        my $salt    = substr $hashcookie, 0, $BLOWFISH_OW_SALT_SIZE;
        my $hashb64 = substr $hashcookie, $BLOWFISH_OW_SALT_SIZE,
            length $hashcookie;

        my $cmphash = Crypt::Eksblowfish::Bcrypt::bcrypt_hash(
            {
                key_nul => $BLOWFISH_OW_KEY_NUL,
                cost    => $BLOWFISH_OW_COST,
                salt    => $salt,
            },
            $password
        );

        my $cmphashb64 = Crypt::Eksblowfish::Bcrypt::en_base64($cmphash);

        return $hashb64 eq $cmphashb64 ? 1 : 0;
    }

}

1;

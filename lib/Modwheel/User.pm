package Modwheel::User;
use strict;
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/User.pm - Manage users and user sessions.
# (c) 2007 Ask Solem Hoel <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
our @ISA = qw(Modwheel::Instance);
use Crypt::Eksblowfish::Bcrypt;

sub BLOWFISH_SALT_SIZE    { 0x10 };
sub BLOWFISH_KEY_SIZE     { 0x48 };
sub BLOWFISH_BLOCK_SIZE   { 0x08 };
sub BLOWFISH_OW_SALT_SIZE { 0x10 };
sub BLOWFISH_OW_COST      { 0x08 };
sub BLOWFISH_OW_KEY_NUL   { 0x01 };

# #### ACCESSORS

sub uname
{
    my $self = shift;
    return $self->{_USERNAME_}
}

sub set_uname
{
    my ($self, $uname)  = @_;
    $self->{_USERNAME_} = $uname;
}

sub uid
{
    my $self = shift;
    return $self->{_UID_};
}

sub set_uid
{
    my ($self, $uid) = @_;
    unless ($uid =~ m/\d+/) {
        $self->modwheel->throw('user-uid-not-digit');
        return $self->modwheel->logerror("UID must be a digit.");
    }
    $self->{_UID_} = $uid;
}

# #### INSTANCE METHODS

sub uidbyname
{
    my ($self, $user) = @_;
    my $db = $self->db;

    my $query = $db->build_select_q('users', ['id'], {username => '?'});
    my $uid   = $db->fetch_singlevar($query, $user);
    return $uid || 0;
}

sub namebyuid
{
    my ($self, $uid) = @_;
    my $db = $self->db;
    
    my $query    = $db->build_select_q('users', ['username'], {id => '?'});
    my $username = $db->fetch_singlevar($query, $uid);

    return $username;
}

sub list
{
    my $self  = shift;
    my $db    = $self->db;

    my $query = $db->build_select_q('users', ['*'], {}, {order=>'username ASC'});
    my $sth   = $db->query($query);
    my @users;
    while (my $hres = $db->fetchrow_hash($sth)) {
        push @users, $hres;
    }
    $db->query_end($sth);
    
    return \@users;
}

sub login
{
    my ($self, $username, $password, $ip) = @_;
    my $modwheel = $self->modwheel;
    my $db       = $self->db;

    my $query   = $db->build_select_q('users', ['id', 'password'], {username => '?'});
    my $href    = $db->fetchonerow_hash($query, $username);
    my ($uid, $cryptpw) = ($href->{id}, $href->{password});
    unless ($cryptpw) {
        $modwheel->throw('user-no-such-user');
        $modwheel->logerror("No such username or no password set for user: $username");
        return 0;
    }

    if (hashcookie_compare($cryptpw, $password)) {
        if ($ip) {
            my $uid   = $self->uidbyname($username);
            my $query = $db->build_update_q('users', {last_ip => '?'}, {id=>'?'});
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

sub update
{
    my ($self, $bool_encrypt, %argv) = @_;
    my $db = $self->db;

    if ($bool_encrypt && $argv{password}) {
        $argv{password} = hashcookie_encipher( $argv{password} );
    }

    unless ($argv{username} || $argv{id}) {
        $self->modwheel->throw('user-update-missing-user');
        $self->modwheel->logerror("Update user: Please specify which user to update.");
        return undef;
    }

    unless ($argv{id}) {
        $argv{id} = $self->uidbyname($argv{username});
    }

    my $query = $db->build_update_q('users', \%argv, {id=>'?'});
    my @values;
    foreach my $key (sort keys %argv) {
        push @values, $argv{$key};
    }
    $db->exec_query($query, @values, $argv{id}) or return undef;

    return $argv{id};
}

sub create
{
    my ($self, %argv) = @_;
    my $db = $self->db;

    unless ($argv{username} && $argv{password}) {
        $self->modwheel->throw('user-missing-field');
        $self->modwheel->logerror("Save user: Can't create user without username and password.");
        return undef;
    }

    if ($self->uidbyname( $argv{username} )) {
        $self->modwheel->throw('user-create-already-exists');
        $self->modwheel->logerror("Create user: User with username '$argv{username}' already exists!");
        return undef;
    }

    $argv{password} = hashcookie_encipher( $argv{password} );
    $argv{id}       = $db->fetch_next_id('users');
    my $query       = $db->build_insert_q('users', \%argv);
    my @values;
    foreach my $key (sort keys %argv) {
        push(@values, $argv{$key})
    }
    $db->exec_query($query, @values) or return undef;

    return $argv{id};
}

sub unametouid
{
    my ($self, $uid) = @_;

    unless ($uid =~ m/^\d+$/) {
        my $username = $uid;
        $uid = $self->uidbyname($username);
        unless ($uid) {
            $self->modwheel->throw('user-no-such-user');
            $self->modwheel->logerror("Convert username to UID) No such user: $username");
            return undef;
        }
    }

    return $uid
}

sub get
{
    my ($self, $uid) = @_;
    my $db = $self->db;

    unless ($uid) {
        $self->modwheel->throw('user-missing-field');
        $self->modwheel->logerror('Get User: Missing username or uid.');
        return undef;
    }

    $uid = $self->unametouid($uid);
    return undef unless $uid;
        
    my $query = $db->build_select_q('users',
        [qw(id username password last_ip real_name groups email comments)],
        {id => '?'}
    );
    my $user = $db->fetchonerow_hash($query, $uid);
    unless (ref $user) {
        $self->modwheel->throw('user-no-such-user');
        $self->modwheel->logerror("User get: No such user id: $uid");
        return undef;
    }
    return $user;
}    

sub delete
{
    my ($self, $uid) = @_;
    my $db = $self->db;
    
    unless ($uid) {
        $self->modwheel->throw('user-missing-field');
        $self->modwheel->logerror('Delete User: Missing username or uid.');
        return undef;
    };
    
    $uid = $self->unametouid($uid);
    return undef unless $uid;

    my $query = $db->build_delete_q('users', {id => '?'});
    my $ret   = $db->exec_query($query, $uid);

    unless ($ret) {
        $self->modwheel->throw('user-no-such-user');
        $self->modwheel->logerror("User delete: Couldn't delete user: No such user id: $uid");
    } else {
        return $ret;
    }
}

# #### CLASS METHODS

sub mkpasswd
{
    my $len = shift;
    # if someone used as a instance method, select the next argument.
    $len    = shift if ref $len;

    $len  ||= 8;
    my $passwd;
    #my @chars = (0 .. 9, 'A' .. 'Z', 'a' .. 'z', '!', '#', '$', '%');
    my @chars  = (0 .. 9, 'A' .. 'Z', 'a' .. 'z');
    $passwd   .= $chars[rand @chars] for 1 .. $len;

    return $passwd;
}

sub hashcookie_encipher
{
    my $password = shift;

    $password   = substr $password, 0, 8;
    $password  .= '~' until length $password == 8;
    my $salt    = Modwheel::User::mkpasswd(BLOWFISH_OW_SALT_SIZE);
    my $hash    = Crypt::Eksblowfish::Bcrypt::bcrypt_hash({
        key_nul => BLOWFISH_OW_KEY_NUL,
        cost    => BLOWFISH_OW_COST,
        salt    => $salt
    }, $password);

    my $hashb64    = Crypt::Eksblowfish::Bcrypt::en_base64($hash);
    my $hashcookie = $salt . $hashb64;

    return $hashcookie;
}

sub hashcookie_compare
{
    my ($hashcookie, $password) = @_;
    $password   = substr $password, 0, 8;
    $password  .= '~' until length $password == 8;

    my $salt    = substr $hashcookie, 0, BLOWFISH_OW_SALT_SIZE ;
    my $hashb64 = substr $hashcookie, BLOWFISH_OW_SALT_SIZE, length($hashcookie);

    my $cmphash = Crypt::Eksblowfish::Bcrypt::bcrypt_hash({
        key_nul => BLOWFISH_OW_KEY_NUL,
        cost    => BLOWFISH_OW_COST,
        salt    => $salt
    }, $password);

    my $cmphashb64 = Crypt::Eksblowfish::Bcrypt::en_base64($cmphash);

    if ($hashb64 eq $cmphashb64) {
        return 1;
    }
    else {
        return 0;
    }

}

1

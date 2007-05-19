# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/DB/Base.pm - Interface for Modwheel database drivers.
#   All Database drivers inherits this class, so if a method is not portable
#   with the current driver it can override the method.
# (c) 2007 Ask Solem <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# $Id: Base.pm,v 1.13 2007/05/18 23:42:38 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/DB/Base.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.13 $
# $Date: 2007/05/18 23:42:38 $
#####
package Modwheel::DB::Base;
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw(:std);
use base 'Modwheel::Instance';
use version; our $VERSION = qv('0.3.1');
{
    use DBI;
    use Carp         qw(confess carp croak cluck longmess shortmess);
    use Params::Util ('_HASH', '_ARRAY', '_CODELIKE');
    use Scalar::Util qw(blessed);

    #========================================================================
    #                     -- OBJECT ATTRIBUTES --
    #========================================================================

    public dbh           => my %dbh_for,           {is => 'rw'};
    public raise_error   => my %raise_error_for,   {is => 'rw'};
    public print_error   => my %print_error_for,   {is => 'rw'};
    public prepare_cache => my %prepare_cache_for, {is => 'rw'};
    public connected     => my %connected_for,     {is => 'ro'};

    #========================================================================
    #                     -- PUBLIC INSTANCE METHODS --
    #========================================================================

    #------------------------------------------------------------------------
    # ->connect({username => $username, password => $password})
    #
    # Connect to the database.
    # If no username or password is specified it look for them in the
    # configuration file instead.
    #------------------------------------------------------------------------
    sub connect {
        my ($self, $arg_ref) = @_;
        my $modwheel = $self->modwheel;

        # Handle arguments and configuration.
        my $dbconfig    = $modwheel->siteconfig->{database};
        my $dsn         = $self->create_dsn($arg_ref);
        my $username    = $arg_ref->{username}   || $dbconfig->{username};
        my $password    = $arg_ref->{password}   || $dbconfig->{password};
        my $raise_error = $arg_ref->{RaiseError} || $self->RaiseError;
        my $print_error = $arg_ref->{PrintError} || $self->PrintError;

        if ($arg_ref->{prepare_cache}) {
            $self->prepare_cache(1);
        }

        my @dbh_config = (
            $dsn, $username, $password,
            {
                RaiseError  => $raise_error,
                PrintError  => $print_error,
                #HandleError => sub { },
            },
        );


        my $dbh = $arg_ref->{cached} ?  DBI->connect_cached( @dbh_config )
                                     :  DBI->connect( @dbh_config )
        ;

        # should always check the return of connect, so we don't continue
        # without a database handle.
        if (!blessed $dbh) {
            return $self->modwheel->throw('db-connection-error',
                $dbconfig->{name},
                $self->errstr
            );
        }

        $self->_set_dbh($dbh);
        $self->_set_connected(1);

        if (defined $ENV{MW_DBI_TRACE}) {
            $self->trace(1);
        }

        return 1;
    }


    #------------------------------------------------------------------------
    # ->connect_cached( \%arg )
    #
    # Shortcut to $self->connect({ cached => 1 })
    #------------------------------------------------------------------------
    sub connect_cached {
        my ($self, $arg_ref) = @_;
        $arg_ref         ||= { };
        $arg_ref->{cached} =  1;
        return $self->connect($arg_ref);
    }

    #------------------------------------------------------------------------
    # ->create_dsn()
    #
    # Method to create a dsn for DBI. see perldoc DBI for more info.
    #------------------------------------------------------------------------
    sub create_dsn {
        my ($self) = @_;
        my $modwheel = $self->modwheel;
        $modwheel->logwarn( $modwheel->get_l10n_string('db-no-driver') );
        return 1;
    }

    #------------------------------------------------------------------------
    # ->driver_requires()
    #
    # If the current driver requires any additional perl modules, a list
    # of them should be returned by this function. The base database module
    # does not require any additional modules, so this is just a prototype
    # that other database drivers can inherit and override.
    #------------------------------------------------------------------------
    sub driver_requires {
        return;
    }

    #------------------------------------------------------------------------
    # ->disconnect()
    #
    # Disconnect from the database.
    #------------------------------------------------------------------------
    sub disconnect {
        my ($self) = @_;
        my $dbh = $self->dbh;
        $self->_set_connected(0);
        return $dbh->disconnect() if blessed $dbh;
        return;
    }

    #------------------------------------------------------------------------
    # ->autocommit($bool_autocommit)
    #
    # If set to 0 no changes to the database will be made until a commit().
    #------------------------------------------------------------------------
    sub autocommit {
        my ($self, $bool_autocommit) = @_;
        my $dbh = $self->dbh;
        $dbh->{AutoCommit} = $bool_autocommit;
        return;
    }

    #------------------------------------------------------------------------
    # ->commit()
    #
    # If autocommit is set to 0, this will apply all changes to the database
    # since the last commit().
    #------------------------------------------------------------------------
    sub commit {
        my ($self) = @_;
        my $dbh = $self->dbh;
        return $dbh->commit();
    }

    #------------------------------------------------------------------------
    # ->rollback()
    #
    # If autocommit is set to 0, this will discard and rollback all changes
    # since the last commit().
    #------------------------------------------------------------------------
    sub rollback {
        my ($self) = @_;
        my $dbh = $self->dbh;
        return $dbh->rollback();
    }

    #------------------------------------------------------------------------
    # ->errstr()
    #
    # Returns the last error in the underlying database system.
    #------------------------------------------------------------------------
    sub errstr {
        return $DBI::errstr;
    }

    #------------------------------------------------------------------------
    # ->PrintError($bool_print_error)
    #
    # If set to true, all errors will be printed to stderr.
    #------------------------------------------------------------------------
    sub PrintError {
        my ($self, $bool_print_error) = @_;
        my $dbh = $self->dbh;

        if (defined $bool_print_error) {
            $self->set_print_error($bool_print_error);
            if (blessed $dbh) {
                $self->dbh->{PrintError} = $bool_print_error;
            }
        }

        return $self->print_error || 1;
    }

    #------------------------------------------------------------------------
    # ->RaiseError($bool_raise_error)
    #
    # If set to true, all errors from DBI will result in a die().
    #------------------------------------------------------------------------
    sub RaiseError {
        my ($self, $bool_raise_error) = @_;
        my $dbh = $self->dbh;

        if (defined $bool_raise_error) {
            $self->set_raise_error($bool_raise_error);
            if (blessed $dbh) {
                $self->dbh->{RaiseError} = $bool_raise_error;
            }
        }

        return $self->raise_error || 0;
    }

    #------------------------------------------------------------------------
    # ->trace(int $level, $sth);
    #
    # Set the trace level for debug messages. See 'perldoc DBI' for more
    # information.
    #------------------------------------------------------------------------
    sub trace {
        my ($self, $level, $sth) = @_;

        blessed $sth
            ? $sth->trace($level)
            :  DBI->trace($level);

        return;
    }

    #------------------------------------------------------------------------
    # ->prepare($query)
    #
    # Prepare a database query for execution.
    # Returns: $sth
    #------------------------------------------------------------------------
    sub prepare {
        my ($self, $query) = @_;
        my $modwheel       = $self->modwheel;
        my $dbh            = $self->dbh;

        confess "prepare('$query'): missing dbh (not connected?)"
            if not blessed($dbh);

        # Show the query in debug mode.
        my ($package, $filename, $line, $sub) = caller;
        if ($modwheel->debug) {
            if (!defined $query) {
                $modwheel->throw('db-prepare-without-query');
                my $trace = longmess('Missing query for database prepare()');
                $modwheel->logerror(
                    "[$package|$sub|$line|$filename]: $trace");
                return;
            }
            else {
                $modwheel->loginform(
                    "[$package|\$sub|$line|$filename]: $query\n");
            }
        }

        # prepare the query...
        my $sth = $self->prepare_cache ?  $dbh->prepare_cached($query)
                                       :  $dbh->prepare($query);

        # and catch errors if there is any.
        if (!$sth) {
            $modwheel->throw('db-prepare-query-error', $query, $self->errstr);
            $sth->finish();
            return;
        }

        return $sth;
    }

    #------------------------------------------------------------------------
    # ->execute($sth, @bind_vars)
    #
    # Execute a prepared query.
    #------------------------------------------------------------------------
    sub execute {
        my ($self, $sth, @bind_vars) = @_;
        return $sth->execute(@bind_vars);
    }

    #------------------------------------------------------------------------
    # ->rows($sth)
    #
    # Returns the number of rows matching/affecting the last query.
    #------------------------------------------------------------------------
    sub rows {
        my ($self, $sth) = @_;
        return $sth->rows;
    }

    #------------------------------------------------------------------------
    # ->query($query, @bind_vars)
    #
    # Shortcut for prepare and execute in one, returns an $sth.
    #------------------------------------------------------------------------
    sub query {
        my ($self, $query, @bind_vars) = @_;
        my $modwheel              = $self->modwheel;
        my $dbh                   = $self->dbh;

        my $sth = $self->prepare($query);
        my $ret = $self->execute($sth, @bind_vars);
        return $modwheel->throw('db-execute-query-error', $query, $self->errstr)
            if !$ret;

        return $sth;
    }

    #------------------------------------------------------------------------
    # ->query_end($sth)
    #
    # End the running (executed) query in $sth.
    #------------------------------------------------------------------------
    sub query_end {
        my ($self, $sth) = @_;
        cluck 'Call to query_end, but no query in use.'
            if not blessed $sth;
        return $sth->finish();
    }

    #------------------------------------------------------------------------
    # ->fetchrow_array($sth)
    #
    # Fetch the current row from the executing query in $sth as a array ref.
    #------------------------------------------------------------------------
    sub fetchrow_array {
        my ($self, $sth) = @_;
        cluck 'Call to fetchrow_array, but no query in use.'
            if not blessed $sth;
        return $sth->fetchrow_arrayref();
    }

    #------------------------------------------------------------------------
    # ->fetchrow_hash($sth)
    #
    # Fetch the current row from the executing query in $sth as a hash ref.
    #------------------------------------------------------------------------
    sub fetchrow_hash {
        my ($self, $sth) = @_;
        cluck 'Call to fetchrow hash, but no query in use.'
            if not blessed $sth;
        return $sth->fetchrow_hashref();
    }

    #------------------------------------------------------------------------
    # ->fetchonerow_array($query, @bind_vars)
    #
    # Use this if you only want to fetch one array row from your query.
    #------------------------------------------------------------------------
    sub fetchonerow_array {
        my ($self, $query, @bind_vars) = @_;
        my $sth = $self->query($query, @bind_vars) or return;
        my $ret = $self->fetchrow_array($sth);
        $self->query_end($sth);
        return $ret;
    }

    #------------------------------------------------------------------------
    # ->fetch_onerow_hash($query, @bind_vars)
    #
    # Use this if you only want to fetch one hash row from your query
    #------------------------------------------------------------------------
    sub fetchonerow_hash {
        my ($self, $query, @bind_vars) = @_;
        my $sth = $self->query($query, @bind_vars) or return;
        my $ret = $self->fetchrow_hash($sth);
        $self->query_end($sth);
        return $ret;
    }

    #------------------------------------------------------------------------
    # ->fetch_singlevar($query, @bind_vars)
    #
    # If you only want to fetch one cell from the database you can use this
    # method.
    #------------------------------------------------------------------------
    sub fetch_singlevar {
        my ($self, $query, @bind_vars) = @_;

        my $sth    = $self->query($query, @bind_vars) or return;
        my $result = $self->fetchrow_array($sth);
        $self->query_end($sth);

        return $result->[0] if _ARRAY($result);

        return;
    }

    #------------------------------------------------------------------------
    # ->exec_query($query, @bind_vars)
    #
    # Can be used for executing a query when you don't need any data from it.
    # i.e instead of writing:
    #       my $delete_object_id = shift;
    #       my $query = $db->build_delete_q('object', { id => '?' });
    #       my $sth = $db->prepare($query);
    #       my $ret = $db->execute($sth, $delete_object_id);
    #       $db->query_end($sth);
    #       return $ret;
    # You can write:
    #       my $delete_object_id = shift;
    #       my $query = $db->build_delete_q('object', { id => '?' });
    #       my $ret   = $db->exec_query($query, $delete_object_id);
    #       return $ret;
    #------------------------------------------------------------------------
    sub exec_query {
        my ($self, $query, @bind_vars) = @_;

        my $sth    = $self->query($query, @bind_vars) or return;
        my $retval = $sth->rows;
        $self->query_end($sth);

        return $retval || 0;
    }

    #------------------------------------------------------------------------
    # ->current_timestamp()
    #
    # Fetch the current time as a string.
    # This is the stringified data representation to use in database
    # fields.
    #------------------------------------------------------------------------
    sub current_timestamp {
        my ($self) = @_;
        my $timestamp = $self->fetch_singlevar('SELECT CURRENT_TIMESTAMP');
        return $timestamp;
    }

    #------------------------------------------------------------------------
    # ->fetch_next_id($table, $optional_primary_key_name)
    #
    # Get the next available id available for a database table.
    # If the primary key name is not specified it is default to 'id'.
    #------------------------------------------------------------------------
    sub fetch_next_id {
        my ($self, $table, $optional_primary_key_name) = @_;
        my $primary_key = 'id';
        $table = $self->sqlescape($table);

        if ($optional_primary_key_name) {
            $primary_key = $optional_primary_key_name;
            $primary_key = $self->sqlescape($primary_key);
        }

        my $next_id = $self->fetch_singlevar(
            "SELECT MAX($primary_key) + 1 FROM $table");
        $next_id ||= 1;

        return $next_id;
    }

    #------------------------------------------------------------------------
    # ->build_insert_q($table, $fields_ref)
    #
    # Build a query to use for inserting new data into the database.
    #------------------------------------------------------------------------
    sub build_insert_q {
        my ($self, $table, $fields_poly) = @_;

        my $fields_ref = $self->_polymorphic_ref_to_array($fields_poly);

        my $fields_sorted = join q{, }, @{$fields_ref};
        my $bind_values   = join q{, }, map {q{?}} @{$fields_ref};

        my $query = qq{
            INSERT INTO $table($fields_sorted) VALUES($bind_values)
        };

        return $query;
    }

    #------------------------------------------------------------------------
    # ->build_update_q(table, $fields_ref, $where_ref)
    #
    # Build a query to use for updating existing data in the database.
    #------------------------------------------------------------------------
    sub build_update_q {
        my ($self, $table, $fields_poly, $where_ref) = @_;

        my $fields_ref = $self->_polymorphic_ref_to_array($fields_poly);

        my $fields_str   .= join q{, }, map {"$_=?"} @{$fields_ref};

        my $where_clause = $self->_build_where_clause($where_ref);
        return $self->modwheel->throw('db-build-query-missing-where')
            if !$where_clause;

        my $query = qq{
            UPDATE $table SET $fields_str WHERE $where_clause
        };

        return $query;
    }

    #------------------------------------------------------------------------
    # ->build_select_q($table, $select, $match_ref, $options_ref)
    #
    # Build a query to use for fetching data from the database.
    #------------------------------------------------------------------------
    sub build_select_q {
        my ($self, $table, $select_poly, $match_ref, $options_ref) = @_;
        return $self->_build_q('SELECT',$table, $select_poly, $match_ref,
            $options_ref);
    }

    #------------------------------------------------------------------------
    # ->build_delete_q($table, $match_ref, $options_ref)
    #
    # Build a query to use for deleting data from the database.
    #------------------------------------------------------------------------
    sub build_delete_q {
        my ($self, $table, $match_ref, $options_ref) = @_;

        return $self->_build_q('DELETE', $table, undef, $match_ref,
            $options_ref);
    }

    #------------------------------------------------------------------------
    # ->quote($string)  :DEPRECATED
    #
    # This method is deprecated, use ->sqlescape($string) instead.
    #------------------------------------------------------------------------
    sub quote {
        my ($self, $string) = @_;
        if (!blessed $self) {
            $string = $self;
        }

        # Don't continue if the string is just a number
        return $string if $string =~ m/^\d+$/xms;

       # Replace all occurences of ' (power quote) with '' (two power quotes).
        $string =~ s/'/''/xmsg;

        return $string;
    }

    #------------------------------------------------------------------------
    # ->sqlescape($string)
    #
    # Quote unsafe characters from a string so it is safe to use in a SQL
    # query.
    #------------------------------------------------------------------------
    sub sqlescape {
        my ($self, $string) = @_;
        if (!blessed $self) {
            $string = $self;
        }

        # Replace all occurences of ' (power quote) with '' (two power quotes)
        $string =~ s/'/''/xmsg;

        # Replace all occurences of ? (question mark) with \?
        # (backslash-questionmark)
        $string =~ s/\?/\\?/xmsg;

        return $string;
    }

    #------------------------------------------------------------------------
    # ->trim($string);
    #
    # Remove leading and trailing whitespace from string.
    #------------------------------------------------------------------------
    sub trim{
        my ($self, $string) = @_;
        if (!blessed $self) {
            $string = $self;
        }

        # Remove leading spaces.
        $string =~ s/^ \s*  //xmsg;

        # Remove trailing spaces.
        $string =~ s/  \s* $//xmsg;

        return $string;
    }

    #------------------------------------------------------------------------
    # ->maintainance()
    #
    # This is the prototype for the maintainance method.
    # Base does not need any maintainance, but databases like PostgreSQL do.
    #------------------------------------------------------------------------
    sub maintainance {
        return 1;
    }
    #------------------------------------------------------------------------
    # ->insert($table, \[@%$]fields, @bindvars)
    #
    # my $ret = $self->insert('tags', ['name'], $tag_name);
    #------------------------------------------------------------------------
    sub insert {
        my ($self, $table, $fields_poly, @bindvars) = @_;
        
        my $q = $self->build_insert_q($table, $fields_poly);
        return if ! $q;

        return $self->exec_query($q, @bindvars);
    }

    #------------------------------------------------------------------------
    # ->update($table, \[@%$]fields, \[@%$]where, @bindvars)
    #------------------------------------------------------------------------
    sub update {
        my ($self, $table, $fields_poly, $where_poly, @bindvars) = @_;
        
        my $q = $self->build_update_q($table, $fields_poly, $where_poly);
        return if ! $q;
        
        return $self->exec_query($q, @bindvars);
    }

    #------------------------------------------------------------------------
    # ->delete($table, \[@%$]where, @bindvars)
    #------------------------------------------------------------------------
    sub delete {
        my ($self, $table, $where_poly, @bindvars) = @_;

        my $q = $self->build_delete_q($table, $where_poly);
        return if ! $q;

        return $self->exec_query($q, @bindvars);
    }

    #========================================================================
    #                     -- PRIVATE INSTANCE METHODS --
    #========================================================================

    #------------------------------------------------------------------------
    # ->_set_dbh(DBI::dbh)
    #
    # Set the private dbh attribute.
    # ->dbh() is the actual object we are adapting to.
    #------------------------------------------------------------------------
    sub _set_dbh {
        my ($self, $dbh)   = @_;
        $dbh_for{ident $self} = $dbh;
        return;
    }

    #------------------------------------------------------------------------
    # ->_set_connected($bool_connected)
    #
    # Sets our connection status. There is no reason why this method should
    # be public, as the only way to connect to the database should be in
    # the object the Modwheel::DB factory creates. (atleast for now).
    #------------------------------------------------------------------------
    sub _set_connected {
        my ($self, $bool_connected)   = @_;
        $connected_for{ident $self} = $bool_connected;
        return;
    }

    #------------------------------------------------------------------------
    # ->_build_where_clause($match_ref)
    #
    # Private method for creating a SQL99-style WHERE clause. It is used by
    # build_select_q and friends.
    #------------------------------------------------------------------------
    sub _build_where_clause {
        my ($self, $match_ref) = @_;
        my $is_hash = 0;
        if(_ARRAY($match_ref)) {
            my $query;
            my $num_pats = $#{$match_ref};
            my $count;
            for my $attribute (@{$match_ref}) {
                $query .= q{(} . $attribute . q{=?} . q{) };
                if (++$count <= $num_pats) {
                    $query .= ' AND ';
                }
            }
            return $query;
        }

        return if !_HASH($match_ref);

        my $query;
        my $num_pats = scalar keys %{$match_ref};
        my $count    = 1;
        for my $attribute (sort keys %{$match_ref}) {
            my $pat = $match_ref->{$attribute};

           # We can change the operator to something else than the default (=)
           # with i.e _build_where_clause({ people => '%op=LIKE% });.
           # this will change the operator to LIKE.
            my $operator = q{=};
            if ($pat =~ s/^ \%op= (.+?) \% //xms) {
                $operator = $1;
            }

            $query .= '(';
            $pat   =~ tr/ //d;
            my @subpats      = split m/ [,] /xms, $pat;
            my $subpat_count = 0;
            foreach my $subpat (@subpats) {
                $query .= $attribute . q{ } . $operator . q{ } . $subpat;
                if ($subpat_count < $#subpats) {
                    $query .= ' OR ';
                }
                $subpat_count++;
            }

            $query .= ')';
            $count++;
            if ($count <= $num_pats)  {
                $query .= ' AND ';
            }
        }

        return $query;
    }

    #------------------------------------------------------------------------
    # ->polymorphic_ref_to_array(\@ref || \%ref || $scalar)
    #
    # Convert a reference to an array.
    #------------------------------------------------------------------------
    sub _polymorphic_ref_to_array {
        my ($self, $var_poly) = @_;

        my @new_array;
        if(_ARRAY($var_poly)) {
            return if not scalar @{$var_poly};
            @new_array = @{$var_poly};
        }
        elsif(_HASH($var_poly)) {
            return if not scalar keys %{$var_poly};
            @new_array = sort keys %{$var_poly};
        }
        else { # SCALAR
            return if not defined $var_poly;
            push @new_array, $var_poly;
        }

        return \@new_array;
    }

    #------------------------------------------------------------------------
    # ->_build_q($command, $tables, $select, $match, $options)
    #
    # Private method used by build_select_q and friends for making
    # sql statements.
    #------------------------------------------------------------------------

    sub _build_q {
        my ($self, $command, $tables_poly, $select_poly, $match_ref,
            $options_ref)
            = @_;
        my $modwheel = $self->modwheel;

        # tables is polymorphic
        # expand tables if table is an hash or array reference.
        my $table;
        if (_HASH($tables_poly)) {
            while (my($orig_table, $as) = each %{$tables_poly}) {
                $table .= "$orig_table $as,";
            }
            chop $table;
        }
        elsif (_ARRAY($tables_poly)) {
            $table = join q{, }, @{$tables_poly};
        }
        else { # SCALAR
            $table = $tables_poly;
        }
        confess 'build_q missing database table' if !$table;

       # select is also polymorphic
       # if it's an array reference it joins the list to a string separated by
       # comma.
        my $select = _ARRAY($select_poly)
            ? join q{, }, @{$select_poly}
            : $select_poly;

        if ($command eq 'SELECT' && defined $select) {
            $select ||= q{*};
        }
        else {
            $select = q{};
        }

        my $where;
        if (defined %{$match_ref}) {
            $where = $self->_build_where_clause($match_ref);
        }

        if ($command eq 'DELETE' && !$where) {
            return $modwheel->throw('db-build-delete-query-missing-where');
        }

        my %option_statements = (
            'order'     => ' ORDER BY %s',
            'group'     => ' GROUP BY %s',
            'limit'     => ' LIMIT  %d',
            'offset'    => ' OFFSET %d',
        );

        my $options;
        while (my ($option, $format_string) = each %option_statements) {
            if (defined $options_ref->{$option}) {
                $options .= sprintf $format_string, $options_ref->{$option};
            }
        }

        my $query = qq{
            $command $select FROM $table
        };
        if ($where) {
            $query .= " WHERE $where";
        }
        if ($options) {
            $query .= $options;
        }

        return $query;
    }

};

1;
__END__

=pod

=head1 NAME

Modwheel::DB::Base - Generic Modwheel database class.

=head1 SYNOPSIS

        my $modwheel = Modwheel->new($modwheel_config);
        my $db = Modwheel::DB->new({
            modwheel => $modwheel;
        });

        $db->connect || die $modwheel->error;
        
        # [...]

        $db->disconnect;

=head1 DESCRIPTION

=head2 PURPOSE

Modwheel::DB automaticly chooses the database driver you 
specify in the configuration, you don't use this class
directly.

This class defines the Modwheel::DB interface and also defines
default methods that other database classes can override.

Usually all Modwheel database classes inherits this class.

You can also see the documentation for these classes:

=over 4

=item * L<Modwheel::DB>

=item * L<Modwheel::DB::MySQL>

=item * L<Modwheel::DB::PostgreSQL>

=item * Modwheel::DB::[...]

=back

=head2 HOW TO SUBCLASS

To create your own class, say Modwheel::DB::Weird, that inherits all methods
from Modwheel::DB::Base and overrides the fetch_next_id() method, you can
do something like this:

    package Modwheel::DB::Weird;
    use strict;
    use warnings;
    use base qw( Modwheel::DB::Base );
    use version; $VERSION = qv('0.0.1');
    use Class::InsideOut::Policy::Modwheel qw(:std);
    use Acme::Bee::Bumblebee qw();
    {
   
        # this driver requires module Acme::Bee::Bumblebee to be installed.
        sub driver_requires {
            return qw( Acme::Bee::Bumblebee ); 
        }

        sub fetch_next_id {
            my($self, $table, $optional_primary_key_name) = @_;
            my $new_id = $self->SUPER::fetch_next_id(@_);

            # be sure that this id is not taken by any bumblebees!
            while (Acme::Bee::Bumblebee->has_bee($new_id)) {
                $new_id = $self->SUPER::fetch_next_id(@_);
            }

            return $new_id;
        }
    
    }
    1; # Magic true return value.

And then in your configuration file:

    Site:
      RalphsWonderfulWorldOfBees:
        database:
          name: bees
          type: Weird
          username: ralph
          password: definityinfinity

=head1 SUBROUTINES/METHODS

=head2 INSTANCE METHODS

=over 4

=item C<$db-E<gt>connect()>

Connect to the database.

Uses the database configuration of the current site to connect to the database.
If a connection was established this function sets $db-E<gt>connected to 1 and returns 1.
Otherwise it sets $db->errstr to contain a description of the error and returns undef.

=item C<$db-E<gt>driver_requires()>

Returns a list of perl modules required for this driver to work.

=item C<$db-E<gt>disconnect()>

Disconnect from the database.

Sets $db->connected to 0 and disconnects from the database if a connection is open.


=item C<$db-E<gt>autocommit($bool_autocommit)>

If this is set, the database will automatically commit database transations.

=item C<$db-E<gt>commit()>

When autocommit is off, this method will commit the current database transation.

=item C<$db-E<gt>rollback()>

When autocommit is off, this method can be used to rollback all changes since the start of the
current transaction.

=item C<$db-E<gt>errstr()>

Holds a description of the last error that occured.

=item C<$db-E<gt>PrintError($bool_print_error)>

If this is set, the database driver will print the contents of $db->errstr when
any error occurs. This option is on by default.

=item C<$db-E<gt>RaiseError($bool_raise_error)>

If this is set, the database driver will print the contents of $db->errstr and _exit_ the running program 
when any error occurs. This option is off by default.

=item C<$db-E<gt>trace($trace_level)>

If this is set, the database driver will print verbose debugging information for any
database action. This option is off by default.

=item C<$db>-E<gt>connected>

Will return true if we have a open database connection, false if not.
Note however that we can't trust the output of this method.


=item C<$db-E<gt>prepare($query)>

Prepare a query for execution.

Example:

    # Select all objects that has root as parent.
    my $query = $db->build_select_q('object', '*', {parent => 1});
    
    # Prepare and execute the query.
    my $sth = $db->prepare($query);
    $db->execute($sth);

    # iterate over the results.
    while (my $hres = $db->fetch_hashref($sth)) {
        print $hres->{name}
    }
    # always remember to end a prepared query:
    $db->query_end($sth);


=item C<$db-E<gt>execute($sth, @bind_variables)>

Execute a prepared query. If you have a query with bind variables, attach them to this methods arguments.

Example:
    
    # select objects by id. the '?' means that we want to bind the variable later.
    my $query = $db->build_select_q('object', '*', {id => '?'});

    # prepare and execute the query using bind variables:
    my $id_to_fetch = 2;
    my $sth = $db->prepare($query);
    $db->execute($sth, $id_to_fetch);

    [ ... work on the result ... ]

    $db->query_end($sth);


=item C<$db-E<gt>query($query)>

Shortcut function for both prepare() and execute().
Returns back the query handle if everything went ok.
NOTE: Remember to use $db->query_end($sth) when finished using this handle.


=item C<$db-E<gt>query_end($sth)>

End a query started by prepare() or query().


=item C<$db-E<gt>fetchrow_array($sth)>

Returns an array reference to the data returned by the current query.


=item C<$db-E<gt>fetchrow_hash($sth)>

Returns a hash reference to the data returned by the current query.


=item C<$db-E<gt>fetchonerow_array($query, @bind_varuables)>

Returns a arrayref to the data in the first row returned by query.
It's a shortcut for writing:

    my $query = "[...]";
    my $sth   = $db->prepare($query);
    $sth->execute($query, @bind_variables);
    my $arrayref = $db->fetchrow_array($sth);
    $db->query_end($sth);


=item C<$db-E<gt>fetchonerow_hash($query, @bind_variables)>

Same as fetchonerow_array but returns a hash reference instead.
 

=item C<$db-E<gt>fetch_singlevar($query)>

Return the first element from the first row of a query.                                                                                  


=item C<$db-E<gt>exec_query($query)>

If you have a query that just executes a command but does not fetch anything, 
this is the ideal function to use.
RETURNS: the number of rows affected by the query.


=item C<$db-E<gt>current_timestamp()>

Get the current timestamp from the database as a string.


=item C<$db-E<gt>fetch_next_id($table, $optional_primary_key_name)>

Return the next available id from a table.


=item C<$db-E<gt>build_insert_q($from_table, %$fields)>

Build a insert query.

Arguments:

=over 4

=item    from_table

The table to insert data to.

=item     %$fields

Fields to insert, this list must be sorted alphabetically so we can map the
bind variables in order.

=back

=item C<$db-E<gt>build_update_q($from_table, %$fields, %$where)>

Build a update query.

Arguments:

=over 4

=item from_table

The table to update data in.

=item %$fields

Fields to update, 

=item %$where    

Only update fields matching i.e {parent => '?', active => 1}
this list must be sorted alphabetically so we can map the bind variables in order.

=back

=item C<$db-E<gt>build_select_q($from_table, %$fields, %$options)>

Build a select query.

Arguments:

=over 4

=item from_table

The table to select data from.

=item %$fields

Fields to select.

=item %$where    

Only select fields matching i.e {parent => '?', active => 1}
this list must be sorted alphabetically so we can map the bind variables in order.

=item %$options    

The following options are available:

=over 8

=item order

which field(s) to order by. i.e  ( {order => 'name,id DESC'} )

=item limit

limit the number of matches. i.e ( {limit => 10 } ).

=item offset

skip the n first numbers.

=back

=back

=item C<$db-E<gt>build_delete_q($from_table, %$fields, %$options)>

Build a delete query.

Arguments:

=over 4

=item from_table

The table to delete data from.

=item %$fields

Fields to select.

=item %$where

Only delete fields matching i.e {parent => '?', active => 1}
this list must be sorted alphabetically so we can map the bind variables in order.

=item %$options

The following options are available:

=over 8

=item limit

limit the number of rows to delete. i.e ( {limit => 10 } ).

=item offset

skip the n first rows.

=back

=back

=item C<$db-E<gt>quote($string)>

Quote characters in a string that will interfere in our database operations.


=item C<$db-E<gt>sqlescape($string)>

Quote characters in a string that will interfere in our database operations.


=item C<$db-E<gt>trim($string)>

Remove leading and trailing whitespace from a string.


=item C<$db-E<gt>maintainance()>

Perform database maintainance.

=item C<$db-E<gt>create_dsn()>

Inherited drivers must define this function to create the database
configuration.

=back

=head2 PRIVATE METHODS

These are methods to be used internally in _this class or a sub-class only_
never used them from the outside world.

=over 4

=item C<$db-E<gt>_set_connected(int $bool_connected)>

Private: Set the current connection status.

=item C<$db-E<gt>dbh()>

Private: Access the current database handler object.

=item C<$db-E<gt>_set_dbh($dbh)>

Private: Sets the current database handler object.

=item  C<$db-E<gt>_build_q()>

Private helper function for the build_*_q functions.


=item C<$db-E<gt>_build_where_clause>

Private helper function for the build_*_q functions.

=back

=head1 INHERITANCE

This class inherits from Modwheel::Instance.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

See L<Modwheel::Manual::Config>

=head1 DEPENDENCIES


=over 4

=item * DBI

=item * Params::Util

=item * version

=back


=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

The Modwheel website: L<http://www.0x61736b.net/Modwheel/>

=head1 VERSION

v0.3.1

=head1 AUTHOR

Ask Solem, F<< ask@0x61736b.net >>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 by Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut


# Local variables:                                                                                                          
# vim: ts=4

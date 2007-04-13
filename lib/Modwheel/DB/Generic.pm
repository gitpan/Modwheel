package Modwheel::DB::Generic;
use strict;
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Modwheel/DB/Generic.pm - Generic database functions.
#   All Database drivers inherits this class, so if a method is not portable
#   with the current driver it can override the method.
# (c) 2007 Ask Solem Hoel <ask@0x61736b.net>
#
# See the file LICENSE in the Modwheel top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
our @ISA = qw(Modwheel::Instance);
use DBI;
use Carp;

=head1 NAME

Modwheel::DB::Generic - Generic Modwheel database class.

=head1 ABSTRACT

All Modwheel database interface classes should inherit this class.

=head1 INHERITANCE

This class inherits from Modwheel::Instance.

=head1 EXPORT

None.

=head1 INSTANCE METHODS

=over 4

=item C<$db-E<gt>connect()>

Connect to the database.

Uses the database configuration of the current site to connect to the database.
If a connection was established this function sets $db-E<gt>connected to 1 and returns 1.
Otherwise it sets $db->errstr to contain a description of the error and returns undef.

=cut
sub connect
{
    my $self = shift;
    my $dbconfig = $self->modwheel->siteconfig->{database};
    my $dsn = $self->create_dsn;

    my $dbh = DBI->connect($dsn,
        $dbconfig->{username},
        $dbconfig->{password},
        {
            RaiseError => 0,
            PrintError => 1,
        },
    );
    # should always check the return of connect, so we don't continue without a
    # database handle.
    unless (ref $dbh) {
        $self->modwheel->throw('db-connection-error');
        $self->modwheel->logerror(
            "Couldn't connect to database '$dbconfig->{name}'\@'$dbconfig->{host}': ",
            $self->errstr);
        return undef;
    }

    $self->set_dbh($dbh);
    $self->set_connected(1);

    if (defined $ENV{MW_DBI_TRACE}) {
        $self->trace(1);
    }

    return 1;
}    

=item C<$db-E<gt>disconnect()>

Disconnect from the database.

Sets $db->connected to 0 and disconnects from the database if a connection is open.

=cut
sub disconnect
{
    my $self = shift;
    $self->set_connected(0);
    return $self->dbh->disconnect() if $self->dbh;
}

=item C<$db-E<gt>dbh()>

Private: Access the current database handler object.

=cut
sub dbh
{
    return $_[0]->{_DB_HANDLER_};
}

=item C<$db-E<gt>set_dbh($dbh)>

Private: Sets the current database handler object.

=cut
sub set_dbh
{
    my ($self, $dbh) = @_;
    $self->{_DB_HANDLER_} = $dbh;
}

=item C<$db-E<gt>autocommit($bool_autocommit)>

If this is set, the database will automatically commit database transations.

=cut
sub autocommit
{
    my ($self, $autocommit) = @_;
    $self->dbh->{AutoCommit} = $autocommit;
}

=item C<$db-E<gt>commit()>

When autocommit is off, this method will commit the current database transation.

=cut
sub commit
{
    return $_[0]->dbh->commit();
}

=item C<$db-E<gt>rollback()>

When autocommit is off, this method can be used to rollback all changes since the start of the
current transaction.

=cut
sub rollback
{
    return $_[0]->dbh->rollback();
}

=item C<$db-E<gt>errstr()>

Holds a description of the last error that occured.

=cut
sub errstr
{
    return $DBI::errstr;
}

=item C<$db-E<gt>PrintError($bool_print_error)>

If this is set, the database driver will print the contents of $db->errstr when
any error occurs. This option is on by default.

=cut
sub PrintError
{
    my ($self, $pe) = @_;
    $self->dbh->{PrintError} = $pe if $pe;
    return $self->dbh->{PrintError};
}

=item C<$db-E<gt>RaiseError($bool_raise_error)>

If this is set, the database driver will print the contents of $db->errstr and _exit_ the running program 
when any error occurs. This option is off by default.

=cut
sub RaiseError
{
    my ($self, $re) = @_;
    $self->dbh->{RaiseError} = $re if $re;
    return $self->dbh->{RaiseError};
}

=item C<$db-E<gt>trace($trace_level)>

If this is set, the database driver will print verbose debugging information for any
database action. This option is off by default.

=cut
sub trace
{
    my ($self, $level, $sth) = @_;

    if (ref $sth) {
        $sth->trace($level);
    }
    else {
        DBI->trace($level);
    }

    return undef;
}

=item C<$db>-E<gt>connected>

Will return true if we have a open database connection, false if not.
Note however that we can't trust the output of this method.

=cut
sub connected
{
    return $_[0]->{_DB_CONNECTED_};
}

=item C<$db>-E<gt>set_connected>

Private: Set the current connection status.

=cut
sub set_connected
{
    my ($self, $connected) = @_;
    $self->{_DB_CONNECTED_} = $connected;
}

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

=cut
sub prepare
{
    my ($self, $query) = @_;
    my $modwheel       = $self->modwheel;
    my $dbh            = $self->dbh;

    # Show the query in debug mode.
    my ($package, $filename, $line, $sub) = caller;
    if ($modwheel->debug) {
        unless (defined $query) {
            $modwheel->throw('db-prepare-without-query');
            $modwheel->logerror("[$package|$sub|$line|$filename]: Missing query for Modwheel::DB::prepare()\n");
            return undef;
        }
        else {
            $modwheel->loginform("[$package|\$sub|$line|$filename]: $query\n");
        }
    }

    # prepare the query...
    my $sth = $dbh->prepare($query);

    # and catch errors if there is any.
    unless ($sth) {
        $modwheel->throw('db-query-error');
        $modwheel->logerror("Couldn't prepare query $query: ", $self->errstr);
        $sth->finish();
        return undef;
    }

    return $sth;
}

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

=cut
sub execute
{
    my ($self, $sth, @vars) = @_;
    return $sth->execute(@vars);
}

=item C<$db-E<gt>query($query)>

Shortcut function for both prepare() and execute().
Returns back the query handle if everything went ok.
NOTE: Remember to use $db->query_end($sth) when finished using this handle.

=cut
sub query
{
    my ($self, $query, @vars) = @_;
    my $modwheel              = $self->modwheel;
    my $dbh                   = $self->dbh;

    my $sth = $self->prepare($query);
    my $ret = $self->execute($sth, @vars);
    unless ($ret) {
        $modwheel->throw('db-query-error');
        $modwheel->logerror("Couldn't execute query: $query:", $self->errstr);
        return undef;
    }

    return $sth;
}

=item C<$db-E<gt>query_end($sth)>

End a query started by prepare() or query().

=cut
sub query_end
{
    my ($self, $sth) = @_;
    return undef unless $sth;
    return $sth->finish;
}    

=item C<$db-E<gt>fetchrow_array($sth)>

Returns a arrayref to the data returned by the current query.

=cut
sub fetchrow_array
{
    my ($self, $sth) = @_;
    return $sth->fetchrow_arrayref();
}

=item C<$db-E<gt>fetchrow_hash($sth)>

Returns a hash to the data returned by the current query.

=cut
sub fetchrow_hash
{
    my ($self, $sth) = @_;
    return $sth->fetchrow_hashref();
}

=item C<$db-E<gt>fetchonerow_array($query, @bind_varuables)>

Returns a arrayref to the data in the first row returned by query.
It's a shortcut for writing:

    my $query = "[...]";
    my $sth   = $db->prepare($query);
    $sth->execute($query, @bind_variables);
    my $arrayref = $db->fetchrow_array($sth);
    $db->query_end($sth);

=cut
sub fetchonerow_array
{
    my ($self, $query, @vars) = @_;
    my $sth = $self->query($query, @vars) or return undef;
    my $ret = $self->fetchrow_array($sth);
    $self->query_end($sth);
    return $ret;
}

=item C<$db-E<gt>fetchonerow_hash($query, @bind_variables)>

Same as fetchonerow_array but returns a hash reference instead.

=cut 
sub fetchonerow_hash
{
    my ($self, $query, @vars) = @_;                                                                                        
    my $sth = $self->query($query, @vars) or return undef;
    my $ret = $self->fetchrow_hash($sth);
    $self->query_end($sth);
    return $ret;
}

=item C<$db-E<gt>fetch_singlevar($query)>

Return the first element from the first row of a query.                                                                                  

=cut 
sub fetch_singlevar
{
    my ($self, $query, @vars) = @_;

    my $sth    = $self->query($query, @vars) or return undef;
    my $result = $self->fetchrow_array($sth);
    $self->query_end($sth);

    return $result->[0];
}

=item C<$db-E<gt>exec_query($query)>

If you have a query that just executes a command but does not fetch anything, 
this is the ideal function to use.
RETURNS: the number of rows affected by the query.

=cut
sub exec_query
{
    my ($self, $query, @vars) = @_;

    my $sth    = $self->query($query, @vars);
    my $retval = $sth->rows if ref $sth;
    $self->query_end($sth);

    return $retval || 0;
}

=item C<$db-E<gt>current_timestamp()>

Get the current timestamp from the database as a string.

=cut
sub current_timestamp
{
    my $self = shift;
    return $self->fetch_singlevar('SELECT CURRENT_TIMESTAMP');
}

=item C<$db-E<gt>fetch_next_id($table, $optional_primary_key_name)>

Return the next available id from a table.

=cut
sub fetch_next_id
{
    my ($self, $table, $optional_primary_key_name) = @_;

    my $primary_key = $optional_primary_key_name || 'id';

    return $self->fetch_singlevar("SELECT MAX($primary_key) + 1 FROM $table");
}

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

=cut
sub build_insert_q
{
    my ($self, $table, $fields) = @_;

    my $query = "INSERT INTO $table(". join(', ', sort keys %$fields). ')';
    my $map   = join(", ", map{'?'} keys %$fields);
    $query   .= "VALUES($map)\n";

    return $query;
}

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

=cut
sub build_update_q
{
    my ($self, $table, $fields, $where) = @_;
    unless (defined $where && scalar keys %$where > 0) {
        $self->modwheel->throw('db-build-query-missing-where');
        $self->modwheel->logerror('Build Database Update Query: Not having a where clause is probably not what you want...');
        return undef;
    }

    my $query = "UPDATE $table SET ";
    $query   .= join(", ", map{"$_=?"} sort keys %$fields);
    $query   .= $self->_build_where_clause($where);

    return $query;
}

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

=cut
sub build_select_q
{
    my ($self, $table, $select, $match, $options) = @_;
    return $self->_build_q('SELECT', $table, $select, $match, $options);
}

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

=cut
sub build_delete_q
{
    my ($self, $table, $match, $options) = @_;
    unless (defined $match && scalar keys %$match > 0) {
        $self->modwheel->throw('db-build-query-missing-where');
        $self->modwheel->logerror('Build Database Delete Query: Not having a where clause is probably not what you want...');
        return undef;
    }

    return $self->_build_q('DELETE', $table, undef, $match, $options);
}

=item private: _build_q

Private helper function for the build_*_q functions.

=cut
sub _build_q
{                                                                                                      
    my ($self, $command, $tables, $select, $match, $options) = @_;

    # expand tables if table is an hash or array reference.    
    my $table;
    if (ref $tables eq 'HASH') {
        while (my($t, $a) = each %$tables) {
            $table .= "$t $a,";
        }
        chop $table;
    }
    elsif (ref $tables eq 'ARRAY') {
        $table = join(", ", @$tables);
    }
    else {
        $table = $tables;
    }

    # expand elements if cells to select is an array reference..
    if (ref $select eq 'ARRAY') {
        $select = join(", ", @$select);
    }

    $table  ||= "object";
    $select ||= "*" if $command eq 'SELECT';

    my $query  = "$command";
       $query .= " $select" if defined $select;
       $query .= " FROM $table";

    if (defined %$match) {
        $query .= $self->_build_where_clause($match)
    }

    if ($options->{order}) {
        $query .= " ORDER BY $options->{order}";
    }
    if ($options->{limit}) {
        $query .= " LIMIT $options->{limit}";
    }
    if ($options->{offset}) {
        $query .= " OFFSET $options->{offset}";
    }
    if ($options->{group}) {
        $query .= " GROUP BY $options->{group}";
    }

    return $query;
}

=item private: _build_where_clause

Private helper function for the build_*_q functions.

=cut
sub _build_where_clause
{
    my ($self, $match) = @_;
    return undef unless defined %$match;

    my $query    = ' WHERE ';
    my $num_pats = scalar keys %$match;
    my $count    = 1;
    foreach my $attribute (sort keys %$match) {
        my $pat = $match->{$attribute};

        my $operator = '=';
        if ($pat =~ s/^\%op=(.+?)\%//) {
            $operator = $1;
        }

        $query .= '(';
        $pat   =~ tr/ //d;
        my @subpats      = split(',', $pat);
        my $subpat_count = 0;
        foreach my $subpat (@subpats) {
            $query .= $attribute. ' '. $operator. ' '. $subpat;
            if ($subpat_count < $#subpats) {
                $query .= " OR ";   
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

=item L<$db-E<gt>quote($string)>

Quote characters in a string that will interfere in our database operations.

=cut
sub quote
{
    my ($self, $string) = @_;
    $string = $self unless ref $self;

    if ($string =~ /^\d+$/) {
        return $string;
    }
    $string =~ s/'/''/g;

    return $string;
}

=item L<$db-E<gt>sqlescape($string)>

Quote characters in a string that will interfere in our database operations.

=cut
sub sqlescape
{
    my ($self, $data) = @_;

    $data = $self unless ref $self;
    $data =~ s/'/''/g;
    $data =~ s/\?/\\?/g;

    return $data;
}

=item L<$db-E<gt>trim($string)>

Remove leading and trailing whitespace from a string.

=cut
sub trim
{
    my ($self, $text) = @_;

    $text = $self unless ref $self;
    $text =~ s/^\s*//;
    $text =~ s/\s*$//;

    return $text;
}

=item L<$db-E<gt>maintainance()>

Perform database maintainance.

=cut
sub maintainance { 1 }

1;
__END__

=back

=head1 HISTORY

=over 8

=item 0.01

Initial version.

=back

=head1 SEE ALSO

The README included in the Modwheel distribution.

The Modwheel website: http://www.0x61736b.net/Modwheel/

=head1 AUTHORS

Ask Solem Hoel, F<< ask@0x61736b.net >>.

=head1 COPYRIGHT, LICENSE

Copyright (C) 2007 by Ask Solem Hoel C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

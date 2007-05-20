# $Id: Prompt.pm,v 1.4 2007/05/19 13:02:56 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/REPL/Prompt.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.4 $
# $Date: 2007/05/19 13:02:56 $

package Modwheel::REPL::Prompt;
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw( :std );
use version; our $VERSION = qv('0.3.3');
{
    use Term::ReadKey;
    use Term::Complete;
    use Term::ANSIColor;
    use List::MoreUtils qw( any );

    public echo => my %echo_for, {is => 'rw'};

    #------------------------------------------------------------------------
    # ->new( )
    #
    # Create a new Modwheel::REPL::Prompt object.
    #------------------------------------------------------------------------
    sub new {
        my ($class) = @_;
        my $self    = register($class);
        $self->set_echo(1);

        return $self;
    }

    #------------------------------------------------------------------------
    # ->prompt($question, $default_answer, @suggestions)
    #
    # The heart of the prompt library.
    #------------------------------------------------------------------------
    sub prompt {
        my ($self, $question, $default_answer, @suggestions) = @_;
        return if not defined $question;

        # Default answers are the first of the suggestions argument,
        # and should be put on the top of the list.
        if ($default_answer) {
            unshift @suggestions, $default_answer;
        }

        # Fine colours. (Ooooh! :)
        my $ANSI_bold  = color 'bold';
        my $ANSI_reset = color 'reset';

        # Iterate through the list of suggestions and
        # add lowercase and uppercase versions to the list of
        # auto-complete answers. We also find the array index of the default
        # answer so we can replace it with ANSI colors later.
        my @complete;
        my $counter = 0;
        my $index_of_default_answer;
        for my $suggestion (@suggestions) {
            push @complete, lc $suggestion;
            push @complete,    $suggestion;
            push @complete, uc $suggestion;
            if ($default_answer && $suggestion eq $default_answer) {
                $index_of_default_answer = $counter;
            }
            $counter++;
        }

        # Make default-answer Bold (if we found it's array index that is).
        if ($default_answer && defined $index_of_default_answer) {
            $suggestions[$index_of_default_answer]= join q{},
                ($ANSI_bold, $default_answer, $ANSI_reset);
        }

        # Prepare our prompt...
        my $suggest = join q{/}, @suggestions;
        my $prompt  = join q{},  $ANSI_bold, $question, $ANSI_reset;
           $prompt .= q{ }; # white-space at end of prompt.
        if ($suggest) {
            $prompt .= "[$suggest]: ";
        }

        # Prompt our user...
        my $answer;
        if ($self->echo) {
            $answer = Complete($prompt, \@complete);
        }
        else {
            print $prompt;
            ReadMode('noecho');
            $answer = <STDIN>;
            ReadMode('restore');
            chomp $answer;
            print "\n";
        }

        return $answer;
    }

    #------------------------------------------------------------------------
    # ->password($prompt)
    #
    # Ask for a password. (Turns echo off).
    #------------------------------------------------------------------------
    sub password {
        my ($self, $prompt) = @_;
        my $answer;

        $self->set_echo(0);
        VERIFY:
        while (1) {
            $answer = $self->prompt($prompt);
            if ($answer) {
                last VERIFY;
            }
            else {
                print "Please enter the password.\n";
            }
        }
        $self->set_echo(1);

        return $answer;
    }

    #------------------------------------------------------------------------
    # ->number($prompt)
    #
    # Asks for a number using $prompt until the user has entered a number.
    #------------------------------------------------------------------------
    sub number {
        my ($self, $prompt) = @_;
        my $answer;

        VERIFY:
        while (1) {
            $answer = $self->prompt($prompt);
            if ($answer =~ m/^[\dxb]+$/xms) {
                last VERIFY;
            }
            else {
                print "You must enter a number. Please try again.\n";
            }
        }

        return 1;
    }


    #------------------------------------------------------------------------
    # ->yes_no($prompt)
    #
    # Ask a yes or no question.
    # If the user enters nothing it defaults to Yes.
    #------------------------------------------------------------------------
    sub yes_no {
        my ($self, $prompt) = @_;
        return $self->_yes_no_no_yes($prompt, 1);
    }

    #------------------------------------------------------------------------
    # ->no_yes($prompt)
    #
    # Ask a yes or no question.
    # If the user enters nothing it defaults to No.
    #------------------------------------------------------------------------
    sub no_yes {
        my ($self, $prompt) = @_;
        return $self->_yes_no_no_yes($prompt, 0);
    }

    #------------------------------------------------------------------------
    # ->_yes_no_no_yes($prompt, $opt_order_yes_first)
    #
    # Internal method used to handle both yes_no and no_yes. 
    #------------------------------------------------------------------------
    sub _yes_no_no_yes {
        my ($self, $prompt, $order) = @_;
        my $answer;

        my @ordered = $order == 1 ? qw( Yes  No  )
                                  : qw( No   Yes );

        VERIFY:
        while (1) {
            $answer = $self->prompt($prompt, @ordered);
            return $order if not $answer;

            if ($answer =~ m/^Y/xmsi) {
                return 1;
            }
            elsif ($answer =~ m/^N/xmsi) {
                return 0;
            }
        }

        return;
    }

    #------------------------------------------------------------------------
    # ->select_from_list($prompt, @list)
    #
    # User is prompted with the question until the user selects a value
    # from the given list, 
    #------------------------------------------------------------------------
    sub select_from_list {
        my ($self, $prompt, @list) = @_;
        my $answer;

        VERIFY:
        while (1) {
            $answer = $self->prompt($prompt, undef, @list);
            if ($answer && any { m/$answer/xmsi } @list) {
                print "ANSWER: '$answer'\n";
                return $answer;
            }
            print 'Please enter one of the following: ';
            print join q{, }, @list;
            print "\n";
        }

       return;
    }

    #------------------------------------------------------------------------
    # ->suggest($prompt, @list_of_suggestions)
    #
    # Prompt for string but also suggest a list of values that are auto-
    # completable.
    #------------------------------------------------------------------------
    sub suggest {
        my ($self, $prompt, @suggestions) = @_;
        return $self->prompt($prompt, undef, @suggestions);
    }

    #------------------------------------------------------------------------
    # ->using_default($prompt, $default_answer, @optional_suggestions)
    #
    # Prompt for string, if user doesn't enter anything the default answer is
    # used.
    #------------------------------------------------------------------------
    sub using_default {
        my ($self, $prompt, $default, @opt_suggestions) = @_;
        my $answer = $self->prompt($prompt, $default, @opt_suggestions);
        return $answer  ? $answer
                        : $default;
    }
}

'now playing: Secede - Say I Said So [Bye Bye Gridlock Traffic] [meta: itunes rating: *****]';

__END__


=pod


=head1 NAME

Modwheel::REPL::Prompt - User interaction from the console.

=head1 VERSION

This document describes Modwheel version v0.3.3

=head1 SYNOPSIS

    use Modwheel::REPL::Prompt;

    my $prompt = Modwheel::REPL::Prompt->new( );
   
    # Keep asking until user provides a number. 
    my $number = $prompt->number('Please enter a number:');
   
    # Ask for yes or no, if the user hits enter, yes is the default. 
    my $confirm = $prompt->yes_no('Would you like to start?');

    # Ask for no or yes, if the user hits enter, no is the default. 
    my $confirm = $prompt->no_yes('Would you like to delete this file?');


=head1 DESCRIPTION

Modwheel::REPL::Prompt supports password input, auto-completion,
suggestions and more.

=head1 SUBROUTINES/METHODS

=head2 CONSTRUCTOR

=over 4

=item C<Modwheel::REPL::Prompt-E<gt>new( )>

Create a new Modwheel::REPL::Prompt object.

=back

=head2 ATTRIBUTES

=over 4

=item C<Modwheel::REPL::Promt-E<gt>echo>

=item C<Modwheel::REPL::Promt-E<gt>set_echo($bool_on)>

Should echo be on or off for user input?
the C<-E<gt>password> function turns this off temporarily.

=back

=head2 METHODS

=over 4

=item C<Modwheel::REPL::Prompt-E<gt>prompt($question, $default_answer, @suggestions)>

Ask user a question. If there are suggestions (default answer is also an suggestion)
they will be listed after the question.

=item C<Modwheel::REPL::Prompt-E<gt>password($question)>

Ask user for a password. Echo will be turned off.
This will loop until a password is entered.

=item C<Modwheel::REPL::Prompt-E<gt>number($question)>

Ask user for a number.
This will loop until user provides a valid number.

=item C<Modwheel::REPL::Prompt-E<gt>yes_no($question)>

Ask user for Yes or No.
If user doesn't enter anything Yes is the default.

=item C<Modwheel::REPL::Prompt-E<gt>no_yes($question)>

Ask user for No or Yes.
If user doesn't enter anything No is the default.

=item C<Modwheel::REPL::Prompt-E<gt>select_from_list($question, @list_of_valid_answers)>

Loops until user has answered one of the answers in the list provided.

=item C<Modwheel::REPL::Prompt-E<gt>suggest($question, @suggestion)>

Ask for a question, but also give some suggestions.

=item C<Modwheel::REPL::Prompt-E<gt>using_default($question, $default_answer, @opt_suggestions)>

Ask a question.
If user doesn enter anything, a default answer is used.

=back

=head2 PRIVATE METHODS

=over 4

=item C<Modwheel::REPL::Prompt-E<gt>_yes_no_no_yes($question, $opt_order_yes_first)>

Internal method used to implement both yes_no and no_yes.

=back

=head1 DIAGNOSTICS


=head1 CONFIGURATION AND ENVIRONMENT

This module requires no configuration file or environment variables.

=head1 DEPENDENCIES

=over 4

=item * version

=item * Term::ReadKey

=item * Term::ANSIColor

=item * Term::Complete

=item * List::MoreUtils

=back



=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-modwheel@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

=over 4

=item * L<Modwheel::Manual>

The Modwheel manual.

=item * L<http://www.0x61736b.net/Modwheel/>

The Modwheel website.

=back

=head1 VERSION

v0.3.3

=head1 AUTHOR

Ask Solem, C<< ask@0x61736b.net >>.


=head1 LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem C<< ask@0x61736b.net >>.

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

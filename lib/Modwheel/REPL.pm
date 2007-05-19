# $Id: REPL.pm,v 1.2 2007/05/18 23:42:37 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/REPL.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.2 $
# $Date: 2007/05/18 23:42:37 $
package Modwheel::REPL;
use strict;
use warnings;
use Class::InsideOut::Policy::Modwheel qw(:std);
use version; our $VERSION = qv('0.3.1');
{
    use English             qw( -no_match_vars );
    use Readonly;
    use Params::Util        qw(_CODELIKE _CLASS);
    use Term::ReadLine;
    use YAML::Syck;
    use Data::Dumper;

    public terminal => my %terminal_for, {is => 'rw'};
    public prompt   => my %prompt_for,   {is => 'rw'};
    public outfh    => my %outfh_for,    {is => 'rw'};
    public subs     => my %subs_for,     {is => 'rw'};
    public class    => my %class_for,    {is => 'rw'};
    public spacing  => my %spacing_for,  {is => 'rw'};

    Readonly my $DEFAULT_SPACING => 16;

    Readonly my %DESCRIBE_SUBS   => (
        'say'    => 'Print some text.',
        'quit'   => 'Quit this program.',
        'help'   => 'This help screen.',
        'yaml'   => 'Dump output of command or var in YAML format.',
        'dump'   => 'Dump output of command or var with Data::Dumper.',
    );

    Readonly my %INTERNAL_SUBS   => (
        'quit' => sub {
            return exit;
        },
        'say'  => sub {
            my $self = shift;
            print join q{ }, @_;
            print "\n";
            return;
        },
        'help' => sub {
            my ($self)  = @_;
            my $class   = $self->class;
            my $spacing = $self->spacing;

            while (my($sub, $description) = each %DESCRIBE_SUBS) {
                my $whitespace = q{ } x ($spacing - length $sub);
                print join $whitespace, ($sub, $description);
                print qq{\n};
            }
            if (ref $class && $class->can('child_help')) {
                $class->child_help;
            }
            return;
        },
        'yaml' => sub {
            my $self = shift;
            my ($sub, @args) = @_;
            print YAML::Syck::Dump( $self->do($sub, @args) );
        },
        'dump' => sub {
            my $self = shift;
            my ($sub, @args) = @_;
            print Data::Dumper::Dump([ $self->do($sub, @args) ]);
        },
    );

    sub new {
        my ($class, $options_ref) = @_;
        my $self = register($class);

        $terminal_for{ident $self}= $options_ref->{terminal}
            || Term::ReadLine->new('mod REPL');

        $prompt_for{ident $self}= $options_ref->{prompt}
            || 'mod.. >';

        $outfh_for{ident $self}= $options_ref->{outfh}
            || $terminal_for{ident $self}->OUT
            || \*STDOUT;

        $subs_for{ident $self}    = $options_ref->{subs};
        $class_for{ident $self}   = $options_ref->{class};
        $spacing_for{ident $self} = $options_ref->{spacing}
            || $DEFAULT_SPACING;

        return $self;
    }

    sub run {
        my ($self) = @_;

    REPL:
        while (1) {
            last REPL if !$self->run_once;
        }

        return;
    }

    sub run_once {
        my ($self) = @_;
        my $line         = $self->read;
        my ($sub, @args) = $self->parseline($line);
        my @ret          = $self->do($line, $sub, @args);
        $self->write(@ret);
        return 1;
    }

    sub do {
        my $self = shift;
        my $orig = shift;
        my ($sub, @args) = @_;
        my $subs   = $self->subs;
        my $class  = $self->class;
        return if not defined $sub;
        my @ret;

        if (_CLASS(ref $class) && $class->can($sub)) {
            @ret = $class->$sub(@args);
        }
        elsif (_CODELIKE($subs->{$sub})) {
            @ret = $subs->{$sub}->($self, @args);
        }
        elsif (_CODELIKE($INTERNAL_SUBS{$sub})) {
            @ret = $INTERNAL_SUBS{$sub}->($self, @args);
        }
        else {
            @ret = $self->execute($orig);
        }

        return @ret;
    }

    sub read {
        my ($self) = @_;
        my $term   = $self->terminal;
        return $term->readline( $self->prompt );
    }

    sub execute {
        my ($self, $command) = @_;
        my @ret = eval qq{$command}; ## no critic
        if ($EVAL_ERROR) {
            @ret = ("Error: $EVAL_ERROR");
        }
        return @ret;
    }

    sub write {
        my ($self, @ret) = @_;
        return if not scalar @ret;
        my $fh = $self->outfh;
        print {$fh} join q{ }, @ret;
        return;
    }

    sub parseline{
        my($self, $string) = @_;
        my @container = ();
        my $argc = 0;

        # ### These are our states.

        my $block    = 0;   # in eval block
        my $quote    = 0;   # in back quote
        my $power    = 0;   # in power quote
        my $weak     = 0;   # in weak quote
        my $in_var   = 0;   # in variable
        my $in_var_p = 0;   # in variable (protected)
        my $lcwvar   = 0;
        my $lcw      = 0;   # last character was whitespace
        my $endofprot= 0;   # end of variable-protection state.
        my $buffer   = undef;

        $string =~ y/\t/ /;
        $string =~ y/\n/ /;

        # return an empty container if the string is empty.
        return @container if not $string;

        # ###
        # Iterate through each character in the string,
        # switching states as we hit special characters.
    CHARACTER:
        foreach my $chr ((split m//xms, $string)) {

            # weak quote character
            if ($chr eq q{"}) {
                if (!$quote || !$block || !$power) {
                    $weak = $weak ? 0 : 1;
                    $lcw=0;
                    next CHARACTER;
                }
            }

            # ### Power quote character
            elsif ($chr eq q{'}) {
                if (!$quote || !$block || !$weak) {
                    $power = $power ? 0 : 1;
                    $lcw=0;
                    next CHARACTER;
                }
            }

            # ### Evaluation block start character
            elsif ($chr eq '{' || $chr eq '[') {
                if (!$block || !$weak || !$quote || !$power) {
                    $block = 1;
                    next CHARACTER;
                }
            }

            # ### Evaluation block end character
            elsif ($chr eq '}' || $chr eq ']') {
                if ($block) {
                    my $result = eval qq{$container[$argc]}; ## no critic
                    if($EVAL_ERROR) {
                        print {*STDERR} "Error in eval block: $EVAL_ERROR";
                    }
                    $container[$argc] = $result;
                    $block = $lcw = 0;
                    next CHARACTER;
                }
            }

            # ### Variable interpolation start character
            elsif ($chr eq q{$}) {
                if(!$power && !$quote) {
                    $in_var = $lcwvar = 1;
                    next CHARACTER;
                }
            }

            # ### Backquote character
            elsif ($chr eq q{\\}) {
                if (!$power || !$quote || !$block) {
                    $quote = 1;
                    next CHARACTER;
                }
                else {
                    $quote = 0;
                }
                $lcw = 0;
            }

            # ### Space character (argument separator)
            elsif ($chr eq q{ }) {
                if (!$block || !$weak || !$quote || !$power) {
                    if (!$lcw) {
                        $argc++;
                        $lcw = 1;
                    }
                    next CHARACTER;
                }
                else {
                    $lcw=0;
                }
            }
            else {
                $lcw=0;
            }

            $container[$argc] .= $chr;
        }

        return @container;
    }

}

1;

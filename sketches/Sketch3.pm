package Sketch3;

use strict; 
use warnings;
use Devel::Declare::Lexer qw/ let loop /;
# use Devel::Declare::Lexer qw/ let loop :debug /;
use Devel::Declare::Lexer::Factory qw( :all );
use Data::Dumper;

sub import
{
    my $caller = caller;
    Devel::Declare::Lexer::import_for($caller, "let");
    Devel::Declare::Lexer::import_for($caller, "loop");
}

sub discard_whitepace {
    my $stream_ref = shift;
    while ($stream_ref->[0]->isa('Devel::Declare::Lexer::Token::Whitespace')) {
        shift @$stream_ref;
    }
}

sub get_balanced {
    my $stream_ref = shift;
    discard_whitepace($stream_ref);
    $stream_ref->[0]->isa('Devel::Declare::Lexer::Token::LeftBracket') or return ();

    my $count = 0;
    my @balanced;
    BALANCE: {
        my $next = shift @$stream_ref;
        push @balanced, $next;
        if ($next->isa('Devel::Declare::Lexer::Token::LeftBracket')) {
            $count++;
        }
        elsif ($next->isa('Devel::Declare::Lexer::Token::RightBracket')) {
            $count--;
            return @balanced unless $count;
        }
        redo;
    }
}

BEGIN {
    Devel::Declare::Lexer::lexed(let => sub {
        my ($stream_ref) = @_;
        my @stream = @$stream_ref;

        my %brackets = ( '['=>'A', '{'=>'H' );

        my $kw = shift @stream;

        my ($count, $stop_munging);
        my @next = map {
            if ($stop_munging) {
                $_
            }
            elsif ($_->isa('Devel::Declare::Lexer::Token::RightBracket')) {
                --$count or $stop_munging++;
                Devel::Declare::Lexer::Token::RightBracket->new( value => ')' );
            }
            elsif ($_->isa('Devel::Declare::Lexer::Token::LeftBracket')) {
                $count++;
                if (my $bareword = $brackets{ $_->{value} }) {
                    Devel::Declare::Lexer::Token::Bareword->new( value => $bareword ),
                    Devel::Declare::Lexer::Token::LeftBracket->new( value => '(' ),
                }
                else {
                    $_;
                }

            }
            else {
                $_;
            }
        } @stream;

        @stream = (
            $kw,
            Devel::Declare::Lexer::Token::Whitespace->new( value => ' ' ),
            Devel::Declare::Lexer::Token::Bareword->new( value => 'letB' ),
            Devel::Declare::Lexer::Token::Whitespace->new( value => ' ' ),
            @next
        );

        \@stream;
    });

    Devel::Declare::Lexer::lexed(loop => sub {
        my ($stream_ref) = @_;
        my @stream = @$stream_ref;

        my %brackets = ( '['=>'A', '{'=>'H' );

        my $kw = shift @stream;

        my $count;

        my @bind = get_balanced(\@stream);
        @bind = map {
            if ($_->isa('Devel::Declare::Lexer::Token::RightBracket')) {
                Devel::Declare::Lexer::Token::RightBracket->new( value => ')' );
            }
            elsif ($_->isa('Devel::Declare::Lexer::Token::LeftBracket')) {
                if (my $bareword = $brackets{ $_->{value} }) {
                    _bareword( $bareword ),
                    Devel::Declare::Lexer::Token::LeftBracket->new( value => '(' );
                }
                else {
                    $_
                }
            }
            else {
                $_
            }
        } @bind;

        my @vars = get_balanced(\@stream); # ( $var1, $var2, $var3 ) to be looped over.

        my @next = (
            _bareword(1),
            Devel::Declare::Lexer::Token::EndOfStatement->new(),
            _operator('for'),
            @vars,
        );

        discard_whitepace(\@stream);

        my $opening_bracket = shift @stream;

        push @next,
            $opening_bracket,
            _bareword('letB'),
            _whitespace(' '),
            @bind,
            _operator('=>'),
            _variable('$', '_'), # for loop alias
            Devel::Declare::Lexer::Token::EndOfStatement->new();

        my @new_stream = (
            $kw,
            @next,
            @stream, # rest of loop body
            Devel::Declare::Lexer::Token::EndOfStatement->new(),
        );

        \@new_stream;
    });
}

1;

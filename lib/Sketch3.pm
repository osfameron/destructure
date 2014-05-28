package Sketch3;

use strict; 
use warnings;
use Devel::Declare::Lexer qw/ let /;
use Devel::Declare::Lexer::Factory qw( :all );
use Data::Dumper;

sub import
{
    my $caller = caller;
    Devel::Declare::Lexer::import_for($caller, "let");
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

        warn join '', map $_->{value}, @stream;
        \@stream;
    });
}

1;

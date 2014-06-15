package Destructure::Sugar;
use strict; use warnings;
use Text::Balanced qw/ extract_codeblock extract_variable extract_quotelike /;

sub munge_bind {
    my $text = shift;

    my $my = $text=~s/^ \s* my\b//x;

    my ($block) = extract_codeblock( $text, '(){}[]' );

    munge_bind_list( $block, $my );
    # returns ($munged, $rest);
}

my %map = (
    '(' => 'A(',
    '[' => 'A(',
    '{' => 'H(',
);
sub munge_bind_list {
    my ($block, $my) = @_;
    return unless $block;

    $block =~ s/ ^ (.) //x;
    my $opening = $map{$1} or die "Bad list opener: $1 ($block)";

    my @out = ($opening);

    # now either:
    #    combinations of:  my / Type / $scalar
    #    %slurp
    #    @slurp
    #    undef
    #    \undef
    #    'quotelike'
    #    bareword (including hash keys)
    #    123
    #    , =>
    #    {[
    #
    while ($block) {
        $block =~s/^ ( (?: \s | , | => )+ ) //x # skip whitespace and commas
            and push @out, $1;

        if ($block =~ /^ (?: 
                \{
                |   # either opening curly or square
                \[ 
            )/x) {
            (my $sublist, $block) = munge_bind_list($block, $my);
            push @out, $sublist;
            next;
        }
        my ($var, $rest, $prefix) = extract_variable($block, qr/
            (my)?  # optional my declaration
            \s*
            (\b\w+)? # Bareword, e.g. a type constraint
            \s*
            /x);
        if ($var) {
            my $lmy = $prefix =~ s/my\s+//;

            if ($prefix =~ /\S/) {
                # we have a type constraint.  We'll use that first;
                push @out, $prefix, ',';
            }
            push @out, 'my' if $my || $lmy;
            push @out, '\\' unless $var =~ /^ \$ /x;
            push @out, $var;

            $block = $rest;
            next;
        }

        if ($block =~ s/^( \# .* )//x) {
            push @out, $1;
            next;
        }

        if ($block =~ s/^ (?: 
            \) | \} | \]  # closing brace
            )
            //x
        ) {
            push @out, ')';
            last;
        }

        # otherwise, we'll push the quoted expression or number|undef
        $block =~ s{^ \\ }{}
            and push @out, '\\';
        (my $quote, $block) = extract_quotelike($block);
        if ($quote) {
            push @out, $quote;
        }
        else {
            (my $lhs, my $comment, $block) = split /(#)/, $block, 2;

            (my $atom, my $comma, my $line) = split /(,|=>)/, $lhs, 2;
            push @out, $atom;
            push @out, $comma if $comma;

            $block = join '', grep defined, $line, $comment, $block;
            next;
        }
    }

    return (
        (join ' ', @out),
        $block,
    );
}

package main;
use strict; use warnings;

my @strings = (
    'my [  $foo , Str $bar, 1, undef, [ $baz ] ] = 1',
    '{ foo => my Int $foo , bar => Str $bar, %rest }',
    '{ foo => [\undef, "this is a { test" ] }',
    "my { foo # wibble , \$baz \n => \$bar }",
    "my [ foo # wibble , \$baz \n => \$bar ]",
);

use feature 'say';
for (@strings) {
    say "WAS: $_";
    my ($munged) = Destructure::Sugar::munge_bind($_);
    say "NOW: $munged";
    say '';
}

1;

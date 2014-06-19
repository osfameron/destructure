package Destructure::Sugar;
use strict; use warnings;
use Text::Balanced qw/ extract_codeblock extract_variable extract_quotelike /;
use Carp 'croak';

#######
# extract this part out?
use Keyword::Simple;

sub import {
    Keyword::Simple::define 'let', sub {
        my ($ref) = @_;
        my ($let, $rest) = munge_let($$ref);
        $$ref = $let . $rest;
    };
}

sub unimport {
    Keyword::Simple::undefine 'let';
}

#######

sub munge_let {
    my $text = shift;

    my ($bind, $rest) = munge_bind($text);
    croak "Couldn't extract bind block" unless $bind;

    $rest =~ s/ \s* = \s* //x or croak 'Expected =';

    (my $block, $rest) = extract_codeblock( $rest, '(){}[]' );
    croak "Couldn't extract a block" unless $block;

    my $munged = join ' ',
        ';',
        $bind,
        '->match(', $block, ')',
        '->bind';
    warn $munged;
    return ($munged, $rest);
};

sub munge_bind {
    my $text = shift;

    my $my = $text=~s/^ \s* my\b//x;

    my ($block, $rest) = extract_codeblock( $text, '(){}[]' );

    my ($munged, $munged_rest) = munge_bind_list( $block, $my );
    return ($munged, $munged_rest . $rest);
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
    my $opening = $map{$1} or croak "Bad list opener: $1 ($block)";

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

        my ($subblock, $subblock_rest) = extract_codeblock($block, '{}[]' );
        if ($subblock) {
            warn "FROM {{{ $block }}}";
            warn "GOT {{{ $subblock }}}";
            my ($sublist, $sublist_rest) = munge_bind_list($subblock, $my);
            warn "NOW {{{ $sublist }}}";
            push @out, $sublist;
            $block = $sublist_rest . $subblock_rest;
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

1;

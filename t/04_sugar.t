use strict; use warnings;
use Test::More;
use lib 'lib';
use Destructure;
use Destructure::Sugar;
use Types::Standard ':all';
use Scalar::Util 'blessed';

subtest 'bindings' => sub {
    my @strings = (
        [
            'my [  $foo , Str $bar, 1, undef, [ $baz ] ] = 1',
            'Nested array with my',
        ],
        [
            '{ foo => my Int $foo , bar => Str $string, %rest }',
            'Hash with slurp',
        ],
        [
            '{ foo => [\undef, "this is a { test" ] }',
            'Hash with constants',
        ],
        [
            "my { foo # wibble , \$baz \n => \$bar }",
            'Hash with comment and newline',
        ],
        [
            "my [ foo # wibble , \$baz \n => \$bar ]",
            'Array with comment and newline',
        ],
        [
            'my { x => $x1, y => $y1 }',
            'Hash with 2 elements',
        ],
        [
            'my [{ x => $x1, y => $y1 }, { x => $x2, y => $y2 }]',
            'AoH',
        ],
    );

    my ($string, %rest); # variables that aren't my'd
    for (@strings) {
        my ($string, $desc) = @$_;
        my ($munged) = Destructure::Sugar::munge_bind($string);
        ok $munged, $desc or do { diag $string; next };
        my $match = eval($munged) or do {
            fail $@;
            diag $munged;
        };
        ok $match->isa('Bind'), 'Is Bind' or do { diag $munged; diag $match };
    }
};

subtest 'let' => sub {
    my $let = Destructure::Sugar::munge_let('my [$x, $y] = [1, 2];');
    eval "$let; is \$x, 1; is \$y, 2;";
};

done_testing;

1;

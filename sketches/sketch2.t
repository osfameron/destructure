use strict; use warnings;

use Test::More;
use Sketch2;
use Test::Exception;

subtest 'simple array', sub {
    letB A(my $foo, my $bar) => [1,2];

    is $foo, 1;
    is $bar, 2;
};

subtest 'undef', sub {
    letB A(my $foo, _, my $bar) => [1,2,3];

    is $foo, 1;
    is $bar, 3;
};

subtest 'literal ', sub {
    letB A(1, 2, my $foo) => [1,2,3];

    is $foo, 3;
};

subtest 'failed literal ', sub {

    throws_ok {
        letB A(1, 2, my $foo) => [3,4,5];
    } qr/Couldn't bind 1 to 3/, 'Failed bind throws error';
};

subtest 'complex array', sub {
    letB A(my $foo, A(my $bar, my $baz)) => [1, [2, 3] ];

    is $foo, 1;
    is $bar, 2;
    is $baz, 3;
};

subtest 'scalar', sub {
    letB S(my $foo) => 10;
    is $foo, 10;
};

subtest 'hash', sub {
    letB H(foo => my $foo, bar => my $bar) => { foo => 1, bar => 2 };

    is $foo, 1;
    is $bar, 2;
};

subtest 'complex', sub {
    letB H(foo => A(my $foo, my $bar), baz => A(_, my $baz)) => { foo => [1,2], baz => [3,4] };

    is $foo, 1;
    is $bar, 2;
    is $baz, 4;
};

subtest 'forB loop', sub {
    # ugly
    my $bind = A(my $foo, my $bar);
    forB $bind => [1,2], [3,6], sub {
        is $foo*2, $bar, "Double $foo == $bar";
    };
};

done_testing;

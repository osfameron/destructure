use strict; use warnings;

use Test::More;
use Sketch2;

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
    letB A(1, 2, my $foo) => [3,4,5];

    is $foo, 3;

    isa_ok S(2), 'Bind::Constant';
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

subtest 'forB loop', sub {
    # ugly
    my $bind = A(my $foo, my $bar);
    forB $bind => [1,2], [3,6], sub {
        is $foo*2, $bar, "Double $foo == $bar";
    };
};

done_testing;

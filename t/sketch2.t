use strict; use warnings;

use Test::More;
use Sketch2;

subtest 'simple array', sub {
    letB A(my $foo, my $bar) => [1,2];

    is $foo, 1;
    is $bar, 2;
};

subtest 'undef ', sub {
    letB A(my $foo, _, my $bar) => [1,2,3];

    is $foo, 1;
    is $bar, 3;
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


done_testing;

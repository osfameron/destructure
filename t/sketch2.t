use strict; use warnings;

use Test::More;
use Sketch2;

subtest 'simple array', sub {
    letB A(my $foo, my $bar) => [1,2];

    is $foo, 1;
    is $bar, 2;
};


done_testing;

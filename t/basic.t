use strict; use warnings;

use Test::More;
use Destructure;

subtest 'simple array', sub {
    A(my $foo, my $bar) = [1,2];

    is $foo, 1;
    is $bar, 2;
};

subtest 'simple array distributed', sub {
    A(my ($foo, $bar)) = [1,2];

    is $foo, 1;
    is $bar, 2;
};

subtest 'complex array', sub {
    A(my $foo, A(my $bar, my $baz)) = [1,[2,3]];

    is $foo, 1;
    is $bar, 2;
    is $baz, 3;
};

subtest 'hashref', sub {
    H(foo => my $qux) = { foo => 'Hello' };

    is $qux, 'Hello';
};

subtest 'complex hashref', sub {

    H(
        foo => A(my $first_foo,,,),
        bar => my $bar,
        baz => H(
            baz => my $bazbaz,
        )
    ) = {
        foo => [1,2,3],
        bar => 'BAR',
        baz => {
            baz => 'BAZ',
        }
    };
    is $first_foo, 1;
    is $bar, 'BAR';
    is $bazbaz, 'BAZ';
};

subtest 'undef ok' => sub {
    A(my $foo, _, my $bar) = [1,2,3];
    is $foo, 1;
    is $bar, 3;
};

done_testing;

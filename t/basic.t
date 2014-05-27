use strict; use warnings;

use Test::More;
use Destructure;

subtest 'simple array', sub {
    _(my $foo, my $bar) = [1,2];

    is $foo, 1;
    is $bar, 2;
};

subtest 'simple array distributed', sub {
    _(my ($foo, $bar)) = [1,2];

    is $foo, 1;
    is $bar, 2;
};

subtest 'complex array', sub {
    _(my $foo, _(my $bar, my $baz)) = [1,[2,3]];

    is $foo, 1;
    is $bar, 2;
    is $baz, 3;
};

subtest 'hashref', sub {
    _h(foo => my $qux) = { foo => 'Hello' };

    is $qux, 'Hello';
};

subtest 'complex hashref', sub {

    _h(
        foo => _(my $first_foo),
        bar => my $bar,
        baz => _h(
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

done_testing;

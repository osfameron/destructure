use Test::More;
use Test::Exception;
use lib 'lib';
use Destructure;
use strict; use warnings;
use feature 'state';

subtest 'repeat with my' => sub {
    my $scalar = S(my $x);
    $scalar->match(1)->bind;
    is $x, 1;
    $scalar->match(2)->bind;
    is $x, 2;

    my $array = A(my $y, my $z);
    $array->match([1,2])->bind;
    is $y, 1;
    is $z, 2;
    $array->match([3,4])->bind;
    is $y, 3;
    is $z, 4;
};

subtest 'repeat with state' => sub {
    my $scalar = sub {
        my $desc = shift;
        state $bind = S(my $x);
        $bind->match(1)->bind;
        is $x, 1, $desc;
    };
    $scalar->('first attempt');
    $scalar->('second attempt');
};


use strict; use warnings;
use Test::More;
use lib 'lib';
use Destructure;
use Destructure::Sugar;
use Types::Standard ':all';

subtest 'let' => sub {
    let my [$x, $y] = [1, 2];
    is $x, 1;
    is $y, 2;
};

subtest 'destructuring bind' => sub {
    my @list = (
        { a => 10, b => 10 },
        { a => 20, b => 15 });

    let my [{ a => $a1, b => $b1 }, { a => $a2, b => $b2 }] = [@list];
    is $a1, 10;
    is $b1, 10;
    is $a2, 20;
    is $b2, 15;
};

subtest 'loop' => sub {
  for ([1, 'a'], [2, 'aa'], [3, 'aaa']) {
    let my [$a, $b] = [@$_];
    is length $b, $a, "Length $b";
  }
};

done_testing;

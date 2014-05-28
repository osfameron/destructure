use strict; use warnings;
use Test::More;
use Sketch2; # functionality
use Sketch3; # sugar

subtest 'Simple' => sub {
    let [my $foo, my $bar, my $baz] => [1, 2, 3];
    is $foo, 1;
    is $bar, 2;
    is $baz, 3;
};

subtest 'Hash' => sub {
    let { foo => my $foo } => { foo => 'foo' };
    is $foo, 'foo';
};

sub test {
    my $num = shift;
    let [my $foo, my $bar, my $baz] => [$num + 1, $num + 2, $num + 3 ];

    is $foo, $num + 1, "foo = $foo";
    is $bar, $num + 2, "bar = $bar";
    is $baz, $num + 3, "baz = $baz";
}

subtest 'Lexical sugar works called multiple times' => sub {
    test(1);
    test(10);
};

subtest 'Lexical sugar loop' => sub {
    loop [my $fst, my $snd] ([1,2], [3,4]) { 
        is $fst+1, $snd, "Loop $fst+1 = $snd"; 
    }
};

done_testing;

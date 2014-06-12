use Test::More;
use lib 'lib';
use Destructure;
use strict; use warnings;
use Data::Dumper;

subtest 'unsugared' => sub {
    # lets just get these out of the way first, to see the entire, cumbersome
    # API if you're writing with objects and no helper functions

    subtest 'scalar' => sub {
        like (Bind::Scalar->new(my $a)->match(), qr/No values/);
        like (Bind::Scalar->new(my $b)->match(1,2), qr/Too many values/);
        my $match = Bind::Scalar->new(my $c)->match(100);
        isa_ok $match, 'Bind::Match';
        is $c, undef, 'sanity check';
        $match->bind;
        is $c, 100;
    };

    subtest 'array' => sub {
        my $decl = Bind::Array->new(
            Bind::Scalar->new(my $a),
            Bind::Scalar->new(my $b),
        );
        like $decl->match(), qr/No values/;
        like $decl->match([1,2,3]), qr/Too many/;
        my $match = $decl->match([1,2]);
        isa_ok $match, 'Bind::Match';
        is $a, undef, 'sanity check';
        is $b, undef, 'sanity check';
        $match->bind;
        is $a, 1;
        is $b, 2;
    };
};

subtest 'scalar syntax' => sub {
    like S(my $a)->match(), qr/No values/;
    like S(my $b)->match(1,2), qr/Too many values/;
    my $match = S(my $c)->match(100);
    isa_ok $match, 'Bind::Match';
    is $c, undef, 'sanity check';
    $match->bind;
    is $c, 100;
};

subtest 'array syntax' => sub {
    my $decl = A( my $a, my $b );
    like $decl->match(), qr/No values/;
    like $decl->match([1,2,3]), qr/Too many/;
    my $match = $decl->match([1,2]);
    isa_ok $match, 'Bind::Match';
    is $a, undef, 'sanity check';
    is $b, undef, 'sanity check';
    $match->bind;
    is $a, 1;
    is $b, 2;
};

subtest 'AoA' => sub {
    my $decl = A( A(my $a), my $b );

    like $decl->match(), qr/No values/;
    like $decl->match([1,2]), qr/Not an array ref/;
    my $match = $decl->match([[1],2]);
    isa_ok $match, 'Bind::Match';
    is $a, undef, 'sanity check';
    is $b, undef, 'sanity check';
    $match->bind;
    is $a, 1;
    is $b, 2;
};

subtest 'Slurp' => sub {
    my $decl = A( my $head, \my @rest );

    $decl->match([ 1 ])->bind;
    is $head, 1;
    is_deeply \@rest, [];

    $decl->match([ 1, 2, 3 ])->bind;
    is $head, 1;
    is_deeply \@rest, [2, 3];
};

subtest 'Hash' => sub {
    my $decl = H( foo => my $foo, bar => my $bar );

    like $decl->match({ foo => 1 }), qr/No such key/;
    like $decl->match({ foo => 1, baz => 3 }), qr/No such key/;
    like $decl->match({ foo => 1, bar => 2, baz => 3 }), qr/Too many/;

    my $match = $decl->match({ foo => 1, bar => 2 })->bind;
    is $foo, 1;
    is $bar, 2;
};

subtest 'Hash Slurp' => sub {
    my $decl = H( foo => my $foo, \my %rest );

    $decl->match({ foo => 1 })->bind;
    is $foo, 1;
    is_deeply \%rest, { };

    $decl->match({ foo => 2, bar => 2 })->bind;
    is $foo, 2;
    is_deeply \%rest, { bar => 2 };

    $decl->match({ foo => 3, bar => 2, baz => 1 })->bind;
    is $foo, 3;
    is_deeply \%rest, { bar => 2, baz => 1 };

};

subtest 'Whole hash slurp' => sub {
    H(\my %hash)->match({ foo => 1 })->bind;
    is_deeply \%hash, { foo => 1 };
};

done_testing;

use Test::More;
use Test::Exception;
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

done_testing;

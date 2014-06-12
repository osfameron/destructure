use strict; use warnings;

package Bind;

sub new {
    my $class = shift;
    bless \@_, $class;
}

sub match {
    my ($match, @remainder) = shift->_match(@_);

    if (ref $match) {
        return sprintf 'Too many values (%d remaining)', (scalar @remainder)
            if @remainder;
        return bless $match, 'Bind::Match';
    }
    else {
        return $match; # string error
    }
}

package Bind::Scalar;
our @ISA = ('Bind');

sub new {
    my $class = shift;
    bless \$_[0], $class;
}

sub _match {
    my $self = shift;
    return 'No values' unless @_;
    my ($value, @rest) = @_;
    return sub { $$self = $value }, @rest;
}

package Bind::Array;
use Scalar::Util 'reftype';
our @ISA = ('Bind');

sub new {
    my $class = shift;
    bless \@_, $class;
}

sub _match {
    my $self = shift;
    return 'No values' unless @_;
    my ($value, @rest) = @_;
    return 'Not an array ref!' unless reftype $value eq 'ARRAY';
    my @values = @$value;
       
    my @matches;
    for my $exp (@$self) {
        (my $match, @values) = $exp->_match(@values);
        return $match unless ref $match;
        push @matches, $match;
    }
    return sprintf 'Too many values (%d remaining)', (scalar @values)
        if @values;
    return sub { map $_->(), @matches }, @rest;
}

package Bind::Slurp::Array;
use Scalar::Util 'reftype';
our @ISA = ('Bind');

sub new {
    my ($class, $array_ref) = @_;
    die "Can't bind a Bind::Slurp::Array to a non array ref" unless reftype $array_ref eq 'ARRAY';
    bless $array_ref, $class;
}

sub _match {
    my ($self, @values) = @_;
    return sub { @$self = @values };
}

package Bind::Match;

sub bind {
    my $self = shift;
    $self->();
}

package main;
use Test::More;
use Data::Dumper;


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

subtest 'AoA' => sub {
    my $decl = Bind::Array->new(
        Bind::Array->new(
            Bind::Scalar->new(my $a),
        ),
        Bind::Scalar->new(my $b),
    );
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
    my $decl = Bind::Array->new(
        Bind::Scalar->new(my $head),
        Bind::Slurp::Array->new(\my @rest)
    );

    $decl->match([ 1 ])->bind;
    is $head, 1;
    is_deeply \@rest, [];

    $decl->match([ 1, 2, 3 ])->bind;
    is $head, 1;
    is_deeply \@rest, [2, 3];
};

done_testing;

use strict; use warnings;

package Destructure;
use Scalar::Util qw(blessed readonly reftype);
use List::Util 'pairmap';
use Sub::Exporter -setup => {
    exports => [
        qw( A S H )
    ],
    groups => {
        default => [ qw( A S H ) ],
    }
};

sub H {
    my @slurp = @_ % 2 ? Bind::Slurp::Hash->new( $_[-1] ) : ();
    pop @_ if @slurp;
    my @match = pairmap { Bind::Hash::Key->new($a, S($b)) } @_;
    Bind::Hash->new( @match, @slurp );
}

sub A {
    Bind::Array->new(map { S($_) } @_);
}

sub S {
    if (blessed $_[0] and $_[0]->isa('Bind')) {
        return $_[0];
    }
    if (ref $_[0]) {
        if (reftype $_[0] eq 'ARRAY') {
            return Bind::Slurp::Array->new($_[0]);
        }
    }
    # constant
    return Bind::Scalar->new(@_);
}

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
    return 'Not an array ref!' unless ref $value and reftype $value eq 'ARRAY';
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

package Bind::Hash;
use Scalar::Util 'reftype';
use List::Util 'pairmap';
our @ISA = ('Bind');

sub new {
    my $class = shift;
    bless \@_, $class;
}

sub _match {
    my $self = shift;
    return 'No values' unless @_;
    my ($value, @rest) = @_;
    return 'Not a hash ref!' unless reftype $value eq 'HASH';
    my %values = %$value;

    my @matches;
    for my $exp (@$self) {
        (my $match, %values) = $exp->_match(%values);
        return $match unless ref $match;
        push @matches, $match;
    }
    return sprintf 'Too many values (%d remaining)', (scalar keys %values)
        if keys %values;

    return sub { map $_->(), @matches }, @rest;
}

package Bind::Hash::Key;
our @ISA = ('Bind');

sub new {
    my $class = shift;
    bless \@_, $class; # [$key, $value]
}

sub _match {
    my ($self, %hash) = @_;
    my $key = $self->[0];
    return "No such key $key" unless exists $hash{$key};
    my $value = delete $hash{$key};
    my ($match) = $self->[1]->_match($value);
    return $match unless ref $match;
    return $match, %hash;
}

package Bind::Slurp::Hash;
use Scalar::Util 'reftype';
our @ISA = ('Bind');

sub new {
    my ($class, $hash_ref) = @_;
    die "Can't bind a Bind::Slurp::Hash to a non hash ref" unless reftype $hash_ref eq 'HASH';
    bless $hash_ref, $class;
}

sub _match {
    my ($self, %values) = @_;
    return sub { %$self = %values };
}

package Bind::Match;

sub bind {
    my $self = shift;
    $self->();
}

1;

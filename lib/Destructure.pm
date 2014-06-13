use strict; use warnings;

package Destructure;
use Scalar::Util qw(blessed readonly reftype);
use List::Util 'pairmap';
use Safe::Isa;

use Sub::Exporter -setup => {
    exports => [
        qw( C A S H )
    ],
    groups => {
        default => [ qw( C A S H ) ],
    }
};

sub H {
    # we get either:
    #   key => $bind (possibly including type)
    #   $bind_slurpy
    my @matchers;
    while (@_) {
        my $key = ref $_[0] ? undef : shift;
        my $matcher = _parse_scalar(\@_);
        if ($key) {
            push @matchers, Bind::Hash::Key->new($key, $matcher);
        }
        else {
            push @matchers, $matcher;
        }
    }
    Bind::Hash->new( @matchers );
}

sub C {
    Bind::Constant->new(@_);
}

sub A {
    my @matchers;
    while (@_) {
        my $matcher = _parse_scalar(\@_);
        push @matchers, $matcher;
    }
    Bind::Array->new(@matchers);
}

sub S {
    _parse_scalar(\@_);
}

sub _parse_scalar {
    my $ary = shift;
    my $type = $ary->[0]->$_isa('Type::Tiny') ? shift @$ary : undef;

    scalar @$ary or die "Nothing to parse!";

    my $S = do {
        if ($ary->[0]->$_isa('Bind')) { $ary->[0] }
        elsif (readonly $ary->[0]) { C($ary->[0]) }
        elsif (ref $ary->[0]) {
            if (reftype $ary->[0] eq 'ARRAY') {
                Bind::Slurp::Array->new($ary->[0]);
            }
            elsif (reftype $ary->[0] eq 'HASH') {
                Bind::Slurp::Hash->new($ary->[0]);
            }
            elsif (reftype $ary->[0] eq 'SCALAR') {
                Bind::Constant->new(${$ary->[0]});
            }
            else {
                die "Unhandled reftype!" . reftype $ary->[0];
            }
        }
        # constant
        else {
            Bind::Scalar->new($ary->[0]);
        }
    };
    shift @$ary;
    if ($type) {
        return Bind::Type->new($type, $S);
    }
    return $S;
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

package Bind::Type;
our @ISA = ('Bind');

sub _match {
    my $self = shift;
    return 'No values' unless @_;

    my $error; $error = $self->[0]->validate(@_) and return $error;
    return $self->[1]->_match(@_);
}

package Bind::Constant;
our @ISA = ('Bind');
use Scalar::Util qw(looks_like_number);

sub new {
    my $class = shift;
    bless \$_[0], $class;
}

sub _match {
    my $self = shift;
    return 'No values' unless @_;
    my ($value, @rest) = @_;
    my $exp = $$self;

    if (! defined($exp)) {
        return "Expected undefined but got $value" if defined $value;
    }
    elsif (looks_like_number($value)) {
        return "Expected $exp but got $value" unless $value == $exp;
    }
    else {
        return "Expected $exp but got $value" unless $value eq $exp;
    }
    return sub () {}, @rest; # noop
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
    return 'Not a hash ref!' unless ref $value and reftype $value eq 'HASH';
    my %values = %$value;

    my @matches;
    for my $exp (@$self) {
        my ($match, @values) = $exp->_match(%values);
        return 'Bad hash returned' if @values % 2;
        return $match unless ref $match;
        %values = @values;
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

use strict; use warnings;
package Sketch2;
use Scalar::Util qw(readonly reftype blessed looks_like_number);

sub import {
    # Exporter didn't like _, TODO clean this up
    my $callpkg = caller();
    no strict 'refs';
    *{"${callpkg}::_"} = \&_;
    *{"${callpkg}::A"} = \&A;
    *{"${callpkg}::S"} = \&S;
    *{"${callpkg}::letB"} = \&letB;
    *{"${callpkg}::forB"} = \&forB;
}

sub _ { sub {} }

sub _bindScalar {
    if (readonly $_[0]) {
        Bind::Constant->new(\$_[0]);
    }
    elsif (blessed $_[0] and $_[0]->isa('Bind')) {
        $_[0]
    }
    elsif (ref $_[0] and reftype $_[0] eq 'CODE') {
        Bind::Code->new($_[0]);
    }
    else {
        Bind::Scalar->new(\$_[0]);
    }
}

sub S {
    _bindScalar( $_[0] );
}

sub A {
    my @refs = map _bindScalar( $_[$_] ), 0..$#_;

    Bind::Array->new(\@refs);
}

sub letB {
    my ($bind, $value) = @_;
    $bind->assign($value);
}

sub forB {
    my $sub = pop;
    my ($bind, @values) = @_;

    for my $value (@values) {
        $bind->assign($value);
        $sub->();
    }
}

package Bind;
sub new {
    my ($class, $data) = @_;
    bless $data, $class;
}

package Bind::Scalar;
our @ISA = 'Bind';

sub assign {
    my ($self, $value) = @_;
    $$self = $value;
}

package Bind::Constant;
our @ISA = 'Bind';
use Scalar::Util qw(looks_like_number);

sub assign {
    my ($self, $value) = @_;
    if (looks_like_number($$self)) {
        die "Couldn't bind $$self to $value" unless $$self == $value;
    }
    else {
        die "Couldn't bind $$self to $value" unless $$self eq $value;
    }
}

package Bind::Code;
our @ISA = 'Bind';

sub assign {
    my ($self, $value) = @_;
    $self->($value);
}

package Bind::Array;
our @ISA = 'Bind';
sub assign {
    my ($self, $value) = @_;
    for my $i (0..$#$self) {
        $self->[$i]->assign( $value->[$i] )
    }
}

1;

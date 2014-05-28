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
}

sub _ { sub {} }

sub _bindScalar {
    my $ref = shift;
    if (readonly $$ref) {
        Bind::Constant->new($ref);
    }
    elsif (blessed $$ref and $$ref->isa('Bind')) {
        $$ref
    }
    elsif (ref $$ref and reftype $$ref eq 'CODE') {
        Bind::Code->new($$ref);
    }
    else {
        Bind::Scalar->new($ref);
    }
}

sub S {
    _bindScalar( \$_[0] );
}

sub A {
    my @refs = map _bindScalar( \$_[$_] ), 0..$#_;

    Bind::Array->new(\@refs);
}

sub letB {
    my ($bind, $value) = @_;
    $bind->assign($value);
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

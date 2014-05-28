use strict; use warnings;
package Sketch1;

sub import {
    my $callpkg = caller();
    no strict 'refs';
    *{"${callpkg}::_"} = \&_;
    *{"${callpkg}::A"} = \&A;
    *{"${callpkg}::H"} = \&H;
}

sub _ { undef }

sub A : lvalue {
    my @refs = map \$_[$_], 0..$#_;

    tie my $obj, 'Assign::Array', @refs;
    $obj;
}

sub H : lvalue {
    my %refs = map {
        ($_[$_*2] => \$_[($_*2)+1]), 
        } 0..($#_ / 2);

    tie my $obj, 'Assign::Hash', %refs;
    $obj;
}

package Assign::Array;
use base 'Tie::Scalar';
use strict; use warnings;

sub TIESCALAR {
    my ($class, @refs) = @_;
    bless \@refs, $class;
}

sub STORE {
    my ($self, $value) = @_;
    my @refs = @$self;
    for my $i (0..$#refs) {
        ${$refs[$i]} = $value->[$i];
    }
}

package Assign::Hash;
use base 'Tie::Scalar';
use strict; use warnings;

sub TIESCALAR {
    my ($class, %refs) = @_;
    bless \%refs, $class;
}

sub STORE {
    my ($self, $value) = @_;
    for my $k (keys %$self) {
        ${$self->{$k}} = $value->{$k};
    }
}

1;

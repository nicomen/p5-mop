package mop::syntax;

use strict;
use warnings;

use mop::syntax::dispatchable;
use mop::internal::attribute::set;
use mop::internal::method::set;

use PadWalker     ();
use Devel::Caller ();
use Sub::Name     ();

sub has (\$) {
    my $var = shift;

	my %names = reverse %{ PadWalker::peek_sub( Devel::Caller::caller_cv( 1 ) ) };
	my $name = $names{ $var };

    my $pad = PadWalker::peek_my(2);
    ${ $pad->{'$class'} }->add_attribute(
        mop::internal::attribute::create(
            name          => $name,
            initial_value => $var
        )
    );
}

sub method {
    my ($name, $body) = @_;
    my $pad = PadWalker::peek_my(2);
    ${ $pad->{'$class'} }->add_method(
        mop::internal::method::create(
            name => $name,
            body => Sub::Name::subname( $name, $body )
        )
    );
}

sub extends {
    my ($superclass) = @_;
    my $pad = PadWalker::peek_my(2);
    ${ $pad->{'$class'} }->add_superclass( $superclass );
}

sub class (&) {
    my $body = shift;
    my $class = $::Class->new;
    {
        local $::CLASS = $class;
        $body->();
    }
    $class->FINALIZE;
    $class;
}

1;

__END__

=pod

=head1 NAME

mop::syntax

=head1 DESCRIPTION

The primary responsibility of these 3 functions is to provide a
sugar layer for the creation of classes. Exactly how this would
work in a real implementation is unknown, but this does the job
(in a kind of scary PadWalker-ish way) for now.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
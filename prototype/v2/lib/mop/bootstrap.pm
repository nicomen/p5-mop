package mop::bootstrap;

use strict;
use warnings;

use mop::internal::class;
use mop::internal::instance;
use mop::internal::attribute;
use mop::internal::attribute::set;
use mop::internal::method;
use mop::internal::method::set;

sub init {

    $::Class = mop::internal::class::create(
        attributes => mop::internal::method::set::create(
            mop::internal::attribute::create( name => '$name',         initial_value => \(my $name) ),
            mop::internal::attribute::create( name => '$version',      initial_value => \(my $version) ),
            mop::internal::attribute::create( name => '$authority',    initial_value => \(my $authority) ),
            mop::internal::attribute::create( name => '$superclasses', initial_value => \([]) ),
            mop::internal::attribute::create( name => '$attributes',   initial_value => \(mop::internal::attribute::set::create()) ),
            mop::internal::attribute::create( name => '$methods',      initial_value => \(mop::internal::method::set::create()) ),
        ),
        methods    => mop::internal::method::set::create(
            # class creation needs ...
            mop::internal::method::create( name => 'BUILD', body => sub {
                foreach my $method ( mop::internal::method::set::members( $::SELF->get_methods ) ) {
                    mop::internal::method::associate_with_class( $method, $::SELF );
                }
                foreach my $attr ( mop::internal::attribute::set::members( $::SELF->get_attributes ) ) {
                    mop::internal::attribute::associate_with_class( $attr, $::SELF );
                }
            }),
            # ... accessor methods to primatives
            mop::internal::method::create( name => 'get_name',         body => sub { mop::internal::instance::get_data_at( $::SELF, '$name' ) } ),
            mop::internal::method::create( name => 'get_version',      body => sub { mop::internal::instance::get_data_at( $::SELF, '$version' ) } ),
            mop::internal::method::create( name => 'get_authority',    body => sub { mop::internal::instance::get_data_at( $::SELF, '$authority' ) } ),
            mop::internal::method::create( name => 'get_superclasses', body => sub { mop::internal::class::get_superclasses( $::SELF ) } ),
            mop::internal::method::create( name => 'get_methods',      body => sub { mop::internal::class::get_methods( $::SELF )      } ),
            mop::internal::method::create( name => 'get_attributes',   body => sub { mop::internal::class::get_attributes( $::SELF )   } ),
            mop::internal::method::create( name => 'get_mro',          body => sub { mop::internal::class::get_mro( $::SELF )          } ),
            # ... methods to build the class
            mop::internal::method::create( name => 'add_superclass', body => sub {
                my $superclass = shift;
                push @{ $::SELF->get_superclasses } => $superclass;
            }),
            mop::internal::method::create( name => 'add_method', body => sub {
                my $method = shift;
                mop::internal::method::associate_with_class( $method, $::SELF );
                mop::internal::method::set::insert(
                    $::SELF->get_methods,
                    $method
                );
            }),
            mop::internal::method::create( name => 'add_attribute', body => sub {
                my $attr = shift;
                mop::internal::attribute::associate_with_class( $attr, $::SELF );
                mop::internal::attribute::set::insert(
                    $::SELF->get_attributes,
                    $attr
                );
            }),
            # ... predicate methods
            mop::internal::method::create( name => 'is_subclass_of', body => sub {
                my $super = shift;
                my @mro   = @{ $::SELF->get_mro };
                shift @mro;
                scalar grep { $super->id eq $_->id } @mro;
            }),
            # ... class API
            mop::internal::method::create( name => 'FINALIZE', body => sub {
                $::SELF->add_superclass( $::Object )
                    unless scalar @{ $::SELF->get_superclasses };
            })
        )
    );

    $::Object = mop::internal::class::create(
        methods => mop::internal::method::set::create(
            mop::internal::method::create( name => 'id',    body => sub { mop::internal::instance::get_uuid( $::SELF )  } ),
            mop::internal::method::create( name => 'class', body => sub { mop::internal::instance::get_class( $::SELF ) } ),
            mop::internal::method::create( name => 'is_a',  body => sub { $::CLASS->id eq $_[0]->id || $::CLASS->is_subclass_of( $_[0] ) } ),
            mop::internal::method::create( name => 'new',   body => sub {
                my %args  = @_;

                my $data = {};

                foreach my $class ( @{ $::SELF->get_mro } ) {
                    my $attrs = $class->get_attributes;
                    foreach my $attr ( mop::internal::attribute::set::members( $attrs ) ) {
                        my $attr_name = mop::internal::attribute::get_name( $attr );
                        unless ( exists $data->{ $attr_name } ) {
                            $data->{ $attr_name } = mop::internal::attribute::get_initial_value_for_instance(
                                $attr
                            );
                        }
                    }
                }

                foreach my $arg ( keys %args ) {
                    my $value = $args{ $arg };
                    $data->{ '$' . $arg } = \$value;
                }

                my $self = bless(
                    mop::internal::instance::create(
                        \$::SELF,
                        $data
                    ),
                    'mop::syntax::dispatchable'
                );

                foreach my $class ( reverse @{ $::SELF->get_mro } ) {
                    if ( my $BUILD = mop::internal::class::find_method( $class, 'BUILD' ) ) {
                        mop::internal::method::execute( $BUILD, $self );
                    }
                }

                return $self;
            } )
        )
    );

    mop::internal::class::get_superclasses( $::Class )->[0] = $::Object;

    bless( $::Class, 'mop::syntax::dispatchable' );
    bless( $::Object, 'mop::syntax::dispatchable' );

    return;
}

1;

__END__

=pod

=head1 NAME

mop::internal::boostrap

=head1 DESCRIPTION

The boostratpping process is important, but a little ugly and
manual. The main goal of the bootstrap is to define the class Class
as well as the class Object, and to "tie the knot" such that the
following things are true:

  - Class is an instance of Class
  - Object is an instance of Class
  - Class is a subclass of Object

This is what will give us our desired "turtles all the way down"
metacircularity.

-head1 TODO

These definitions should actually get stripped down to their bare
minimums so that there is less to overwrite in the MOP boostrap
that we do later on.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package Class::Interfaces;

use strict;
use warnings;

our $VERSION = '0.01';

sub import {
    shift;
    my %interfaces = @_;
    foreach my $interface (keys %interfaces) {
        # build the interface
        my (@methods, @subclasses);
        if (ref($interfaces{$interface}) eq 'HASH') {
            my $interface_spec = $interfaces{$interface};
            # if we have an isa
            if (exists ${$interface_spec}{isa}) {
                # if is an array (multiple inheritance)
                if (ref($interface_spec->{isa}) eq 'ARRAY') {
                    @subclasses = @{$interface_spec->{isa}};
                }
                else {
                    # if its another kind of ref, its an error
                    (!ref($interface_spec->{isa}))
                        || die "Interface ($interface) isa list must be an array reference";
                    # otherwise its just a single item
                    @subclasses = $interface_spec->{isa};
                }
            }
            if (exists ${$interface_spec}{methods}) {
                (ref($interface_spec->{methods}) eq 'ARRAY')
                    || die "Method list for Interface ($interface) must be an array reference";
                @methods = @{$interface_spec->{methods}};
            }
        }
        elsif (ref($interfaces{$interface}) eq 'ARRAY') {
            @methods = @{$interfaces{$interface}};
        }
        else {
            die "Cannot use a " . $interfaces{$interface} . " to build an interface";
        }
        # now create the interfaces
        my $package = "package $interface;";
        $package .= "\@${interface}::ISA = qw(" . (join " " => @subclasses) . ");" if @subclasses;
        eval $package;
        die "Could not create Interface ($interface) because : $@" if $@;
        eval {
            no strict 'refs';
            foreach my $method (@methods) {
                ($method !~ /^BEGIN|INIT|CHECK|END|DESTORY|AUTOLOAD|import|bootstrap$/)
                    || die "Cannot create an interface using reserved perl methods";
                *{"${interface}::${method}"} = \&_method_sub;
            }
        };
        die "Could not create sub methods for Interface ($interface) because : $@" if $@;  
    }
}

sub _method_stub { die "Method Not Implemented" }

1;

__END__

=head1 NAME

Class::Interfaces - A module for defining interface classes inline

=head1 SYNOPSIS

  # define some simple interfaces
  use Class::Interfaces (
      Serializable => [ 'pack', 'unpack' ],
      Printable    => [ 'toString' ],
      Iterable     => [ 'iterator' ],
      Iterator     => [ 'hasNext', 'next' ]
      );
    
  # or some more complex ones ...
        
  # interface can also inherit from 
  # other interfaces using this form     
  use Class::Interfaces (
      BiDirectionalIterator => { 
          isa     => 'Iterator', 
          methods => [ 'hasPrev', 'prev' ] 
          },
      ResetableIterator => { 
          isa     => 'Iterator', 
          methods => [ 'reset' ] 
          },
      # we even support multiple inheritance
      ResetableBiDirectionalIterator => { 
          isa => [ 'ResetableIterator', 'BiDirectionalIterator' ]
          }
      );

=head1 DESCRIPTION

This module provides a simple means to define abstract class interfaces, which can be used to program using the concepts of interface polymorphism.

=head2 Interface Polymorphism

Interface polymorphism is a very powerful concept in object oriented programming. The concept is that if a class I<implements> a given interface it is expected to follow the guidelines set down by that interface. This in essence is a contract between the implementing class an all other classes, which says that it will provide correct implementations of the interfaces abstract methods. So it then becomes possible to treat an instance of an implementing class according to the interface and not need to know much of anything about the actual class itself. This can lead to highly generic code which is able to work with a wide range of virtually arbitrary classes just by using the methods of the certain interface which the class implements. Here is an example, using the interfaces from the L<SYNOPSIS> section:

  my $list = get_list();
  if ($list->isa('Iterable')) {
      my $iterator = $list->iterator();
      if ($iterator->isa('Iterator') {
          while ($iterator->hasNext()) {
              my $current = $iterator->next();
              if ($current->isa('Serializable')) {
                  store_into_database($current->pack());
              }
              elsif ($current->isa('Printable')) {
                  store_into_database($current->toString());
              }
              else {
                  warn "Unable to store $current into database : unrecognized object type";
              }
          }
      else {
          warn "Unrecognized iterator type : $iterator";
      }
  }
  else {
      warn "Unable to process list : is not an Iterable object";
  }
  
Now, this may seem like there is a lot of manual type checking, branching and error handling, this is due to perl's object type system. Some say that perl is a strongly typed langugage because a SCALAR cannot be converted (cast) as an ARRAY, and conversions to a HASH can only be done in limited circumstances. Perl enforces these rules at both compile and run time. However, this strong typing breaks down when it comes to perl's object system. If we could enforce object types in the same way we can enforce SCALAR, ARRAY and HASH types, then the above code would need less manual type checking and therefore less branching and error handling. For instance, below is a java-esque example of the same code, showing how type checking would simplify things.
  
  Iterable list = get_list();
  Iterator iterator = list.iterator();
  while (iterator.hasNext()) {
      try {
          store_into_database(iterator.next());
      }
      catch (Exception e) { 
          // ... do something with the exception
      }
  }

  void store_into_database (Serializable current) { ... }
  void store_into_database (Printable current) { ... }

While the java-esque example is much shorter, it is really doing the same thing, just all the type checking and error handling is performed by the language itself. But the power of the concept of interface polymorphism is not lost.

=head1 INTERFACE

Class::Interfaces is interacted with through the C<use> interface. It expects a hash of interface descriptors in the following formats.

=over 4

=item E<lt>I<interface name>E<gt> =E<gt> [ E<lt>list of method namesE<gt> ]

An interface can be simply described as an ARRAY reference containing method labels as strings.

=item E<lt>I<interface name>E<gt> =E<gt> { E<lt>interface descriptionE<gt> }

Another option is to use the HASH reference, which can support the following key value pair formats.

=over 4

=item isa =E<gt> E<lt>super interfaceE<gt>

An interface can inherit from another interface by assigning an interface name (as a string) as the value of the C<isa> key.

=item isa =E<gt> [ E<lt>list of super interfacesE<gt> ]

Or an interface can inherit from multiple interfaces by assigning an ARRAY reference of interface names (as strings) as the value of the C<isa> key.

=item methods =E<gt> [ E<lt>list of method namesE<gt> ]

An interface can define it's method labels as an ARRAY reference containing string as the value of the C<methods> key. 

=back

Obviously only one form of the C<isa> key can be used at a time (as the second would cancel first out), but you can use any other combination of C<isa> and C<methods> with this format.

=back

=head1 TO DO

The documentation needs work, but my head is swimming from allergies so this is good for now. 

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

 ------------------------ ------ ------ ------ ------ ------ ------ ------
 File                       stmt branch   cond    sub    pod   time  total
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 Class/Interfaces.pm       100.0  100.0    n/a  100.0    n/a  100.0  100.0
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 Total                     100.0  100.0    n/a  100.0    n/a  100.0  100.0
 ------------------------ ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

=over 4

=item L<Object::Interface>

=item L<interface>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


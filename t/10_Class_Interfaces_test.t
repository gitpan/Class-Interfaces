#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;

use_ok('Class::Interfaces' =>  (
    Serializable   => [ 'pack', 'unpack' ],
    Iterable       => [ 'iterator' ],
    Visitable      => [ 'visit' ],
    Saveable       => { isa => 'Serializable', methods => [ 'save', 'restore' ] },
    VisitOrIterate => { isa => [ 'Visitable', 'Iterable' ] },
    Printable      => { methods => [ 'toString', 'stringValue' ] },
    ));

can_ok("Serializable", 'pack');
can_ok("Serializable", 'unpack');

can_ok("Iterable", 'iterator');

can_ok("Visitable", 'visit');

isa_ok(bless({}, 'Saveable'), 'Serializable');
can_ok("Saveable", 'pack');
can_ok("Saveable", 'unpack');
can_ok("Saveable", 'save');
can_ok("Saveable", 'restore');

isa_ok(bless({}, 'VisitOrIterate'), 'Visitable');
isa_ok(bless({}, 'VisitOrIterate'), 'Iterable');
can_ok("VisitOrIterate", 'iterator');
can_ok("VisitOrIterate", 'visit');

can_ok("Printable", 'toString');
can_ok("Printable", 'stringValue');

# now check the error handling

eval {
    Class::Interfaces->import(
        Fail => sub {}
        );
};
like($@, qr/Cannot use a (.*?) to build an interface/, '... got the error we exepected');

eval {
    Class::Interfaces->import(
        Fail => { isa => sub {} }
        );
};
like($@, qr/Interface \(Fail\) isa list must be an array reference/, '... got the error we exepected');

eval {
    Class::Interfaces->import(
        Fail => { methods => sub {} }
        );
};
like($@, qr/Method list for Interface \(Fail\) must be an array reference/, '... got the error we exepected');

eval {
    Class::Interfaces->import(
        '+' => []
        );
};
like($@, qr/Could not create Interface \(\+\) because \: /, '... got the error we exepected');


eval {
    Class::Interfaces->import(
        Fail => [ 'BEGIN' ]
        );
};
like($@, qr/Could not create sub methods for Interface \(Fail\) because \: Cannot create an interface using reserved perl methods/, '... got the error we exepected');

eval {
    Class::Interfaces->_method_stub();
};
like($@, qr/Method Not Implemented/, '... got the error we expected');
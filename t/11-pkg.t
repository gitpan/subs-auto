#!perl -T

use strict;
use warnings;

use Test::More tests => 16;

our $foo;

{
 use subs::auto in => 'subs::auto::Test::Pkg';

 eval { subs::auto::Test::Pkg::foo 1 };
 is($@, '', 'compiled to subs::auto::Test::Pkg::foo(1)');
 is($foo, 3, 'subs::auto::Test::Pkg::foo was really called');

 {
  use subs::auto;

  eval { foo 2 };
  is($@, '', 'compiled to foo(2)');
  is($foo, 4, 'main::foo was really called');

  eval { subs::auto::Test::Pkg::foo 3 };
  is($@, '', 'compiled to subs::auto::Test::Pkg::foo(3)');
  is($foo, 9, 'subs::auto::Test::Pkg::foo was really called');

  {
   package subs::auto::Test::Pkg;

   eval { foo 4 };
   Test::More::is($@, '', 'compiled to foo(4)');
   Test::More::is($foo, 12, 'subs::auto::Test::Pkg::foo was really called');

   eval { main::foo 5 };
   Test::More::is($@, '', 'compiled to main::foo(5)');
   Test::More::is($foo, 10, 'main::foo was really called');
  }
 }
}

{
 package subs::auto::Test::Pkg;

 use subs::auto;

 eval { foo 6 };
 Test::More::is($@, '', 'compiled to foo(6)');
 Test::More::is($foo, 18, 'subs::auto::Test::Pkg::foo was really called');
}

{
 use subs::auto in => '::';

 eval { foo 7 };
 is($@, '', 'compiled to foo(7)');
 is($foo, 14, 'main::foo was really called');
}

{
 package subs::auto::Test;

 use subs::auto in => '::Pkg';

 {
  package subs::auto::Test::Pkg;

  eval { foo 8 };
  Test::More::is($@, '', 'compiled to foo(8)');
  Test::More::is($foo, 24, 'subs::auto::Test::Pkg::foo was really called');
 }
}

sub foo {
 $main::foo = 2 * $_[0];
}

sub subs::auto::Test::Pkg::foo {
 $main::foo = 3 * $_[0];
}

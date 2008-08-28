#!perl -T

use strict;
use warnings;

use Test::More tests => 12;

our $foo;

{
 use subs::auto in => 'subs::auto::Test::Pkg';

 eval { subs::auto::Test::Pkg::foo 5 };
 is($@, '', 'compiled to subs::auto::Test::Pkg::foo(5)');
 is($foo, 10, 'subs::auto::Test::Pkg::foo was really called');

 {
  use subs::auto;

  eval { foo 3 };
  is($@, '', 'compiled to foo(3)');
  is($foo, 3, 'main::foo was really called');

  {
   package subs::auto::Test::Pkg;

   eval { foo 7 };
   Test::More::is($@, '', 'compiled to foo(7)');
   Test::More::is($foo, 14, 'subs::auto::Test::Pkg::foo was really called');

   eval { main::foo 9 };
   Test::More::is($@, '', 'compiled to main::foo(9)');
   Test::More::is($foo, 9, 'main::foo was really called');
  }
 }
}

{
 use subs::auto in => '::';

 eval { foo 11 };
 is($@, '', 'compiled to foo(11)');
 is($foo, 11, 'main::foo was really called');
}

{
 package subs::auto::Test;

 use subs::auto in => '::Pkg';

 {
  package subs::auto::Test::Pkg;

  eval { foo 13 };
  Test::More::is($@, '', 'compiled to foo(13)');
  Test::More::is($foo, 26, 'subs::auto::Test::Pkg::foo was really called');
 }
}

sub foo {
 $main::foo = $_[0];
}

sub subs::auto::Test::Pkg::foo {
 $main::foo = 2 * $_[0];
}

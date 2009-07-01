package subs::auto;

use 5.010;

use strict;
use warnings;

use Carp qw/croak/;
use Symbol qw/gensym/;

use Variable::Magic qw/wizard cast dispell getdata/;

=head1 NAME

subs::auto - Read barewords as subroutine names.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    {
     use subs::auto;
     foo;             # Compile to "foo()"     instead of "'foo'"
                      #                        or croaking on strict subs
     foo $x;          # Compile to "foo($x)"   instead of "$x->foo"
     foo 1;           # Compile to "foo(1)"    instead of croaking
     foo 1, 2;        # Compile to "foo(1, 2)" instead of croaking
     foo(@a);         # Still ok
     foo->meth;       # "'foo'->meth" if you have use'd foo somewhere,
                      #  or "foo()->meth" otherwise
     print foo 'wut'; # print to the filehandle foo if it's actually one,
                      #  or "print(foo('wut'))" otherwise
    } # ... but function calls will fail at run-time if you don't
      # actually define foo somewhere
    
    foo; # BANG

=head1 DESCRIPTION

This pragma lexically enables the parsing of any bareword as a subroutine name, except those which corresponds to an entry in C<%INC> (expected to be class names) or whose symbol table entry has an IO slot (expected to be filehandles).

You can pass options to C<import> as key / value pairs :

=over 4

=item *

C<< in => $pkg >>

Specifies on which package the pragma should act. Setting C<$pkg> to C<Some::Package> allows you to resolve all functions name of the type C<Some::Package::func ...> in the current scope. You can use the pragma several times with different package names to allow resolution of all the corresponding barewords. Defaults to the current package.

=back

This module is B<not> a source filter.

=cut

BEGIN {
 croak 'uvar magic not available' unless Variable::Magic::VMG_UVAR;
}

my @core = qw/abs accept alarm atan2 bind binmode bless break caller chdir
              chmod chomp chop chown chr chroot close closedir connect
              continue cos crypt dbmclose dbmopen default defined delete die
              do dump each endgrent endhostent endnetent endprotoent endpwent
              endservent eof eval exec exists exit exp fcntl fileno flock fork
              format formline getc getgrent getgrgid getgrnam gethostbyaddr
              gethostbyname gethostent getlogin getnetbyaddr getnetbyname
              getnetent getpeername getpgrp getppid getpriority getprotobyname
              getprotobynumber getprotoent getpwent getpwnam getpwuid
              getservbyname getservbyport getservent getsockname getsockopt
              given glob gmtime goto grep hex index int ioctl join keys kill
              last lc lcfirst length link listen local localtime lock log
              lstat map mkdir msgctl msgget msgrcv msgsnd my next no oct open
              opendir ord our pack package pipe pop pos print printf prototype
              push quotemeta rand read readdir readline readlink readpipe recv
              redo ref rename require reset return reverse rewinddir rindex
              rmdir say scalar seek seekdir select semctl semget semop send
              setgrent sethostent setnetent setpgrp setpriority setprotoent
              setpwent setservent setsockopt shift shmctl shmget shmread
              shmwrite shutdown sin sleep socket socketpair sort splice split
              sprintf sqrt srand stat state study sub substr symlink syscall
              sysopen sysread sysseek system syswrite tell telldir tie tied
              time times truncate uc ucfirst umask undef unlink unpack unshift
              untie use utime values vec wait waitpid wantarray warn when
              write/;
push @core,qw/not __LINE__ __FILE__ DATA/;

my %core;
@core{@core} = ();
delete @core{qw/my local/};
undef @core;

my $tag = wizard data => sub { 1 };

sub _reset {
 my ($pkg, $func) = @_;
 my $fqn = join '::', @_;
 my $cb = do {
  no strict 'refs';
  no warnings 'once';
  *$fqn{CODE};
 };
 if ($cb and getdata(&$cb, $tag)) {
  no strict 'refs';
  my $sym = gensym;
  for (qw/SCALAR ARRAY HASH IO FORMAT/) {
   no warnings 'once';
   *$sym = *$fqn{$_} if defined *$fqn{$_}
  }
  undef *$fqn;
  *$fqn = *$sym;
 }
}

sub _fetch {
 (undef, my $data, my $func) = @_;
 return if $data->{guard} or $func =~ /::/ or exists $core{$func};
 local $data->{guard} = 1;
 my $hints = (caller 0)[10];
 if ($hints and $hints->{subs__auto}) {
  my $mod = $func . '.pm';
  if (not exists $INC{$mod}) {
   my $fqn = $data->{pkg} . '::' . $func;
   if (do { no strict 'refs'; not *$fqn{CODE} || *$fqn{IO}}) {
    my $cb = sub {
     my ($file, $line) = (caller 0)[1, 2];
     ($file, $line) = ('(eval 0)', 0) unless $file && $line;
     die "Undefined subroutine &$fqn called at $file line $line\n";
    };
    cast &$cb, $tag;
    no strict 'refs';
    *$fqn = $cb;
   }
  }
 } else {
  _reset($data->{pkg}, $func);
 }
 return;
}

sub _store {
 (undef, my $data, my $func) = @_;
 return if $data->{guard};
 local $data->{guard} = 1;
 _reset($data->{pkg}, $func);
 return;
}

my $wiz = wizard data  => sub { +{ pkg => $_[1], guard => 0 } },
                 fetch => \&_fetch,
                 store => \&_store;

my %pkgs;

sub _validate_pkg {
 my ($pkg, $cur) = @_;
 return $cur unless $pkg;
 croak 'Invalid package name' if ref $pkg
                              or $pkg =~ /(?:-|[^\w:])/
                              or $pkg =~ /(?:\A\d|\b:(?::\d|(?:::+)?\b))/;
 $pkg =~ s/::$//;
 $pkg = $cur . $pkg if $pkg eq '' or $pkg =~ /^::/;
 $pkg;
}

sub import {
 shift;
 croak 'Optional arguments must be passed as keys/values pairs' if @_ % 2;
 my %args = @_;
 my $cur  = (caller 1)[0];
 my $in   = _validate_pkg $args{in}, $cur;
 $^H{subs__auto} = 1;
 ++$pkgs{$in};
 no strict 'refs';
 cast %{$in . '::'}, $wiz, $in;
}

sub unimport {
 $^H{subs__auto} = 0;
}

{
 no warnings 'void';
 CHECK {
  no strict 'refs';
  dispell %{$_ . '::'}, $wiz for keys %pkgs;
 }
}

=head1 EXPORT

None.

=head1 CAVEATS

C<*{'::foo'}{CODE}> will appear as defined in a scope where the pragma is enabled, C<foo> is used as a bareword, but is never actually defined afterwards. This may or may not be considered as Doing The Right Thing. However, C<*{'::foo'}{CODE}> will always return the right value if you fetch it outside the pragma's scope. Actually, you can make it return the right value even in the pragma's scope by reading C<*{'::foo'}{CODE}> outside (or by actually defining C<foo>, which is ultimately why you use this pragma, right ?).

You have to open global filehandles outside of the scope of this pragma if you want them not to be treated as function calls. Or just use lexical filehandles and default ones as you should be.

=head1 DEPENDENCIES

L<perl> 5.10.0.

L<Carp> (standard since perl 5), L<Symbol> (since 5.002).

L<Variable::Magic> with C<uvar> magic enabled (this should be assured by the required perl version).

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-subs-auto at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=subs-auto>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc subs::auto

Tests code coverage report is available at L<http://www.profvince.com/perl/cover/subs-auto>.

=head1 ACKNOWLEDGEMENTS

Thanks to Sebastien Aperghis-Tramoni for helping to name this pragma.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of subs::auto

use 5.010;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = 'subs-auto';

my %META = (
 configure_requires => {
  'ExtUtils::MakeMaker' => 0,
 },
 build_requires => {
  'ExtUtils::MakeMaker' => 0,
  'Test::More'          => 0,
 },
 resources => {
  bugtracker => "http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/?p=perl%2Fmodules%2F$dist.git",
 },
);

WriteMakefile(
    NAME             => 'subs::auto',
    AUTHOR           => 'Vincent Pit <perl@profvince.com>',
    LICENSE          => 'perl',
    VERSION_FROM     => 'lib/subs/auto.pm',
    ABSTRACT_FROM    => 'lib/subs/auto.pm',
    PL_FILES         => {},
    PREREQ_PM        => {
        'Carp'            => 0,
        'Symbol'          => 0,
        'Variable::Magic' => 0.08
    },
    MIN_PERL_VERSION => 5.010,
    META_MERGE       => \%META,
    dist             => {
        PREOP    => 'pod2text lib/subs/auto.pm > $(DISTVNAME)/README',
        COMPRESS => 'gzip -9f', SUFFIX => 'gz'
    },
    clean            => {
        FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt"
    }
);

1;

package MY;

sub postamble {
 my $cv = join ' -coverage ', 'cover',
                            qw/statement branch condition path subroutine time/;
 <<POSTAMBLE;
cover test_cover:
	$cv -test
POSTAMBLE
}

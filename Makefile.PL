use 5.010;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $BUILD_REQUIRES = {
 'ExtUtils::MakeMaker' => 0,
 'Test::More'          => 0,
};

sub build_req {
 my $tometa = ' >> $(DISTVNAME)/META.yml;';
 my $build_req = 'echo "build_requires:" ' . $tometa;
 foreach my $mod ( sort { lc $a cmp lc $b } keys %$BUILD_REQUIRES ) {
  my $ver = $BUILD_REQUIRES->{$mod};
  $build_req .= sprintf 'echo "    %-30s %s" %s', "$mod:", $ver, $tometa;
 }
 return $build_req;
}

WriteMakefile(
    NAME          => 'subs::auto',
    AUTHOR        => 'Vincent Pit <perl@profvince.com>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/subs/auto.pm',
    ABSTRACT_FROM => 'lib/subs/auto.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Carp'            => 0,
        'Symbol'          => 0,
        'Variable::Magic' => 0.08
    },
    dist          => {
        PREOP      => 'pod2text lib/subs/auto.pm > $(DISTVNAME)/README; '
                      . build_req,
        COMPRESS   => 'gzip -9f', SUFFIX => 'gz'
    },
    clean         => { FILES => 'subs-auto-* *.gcov *.gcda *.gcno cover_db' }
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

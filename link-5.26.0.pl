#!perl
use strict;
use warnings;

use File::Spec::Functions qw( rel2abs catdir abs2rel );
use File::Basename qw( dirname );
use File::Find qw( find );
use Term::ANSIColor qw( colored );
use constant SAFEDIR  => '/etc/portage/3rd-party/perl-testing-profiles';
use constant TARGET   => '/etc/portage/';
use constant MYDIR    => rel2abs( dirname(__FILE__) );
use constant LINKBASE => catdir( MYDIR, '5.26.0' );

use constant ERR => colored( [ 'bold', 'red' ], "ERROR" ) . ": ";

MYDIR eq SAFEDIR
  or die sprintf ERR
  . "This script is not in the documented fixed location required for safe operation.\n"
  . "     Got: %s\n"
  . "Expected: %s\n\nFailed", colored( ['yellow'], MYDIR ),
  colored( ['green'], SAFEDIR );

-d LINKBASE
  or die sprintf ERR
  . "Link Base path %s is not an existing directory: %s\n\nFailed",
  colored( ['yellow'], LINKBASE ), $!;

-d TARGET
  or die sprintf ERR
  . "Portage config dir %s is not an existing directory: %s\n\nFailed",
  colored( ['yellow'], TARGET ), $!;

for my $subdir (qw( profile env package.env )) {
    my $newdir = catdir( TARGET, $subdir );
    next if -d $newdir;
    printf colored( [ 'bold', 'green' ], '→' ) . " mkdir %s\n",
      colored( ['yellow'], $newdir );
    mkdir $newdir
      or die sprintf ERR . "Can't mkdir %s, %s\n\nFailed",
      colored( ['yellow'], $newdir ), $!;
}
for my $subdir (qw( profile env package.env )) {
    my $newdir     = catdir( TARGET,   $subdir );
    my $source_dir = catdir( LINKBASE, $subdir );

    find(
        {
            follow   => 0,
            no_chdir => 1,
            wanted   => sub {
                my $dest_file =
                  catdir( $newdir, abs2rel( "$_", "$source_dir" ) );
                if ( -d "$_" ) {
                    return if -d "$dest_file";
                    printf colored( [ 'bold', 'green' ], '→' )
                      . " mkdir %s\n",
                      colored( ['yellow'], $dest_file );
                    mkdir $dest_file
                      or die sprintf ERR . "Can't mkdir %s, %s\n\nFailed",
                      colored( ['yellow'], $dest_file ), $!;
                    return;
                }
                my $relpath = abs2rel( "$_", dirname($dest_file) );
                print colored( [ 'bold', 'green'], '→' );
                print " $dest_file -> $relpath\n";
                symlink "$relpath", "$dest_file" or die "Can't make $dest_file";
            }
        },
        $source_dir
    );
}

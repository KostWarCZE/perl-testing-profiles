#!perl
use strict;
use warnings;

use File::Find;
use File::Spec qw( rel2abs );
use Term::ANSIColor qw( colored );

my $do_it;
my $fmt_msg = "Would unlink %s (-> %s )";
if ( grep {qr{\A--do\z}} @ARGV ) {
  $do_it = 1;
  $fmt_msg = colored(['bold','red'], " → ") .  "Unlinking %s (-> %s )";
}

my $opts = { follow => 0 , no_chdir => 1 };
$opts->{wanted} = sub {
  return unless -e $_;
  return unless -l $_;
  my $dest = readlink $_;

  if ( $dest =~ qr{3rd-party/perl-testing-profiles} ) {
      printf "${fmt_msg}\n", colored([ 'bold', 'yellow' ], $_ ), colored([ 'green' ], $dest );
      if ( $do_it ) {
        unlink "$_" or die colored(['bold','red'], "Error unlinking $_, $!");
      }
  }
};
File::Find::find($opts, "/etc/portage");

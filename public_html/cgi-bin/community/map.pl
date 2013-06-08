#!/usr/bin/perl -w
#!/usr/local/bin/perl5.16.3 -w
#!/usr/local/bin/perl -w
#
# kjolley
# Sat Apr 20 14:55:23 PDT 2013
#

use strict;
use File::Basename;
use Getopt::Long;

my $bin = basename $0;

my $map   = "/tmp/nodes.txt";
my $input = "/tmp/edges.txt";
my $direction = "forward";
my %h    = ();

GetOptions(
    "map=s"       => \$map,
    "input=s"     => \$input,
    "direction=s" => \$direction,
);

$direction = lc($direction);
die "you may only map FORWARD or REVERSE\n" unless ($direction eq 'forward' or $direction eq 'reverse');
my $forward = ($direction eq 'forward') ? 1 : 0;

open (MAP, "$map")
  or die "ERROR: $bin: Can't read $map: $!\n";
while (<MAP>) {
  chomp;
  if ($forward) {
    $h{$_}="".$.;
  } else {
    $h{$.}="".$_;
  }
}
close (MAP)
    or die "ERROR: $bin: Can't close $map: $!\n";

open (INPUT, "$input")
  or die "ERROR: $bin: Can't read $input: $!\n";

if ($forward) {
  while (<INPUT>) {
    my ($source, $target, $weight) = split;
    next unless ($source && $target && $weight);
    print "$h{$source}\t$h{$target}\t$weight\n";
  }
} else {
  print "name\tcommunity\n";
  while (<INPUT>) {
    my ($id, $community) = split;
    print "$h{$id}\t$community\n" if defined($h{$id});
  }
}

close (INPUT)
    or die "ERROR: $bin: Can't close $input: $!\n";

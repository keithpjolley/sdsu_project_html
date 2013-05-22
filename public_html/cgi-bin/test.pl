#!/usr/local/bin/perl -w

use v5.10;
use strict;
use File::Basename;

my $bin = basename $0;

my $attribs =  "include/attributes/nodes";
my %hash    = ();

open (FILE, "$attribs")
  or die "ERROR: $bin: Can't read $attribs: $!\n";
while (<FILE>) {
  chomp;
  my ($attrib, $key, $value) = split /;/;
#  say "$name # $attrib # $value";
  $hash{$attrib}{$key} = $value;
}
close (FILE)
    or die "ERROR: $bin: Can't close $attribs: $!\n";

#graph_strength_in : order : 9
#graph_strength_in : popup_text : Total incoming edges.
#graph_strength_in : display_name : Strength In

for my $attrib (sort { $hash{$a}{'order'} <=> $hash{$b}{'order'} } keys %hash) {
  my $order = $hash{$attrib}{'order'};
  my $pop   = $hash{$attrib}{'popup_text'};
  my $name  = $hash{$attrib}{'display_name'};
  say "attrib : $attrib";
  say " order : $order";
  say "  name : $name";
  say "   pop : $pop";
  say "";
}

#!/usr/local/bin/perl5.16.3 -w
#
# kjolley
# Thu May  2 05:40:09 PDT 2013
#
use v5.10;
use strict;
use File::Basename;
use JSON::PP;
sub jsonprint;

my $bin = basename $0;

my caveat<<EOF1;

Please note that graphs that search by a particular mailing list tend to not be very interesting.
This is because the graph is so constricted - all connections are to/from a single person. Searches
on topics, or lists if available, tend to be much more interesting.

EOF1

my $topiclist = "./html/input/net.list";
my %topics = ();
my %list_interesting = ();
my %list_seen = ();
my %people_interesting = ();
my %people_seen = ();

my $topic_json   = "./html/input/interesting_topic.json";
my $list_json   = "./html/input/interesting_list.json";
my $people_json = "./html/input/interesting_people.json";

my $topic_html   = "./html/input/interesting_topic.html";
my $list_html   = "./html/input/interesting_list.html";
my $people_html = "./html/input/interesting_people.html";

# topics in subject
open (FILE, "$topiclist")
  or die "ERROR: $bin: Can't read $topiclist: $!\n";
while (<FILE>) {
  chomp;
  my ($source, $target, $list, $subject) = split(/\t/);
  # find lists that have a lot of different people sending and receiving from it
  next unless $source && $target && $list && $subject;
  $list_interesting{$list}++ if (!$list_seen{$source});
  $list_interesting{$list}++ if (!$list_seen{$target});
  $people_interesting{$source}++ if (!$people_seen{$target}{$source});
  $people_interesting{$target}++ if (!$people_seen{$source}{$target});
  $list_seen{$source}++;
  $list_seen{$target}++;
  $people_seen{$source}{$target}++;
  $people_seen{$target}{$source}++;
  # find commo topics - will heavily weight towards "automated" mailing lists, like status reports
  for (split ' ', $subject) {
    next if /^(.{1,3}|next|qualcomm|mail|users|with|your|what|meeting|status|does|from)$/;
    s/^update.*/update/;
    $topics{$_}++;
  }
}
close (FILE)
  or die "ERROR: $bin: Can't close $topiclist: $!\n";

# keep only the the top $n topics
my $n = 10;
for my $key (sort { $topics{$b} <=> $topics{$a} } keys %topics) {
  delete $topics{$key} unless ($n-->0);
}
$n = 10;
for my $key (sort { $list_interesting{$b} <=> $list_interesting{$a} } keys %list_interesting) {
  delete $list_interesting{$key} unless ($n-->0);
}
$n = 10;
for my $key (sort { $people_interesting{$b} <=> $people_interesting{$a} } keys %people_interesting) {
  if (-f "./html/input/mailing-lists/$key") {
    delete $people_interesting{$key};
  } else {
    delete $people_interesting{$key} unless ($n-->0);
  }
}

#jsonprint (\%topics,              $topic_json);
#jsonprint (\%list_interesting,   $list_json);
#jsonprint (\%people_interesting, $people_json);

htmlprint (\%topics,             $topic_html,  "topics", "");
htmlprint (\%list_interesting,   $list_html,   "lists",  "");
htmlprint (\%people_interesting, $people_html, "people", "$caveat");

sub jsonprint {
  my $href = shift;
  my $file = shift;
  say "JSON output to: $file";
  open (FILE, ">$file") or die "ERROR: $bin: Can't open $file: $!\n";
  my $json = JSON::PP->new->allow_nonref->pretty;
  say      $json->sort_by(sub { lc($JSON::PP::a) cmp lc($JSON::PP::b) })->encode($href);
  say FILE $json->sort_by(sub { lc($JSON::PP::a) cmp lc($JSON::PP::b) })->encode($href);
  close (FILE) or die "ERROR: $bin: Can't close $file: $!\n";
}

sub htmlprint {
  my $href = shift;
  my $file = shift;
  my $type = shift;
  my $note = shift;
  say "HTML output to: $file";
  open (FILE, ">$file") or die "ERROR: $bin: Can't open $file: $!\n";
  say FILE "<!DOCTYPE html>\n<html>\n<head><title>Connected $type</title></head>\n<body>";
  say FILE "These $type were found in a large number of conversations across the dataset.";
  say FILE "<p>$note</p>" if ($note);
  say FILE "<ul>";
  for my $key (keys $href) {
    say $key;
    say FILE "<li>$key</li>";
  }
  say FILE "</ul></body>\n</html>";
  close (FILE) or die "ERROR: $bin: Can't close $file: $!\n";
}

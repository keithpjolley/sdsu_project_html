#!/usr/local/bin/perl5.16.3 -w

# kjolley

BEGIN { $Pod::Usage::Formatter = 'Pod::Text::Termcap'; }

use strict;

use Cwd qw(abs_path getcwd);
use Data::Dumper;
use Date::Parse;
use Email::Address;
use File::Basename;
use Getopt::Long;
use Mail::MboxParser;
use Pod::Usage qw(pod2usage);

sub sumit;
sub parseit;
sub expandlists;

my $bin = basename $0;

my $dryrun  = 0;
my $verbose = 0;
my $nocache = 0;
my $help    = 0;
my $sum     = 0;
my $expand  = 0;
my %hash    = ();
my %sum     = ();

GetOptions (
  "verbose:0" => \$verbose,  # flag
  "nocache"   => \$nocache,  # flag
  "sum"       => \$sum,      # flag
  "help"      => \$help,     # flag
  "expand"    => \$expand,   # flag
);

print STDERR "VERBOSE: $bin: \$verbose: $verbose\n" if $verbose>0;
print STDERR "VERBOSE: $bin:     \$sum: $sum\n"     if $verbose>0;
print STDERR "VERBOSE: $bin:  \$expand: $expand\n"  if $verbose>0;
print STDERR "VERBOSE: $bin: \$nocache: $nocache\n"  if $verbose>0;

pod2usage(-exitval=>0,-verbose=>2) if ($help);
pod2usage(-exitval=>1,-verbose=>0) if ($#ARGV<0);

# get all the folks on various mailing lists
expandlists() if ($expand);
my $suffix = (($expand) ? ".expanded" : ".noexpand") . ".cache";

for my $file (@ARGV) {
  print STDERR "VERBOSE: $bin: LOOP:\n" if $verbose>=200;
  my $cachefile = "$file" . "$suffix";
  if ($nocache or ! (-f $cachefile and -r $cachefile)) {
    print STDERR "VERBOSE: $bin: parsing input file: $file\n" if ($verbose>0);
    unless (-f $file and -r $file) {
      warn "WARNING: $bin: cannot read input file: $file. Skipping."
    } elsif ($file =~ m/($suffix)$/)  {
      warn "WARNING: $bin: this looks like a cache file: $file. Skipping."
    } else {
      my $cachefile = "$file" . "$suffix";
      print STDERR "VERBOSE: $bin: creating cache file: $cachefile\n" if $verbose>0;
      open (CFILE, ">$cachefile")
        or die "ERROR: $bin: Can't open $cachefile: $!\n";
      print STDERR "VERBOSE: $bin: pre-parseit:\n" if $verbose>=200;
      parseit($file, $cachefile);
      close (CFILE)
        or die "ERROR: $bin: Can't close $cachefile: $!\n";
    }
  } else {
    print STDERR "VERBOSE: $bin: using cache file: $cachefile\n" if ($verbose>0);
    open (CFILE, "$cachefile")
        or die "ERROR: $bin: Can't read $cachefile: $!\n";
    if ($sum) {
      while (<CFILE>) {
        chomp;
        sumit((split(/\t/))[0,1]);
      }
    } else {
      while (<CFILE>) { print; }
    }
    close (CFILE)
      or die "ERROR: $bin: Can't close $cachefile: $!\n";
  }
}

exit unless ($sum);

for my $from (keys %sum) {
  for my $target (keys %{$sum{$from}}) {
    print "$from\t$target\t$sum{$from}{$target}\n";
  }
}

sub expandlists () {
  my $expanddir = "mailing-lists";
  return if (! -d $expanddir);
  my $cwd = getcwd();
  if (!chdir($expanddir)) {
    warn "WARNING: $bin: couldn't chdir into $expanddir. Skipping list expansion. ";
    return;
  }
  for my $list (glob "*")
  {
    $list = lc($list);
    print STDERR "VERBOSE: $bin: expanding $list\n" if ($verbose == 2);
    open (INLIST, "$list")
        or warn "WARNING: $bin: Will not expand \"$list\" list. Can't read $list: $!\n";
    while (<INLIST>) {
      chomp;
      for (split) {
        $hash{$list}{lc($_)}++;
      }
    }
    close (INLIST)
        or warn "WARNING: $bin: Can't close $list: $!\n";
  } 
  chdir($cwd);
  return;
}

sub parseit () {
  my $file      = shift;
  my $cachefile = shift;
  my $parseropts = { enable_grep => 1 };
  my $mb = Mail::MboxParser->new(
    $file,
    decode     => 'ALL',
    parseropts => $parseropts
  );
  # iterating
  print STDERR "VERBOSE: $bin: parseit:\n" if $verbose>=200;
  while (my $msg = $mb->next_message) {
    print STDERR Dumper($msg->header) if $verbose>=2000;
    my $from = $msg->header->{from};
    next unless defined $from;  # something bad happened...
    $from  = (Email::Address->parse($from))[0]->user;
    my $to = $msg->header->{to} || "";
    my $cc = $msg->header->{cc} || "";
    my @to_names= ();
    print STDERR "VERBOSE: $bin: raw: \$to: $to\n" if $verbose>=200;
    next unless ($to or $cc);
#for (Email::Address->parse($to), Email::Address->parse($cc)) {
    for my $user ((split (/ /, $to)), (split (/ /, $cc))) {
#my $user = $_->user;
      $user = lc($user);
      $user =~ s/\'//g;
      $user =~ s/\@(.*\.)?enron.com//;
      $user =~ s/,//g;
      print STDERR "VERBOSE: $bin: cooked: \$user: $user\n" if $verbose>=200;
      if ($hash{$user}) {
        # this is a mailing list with members
        for my $member (keys %{$hash{$user}}) {
          print STDERR "VERBOSE: $bin: adding $member from list $user\n" if ($verbose>10);
          push (@to_names, lc($member));
        }
      } else {
        push (@to_names, $user);
      }
    }
    my $subject = lc($msg->header->{subject})   || "";
    my $datesent= str2time($msg->header->{date} || 0);
    #my $quotes  = $msg->body($msg->find_body)->quotes->{0};
    my $list    = lc(basename(dirname(abs_path($file))));
    if ($verbose>=5) {
      print STDERR "\n";
      print STDERR "     from: " . $from . "\n";
      print STDERR "       to: @to_names" . "\n";
      for my $name (@to_names) {
        print STDERR "      list: $name\n" if ($hash{$name});
      }
      print STDERR "  subject: " . $subject . "\n";
      print STDERR " datesent: " . $datesent . "\n";
      print STDERR "     list: " . $list . "\n";
      print STDERR "     file: " . $file . "\n";
    }

    next unless ($from and $list and @to_names);
    $subject = "__NO_SUBJECT__" unless $subject;
    $datesent = localtime unless $datesent;

    if ($sum) {
      sumit($from, @to_names);
    } else {
      for my $target (@to_names) {
        print "$from\t$target\t$list\t$subject\t$datesent\n"
      }
    }

    unless ($nocache) {
      for my $target (@to_names) {
        print CFILE "$from\t$target\t$list\t$subject\t$datesent\n";
      }

    }
  }
}

sub sumit () {
  my ($from, @to_names) = @_;
  for my $target (@to_names) {
    $sum{$from}{$target}++;
  }
  return;
}


__END__

=head1 NAME

mailar.parser.pl

=head1 SYNOPSIS

mailar.parser.pl [--help] [--verbose[=N]] [--nocache] [--sum] [--noexpand] file [file [...]]

=head1 DESCRIPTION

B<mailar.parser.pl> will read the given input file(s) and do something
useful with the contents thereof.

input B<file> is an mbox file to be parsed. B<mailar.parser.pl> also
looks for map named "./expand/maillist". These should be a list of email
addresses. anytime the parser sees the token "maillist" it expands that
out to "name1 name2 ..."

=head1 OPTIONS

=over 8

=item B<--help>

Print this helpful message and exit.

=item B<--verbose>

Be verbose. Sends messages to stdout. Higher "N" for higher verbosiosity.

=item B<--sum>

summarize -- creates summmary stats. this was done faster by awk or R so i don't use it here.

=item B<--noexpand>

expand reads each file in the directory "mailing-lists".  any time it sees an email address like
mailing-lists/listname it will expand "listname" out to every token it finds in the listname file.

for instance, if "mailing-lists/dogs.mail" has "joe bob sue", then anytime "dogs.mail" is seen it
will get expanded to one line each of "joe", "bob", and "sue". format of the file is pretty loose.

=item B<--nocache>

Ignore the cache files, do not create cache files. Normally when this program
is run it has to parse through each and every mbox file. This is expensive and
slow. This program creates a "mbox.cache" file by default. If it also uses a
preparsed "mbox.cache" file if it can. This is about 2000% times faster on
my host so I recommend it. Yes, I could have used SQLite.

If you are trying to use this program to parse your cache files -- don't. Use
B<cat file.cache> instead.

=back

=head1 EXAMPLE

C<find input -type f -name \*.mbox | xargs mailar.parser.pl>

=head1 AUTHOR

keith p. jolley

v0.00000000000001     Sat Mar  9 10:25:37 PST 2013

v0.00000000000001.001 Thu Apr 18 19:16:31 PDT 2013

=cut

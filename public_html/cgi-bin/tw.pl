#!/usr/local/bin/perl5.16.3 -w

# kjolley
# April 01, 2013

#use v5.10;
use strict;
use CGI qw(:standard *table);
use File::Basename;
use File::Temp qw(tempdir);
use Sys::Hostname;
use JSON::PP;
use Cwd;
#use Data::Dumper;

my $bin = basename $0;

# make sure R is in my path
$ENV{'PATH'} = '/home/student/jolley/bin' . ':' . $ENV{'PATH'} if (hostname eq 'volta');
$ENV{'LC_CTYPE'} = 'C';
$ENV{'LANG'} = 'C';

# python server acts differently than apache
chdir("cgi-bin") if ((-d "cgi-bin") and (basename(getcwd) eq "public_html"));
my $dir = getcwd;
die "ERROR: $bin: must be invoked from 'cgi-bin'. Called from: " . $dir unless (basename($dir) eq "cgi-bin");

# include is inside the cgi-bin directory. it contains all the js and css files
# input is created during pre-processing. it contains, at minimum, the netlist
my $input    = ($bin eq "tw-qcom.pl") ? "../input.qcom" : "../input.enron";
my $include  = "../include";

# filesystem paths
my $thelist  = "$input/net.list";  
my $maillist = "$input/mailing-lists";
my $topicpop = "$input/interesting_topic.html";
my $mlistpop = "$input/interesting_list.html";
my $emailpop = "$input/interesting_people.html";
my $d3js     = "$include/myD3.js";  
my $jdir     = "../__cache__/JSON";

# url paths
my $inc_url  = url(-base=>1) . dirname (dirname (url(-absolute=>1))) . "/";
my @css      = ($inc_url . "include/css/style.css",
                $inc_url . "include/css/demo_table.css",);
my @js       = ($inc_url . "include/d3.v3.min.js",
                $inc_url . "include/DataTables-1.9.4/media/js/jquery.js",
                $inc_url . "include/DataTables-1.9.4/media/js/jquery.dataTables.js",);

if (! -d $jdir) {
  warn "MESSAGE: $bin: creating JSON dir: $jdir";
  warn "MESSAGE: $bin: cwd: " . getcwd;
  mkdir ($jdir)
    or die "ERROR: $bin: no JSON dir: $jdir: $!";
}

$maillist = 0 if (! -d $maillist);
$topicpop = 0 if (! -f $topicpop);
$mlistpop = 0 if (! -f $mlistpop);
$emailpop = 0 if (! -f $emailpop);

sub mydiv;
sub dograph;
sub fixnans;
sub fmt;
sub footer;
sub json2table;
sub metrics;
sub netword;
sub printplaintable;
sub printattribtable;
sub search;
sub showgraph;
sub wanted;

my $tablejs = <<'EOF';
    $(document).ready(function() {
        $('.dataTable').dataTable();
        } );
EOF

my $title    = ($bin eq "tw-qcom.pl") ? "QUALCOMM" : "ENRON";

print
  header,
  start_html(
    -title =>$title . ' Community Network',
    -style => {-type=>"text/css", -src=>[@css]},
    -script=> [ { -language=>'javascript', -charset=>"utf-8",  -src=>$js[0]},  # not sure why i can't use @js like above.
                { -language=>'javascript', -charset=>"utf-8",  -src=>$js[1]},
                { -language=>'javascript', -charset=>"utf-8",  -src=>$js[2]},
                { -language=>'javascript', -charset=>"utf-8", -code=>$tablejs},
              ],
  ),
  mydiv('left'),
  start_form,
  table({-id=>"tokens"},
    Tr(
      [
        th([
              "All Fields",
              "Topic",
              ($maillist
                ? ("Mail List", "People (email)")
                : "People (email)"
              ),
           ]),
        td([
              textfield(-name=>'all', -size=>45),
              textfield(-name=>'topic'),
              ($maillist
                ? (textfield(-name=>'mlist'), textfield(-name=>'email'))
                :  textfield(-name=>'email')
              ),
           ]),
        (($topicpop or $mlistpop or $emailpop) ?
          td([
                (submit . "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; suggested queries:"),
                $topicpop ? a({-href=>"$topicpop", -target=>"_blank"}, "topics")          : "(none)",
                ($maillist
                  ? (($mlistpop ? a({-href=>"$mlistpop", -target=>"_blank"}, "mail lists")      : "(none)"),
                     ($emailpop ? a({-href=>"$emailpop", -target=>"_blank"}, "email addresses") : "(none)"))
                  :  ($emailpop ? a({-href=>"$emailpop", -target=>"_blank"}, "email addresses") : "(none)")
                ),
           ])
        :
          td( {-colspan=>($maillist ? "4" : "3")}, (submit . '&nbsp run "goodword.pl" to enable suggestions')),
        ),
        td( {-colspan=>"0"}, "Using " . $title . " data"),
      ]),
  ),
  p,
  end_form,
  mydiv('close');

if (param) {
  mydiv('left');
  my ($json, $mfile) = dograph();
  mydiv('close');
  json2table($json);
  metrics($mfile);
}

print footer, end_html . "\n";
exit;

sub mydiv {
  my $pos = shift;
  my $ret = '</div>';
  if ($pos eq 'left' or $pos eq 'right' or $pos eq 'full') {
    $ret = '<div class="' . $pos . '">';
  }
  $ret .= "\n";
  return ($ret);
}

sub footer {
  return <<'EOF1'
  <div id="footer" style="background-color:#003399;clear:both;text-align:center;color:#FFF;">
  Content may be QUALCOMM Proprietary</div>
EOF1
}

sub dograph {
  # prints the D3 script, returns the location of the $json and $mfile files
  die "ERROR: $bin: 16. no json dir $jdir" unless -d $jdir;
  die "ERROR: $bin: 17. can't read input list $thelist" unless -r $thelist;
  my $topic = param('topic') || "";  # make sure that the query variables are set to something
  my $mlist = param('mlist') || "";
  my $email = param('email') || "";
  my $all   = param('all')   || "";
  $topic =~ tr/[A-Za-z0-9_.^\$ -//dc; # only allow these characters to pass through
  $mlist =~ tr/[A-Za-z0-9_.^\$ -//dc;
  $email =~ tr/[A-Za-z0-9_.^\$ -//dc;
  $all   =~ tr/[A-Za-z0-9_.^\$ -//dc;
  my $qfile = "query." . join('.', sort(split(' ', $topic)))  # make a name safe for the filesystem
                 . "." . join('.', sort(split(' ', $mlist)))  # to store info about this query
                 . "." . join('.', sort(split(' ', $email)))
                 . "." . join('.', sort(split(' ', $all)));
  $topic = join('|', split(' ', $topic)); # our regex - make all searchs an "or"
  $mlist = join('|', split(' ', $mlist));
  $email = join('|', split(' ', $email));
  $all   = join('|', split(' ', $all));

  my $tmpdir = tempdir(CLEANUP => 0)
    or die "ERROR: $bin: 18. couldn't create tempdir: $!";
  my $net  = "$tmpdir/$qfile.net";
  my $json = "$jdir/$qfile.json";
  my $mfile = "";
  if ($topic eq "" && $mlist eq "" && $email eq "" && $email eq "" && $all eq "") {
    print "<h2>empty search</h2>\n";
  } else {
    my $edges = search($topic, $mlist, $email, $all, $net);
    if ($edges==0) {
      print "Sorry. no search results found", p, "\n";
    } else {
      $mfile = netword($mlist, $net, $tmpdir, $qfile, $json);
      # this test is wrong - json can still have a few lines and be "empty"
      if (-z $json) {
        print "Sorry. no search results found", p, "\n";
      } else {
        showgraph($json);
      }
    }
  }
  return ($json, $mfile);
}

sub search {
  my $topic = shift;
  my $mlist = shift;
  my $email = shift;
  my $all   = shift;
  my $net   = shift;
  my $edges = 0;

  open (LIST, "$thelist")
      or die "ERROR: $bin: 1. Can't read $thelist: $!\n";
  my @lines = <LIST>;
  close (LIST)
      or die "ERROR: $bin: 2. Can't close $thelist: $!\n";
  open (NET, ">$net")
      or die "ERROR: $bin: 3. Can't open $net: $!\n";

#  warn "\$all: $all";
#  warn "\$topic: $topic";
#  warn "\$mlist: $mlist";
#  warn "\$email: $email";

#  my $warn = 0;
  for (@lines) {
    my $n = 0;
    my ($source, $target, $list, $subject) = split /\t/;
#   if ($warn < 5 && ($list eq "skilling-j")) {
#     warn "\$list: $list  ---------  \$mlist: $mlist";
#     warn "list is defined" if defined $list;
#     warn "list eq mlist" if ($list eq "skilling-j");
#     warn "list match mlist" if ($list =~ /$mlist/i);
#     warn "";
#     $warn++;
#   }
    # each match gets a +1 weight
    $n++ if (($all   ne "") && (/$all/i));
    $n++ if (($topic ne "") && defined($subject) && ($subject  =~ /$topic/i));
    $n++ if (($mlist ne "") && defined($list)    && ($list     =~ /$mlist/i));
    $n++ if (($email ne "") && defined($source)  && ($source   =~ /$email/i));
    $n++ if (($email ne "") && defined($target)  && ($target   =~ /$email/i));
    print NET "$source\t$target\t$n\n" if $n;
#   warn "$source\t$target\t$n\n" if ($n && $warn++ < 10);
    $edges++;
  }
  close (NET)
      or die "ERROR: $bin: 4. Can't close $net: $!\n";
  return ($edges);
}

sub netword {
  my $mlist = shift;
  my $net   = shift;
  my $tmpdir= shift;
  my $q     = shift;
  my $json  = shift;

  # different files that the main R script needs to know about
  # make a temporary script that sets variables before calling the main R script
  my $rfile = "$tmpdir/$q.R";
  my $cfile = "$tmpdir/$q.communities.txt";
  my $efile = "$tmpdir/$q.edges.txt";
  my $mfile = "$tmpdir/$q.metrics.txt";
  my $vfile = "$tmpdir/$q.vertices.txt";

  open (RFILE, ">$rfile")
    or die "ERROR: $bin: 6. Can't open $rfile: $!\n";
  print RFILE <<EOF2;
rfile <- "$net"    # raw edges file
vfile <- "$vfile"  # vertices file
efile <- "$efile"  # edge file
cfile <- "$cfile"  # community file
mfile <- "$mfile"  # metrics output
jfile <- "$json"   # json output
maillistdir <- "$maillist"
source("R_files/main.R")
EOF2
  close (RFILE)
    or die "ERROR: $bin: 7. Can't close $rfile: $!\n";

# handy for troubleshooting R issues
# system("rsync", "-avP", "$tmpdir", "/tmp/tmp2/");

  my @Rargs = ("R", "-s", "-f", "$rfile");
#  warn(@Rargs);
  system(@Rargs) == 0
    or warn "WARNING: $bin: R didn't complete successfully: $!";
  fixnans($json);
  return ($mfile);
}

# wow. it really takes this much code to do 'sed -i s/foo/bar/g file'?
sub fixnans {
  my $json  = shift;
  open (JFILE, "$json")
    or die "ERROR: $bin: 8. Can't read $json: $!\n";
  my @lines = <JFILE>;
  close (JFILE)
    or die "ERROR: 9. $bin: Can't close $json: $!\n";
  open (JFILE, ">$json")
    or die "ERROR: $bin: 10. Can't write $json: $!\n";
  for (@lines) {
    s/:NaN/:null/g;
    print JFILE;
  }
  close (JFILE)
    or die "ERROR: $bin: 11. Can't close $json: $!\n";
  return;
}

sub showgraph {
  my $json = shift;
  open (FILE, "$d3js") or die "ERROR: $bin: 12. Can't read $d3js: $!\n";
  my @lines = <FILE>;
  for (@lines) {
    s#__JSON_FILE__#$json#;
    print;
  }
  close (FILE) or die "ERROR: $bin: 13. Can't close $d3js: $!\n";
}

# this is completely f'ing retarded
sub json2table {
  my $json = shift;
#  warn "j2t: \$json $json: " . ((-r $json) ? "readable" : "nonsuch");
  local $/;
  my @nodeattribs = qw(
        name
        pr
        evcent
        betweenness_vertex
        closeness_in
        closeness_out
        community
        degree
        graph_strength_in
        graph_strength_out
        isperson
  );
  #     don't display these node attributes
  #     charge
  #     connectivity_vertex
  #     radius

  my @linkattribs = qw(
        source
        target
        weight
  );
  #     don't display these link attributes
  #     width
  #     linkStrength  # these are just "weight" mapped
  #     linkDistance

  # delete the "isperson" column if we don't have any mail-lists to check against
  @nodeattribs = grep {$_ ne 'isperson'} @nodeattribs unless $maillist;

  open (my $fh, "<", "$json") or die "ERROR: $bin: 12. Can't read $json: $!\n";
  my $json_text = <$fh>;
  close ($fh) or die "ERROR: $bin: 13. Can't close $json: $!\n";
  my $ps = decode_json($json_text);
  # if my brain was bigger i'd know an easier way of doing this.
  my %temphash = ();
  for my $foo (@{$ps->{'nodes'}}) {
    my $name = $foo->{'name'};
    $name = uc($name) unless $foo->{'isperson'};
    $temphash{$foo->{'index'}} = $name;
  }
  for my $key (keys %{$ps}) {
    my $attribs = "$include/attributes/$key";
#    if (-d $attribs) {
#      printattribtable ($key, $ps, {},         $attribs) if ($key eq 'nodes');
#      printattribtable ($key, $ps, \%temphash, $attribs) if ($key eq 'links');
#    } else {
      printplaintable  ($key, $ps, {},         @nodeattribs) if ($key eq 'nodes');
      printplaintable  ($key, $ps, \%temphash, @linkattribs) if ($key eq 'links');
#    }
  }
}

sub printattribtable {
#  my ($key, $href, $hash, $attribs) = @_;
#  my $word = $key; 
#  if ($word eq 'nodes') {
#    $word = "People";
#    print mydiv('full');
#  } elsif ($word eq 'links') {
#    print mydiv('left');
#    $word = "Connections";
#  }
#  print '<h2>' . $word . ':</h2>';
#  print '<table cellpadding="0" border="0" style="width:900px" class="display dataTable" id="' . $key . '">' . "\n";
#  print '  <thead>' . "\n";
#  print '    <tr>' . "\n";
#  for my $attr (@attribs) {
#    print '      <th>' . $attr . '</th>' . "\n";
#  }
#  print '    </tr>' . "\n";
#  print '  </thead>' . "\n";
#  print '  <tbody>' . "\n";
#
#
#  for my $foo (@{$href->{$key}}) {
#    print '    <tr>' . "\n";
#    for my $attr (@attribs) {
#      if (($key eq 'links') and ($attr eq 'source' or $attr eq 'target')) {
#        my $name = $$hash{$foo->{$attr}} || $foo->{$attr};
#        print '      <td>' . $name . '</td>' . "\n";
#      } elsif (($key eq 'nodes') and ($attr eq 'isperson')) {
#        print '      <td>' . ($foo->{$attr} ? 'person' : 'list') . '</td>' . "\n";
#      } else {
#        my $tmp = $foo->{$attr};
#        if ($attr eq 'name' and not $foo->{'isperson'}) {
#          $tmp = uc($tmp);
#        } else {
#          $tmp = fmt($tmp);
#        }
#        print '      <td>' . $tmp . '</td>' . "\n";
#      }
#    }
#    print '    </tr>' . "\n";
#  }
#  print '  </tbody>' . "\n";
#  print '</table>' . "\n";
#  print mydiv('close');
  return;
}

sub printplaintable {
  my ($key, $href, $hash, @attribs) = @_;
  my $word = $key; 
  if ($word eq 'nodes') {
    $word = "People";
    print mydiv('full');
  } elsif ($word eq 'links') {
    print mydiv('left');
    $word = "Connections";
  }
  print '<h2>' . $word . ':</h2>';
  print '<table cellpadding="0" border="0" style="width:900px" class="display dataTable" id="' . $key . '">' . "\n";
  print '  <thead>' . "\n";
  print '    <tr>' . "\n";
  for my $attr (@attribs) {
    print '      <th>' . $attr . '</th>' . "\n";
  }
  print '    </tr>' . "\n";
  print '  </thead>' . "\n";
  print '  <tbody>' . "\n";
  for my $foo (@{$href->{$key}}) {
    print '    <tr>' . "\n";
    for my $attr (@attribs) {
      if (($key eq 'links') and ($attr eq 'source' or $attr eq 'target')) {
        my $name = $$hash{$foo->{$attr}} || $foo->{$attr};
        print '      <td>' . $name . '</td>' . "\n";
      } elsif (($key eq 'nodes') and ($attr eq 'isperson')) {
        print '      <td>' . ($foo->{$attr} ? 'person' : 'list') . '</td>' . "\n";
      } else {
        my $tmp = $foo->{$attr};
        if ($attr eq 'name' and not $foo->{'isperson'}) {
          $tmp = uc($tmp);
        } else {
          $tmp = fmt($tmp);
        }
        print '      <td>' . $tmp . '</td>' . "\n";
      }
    }
    print '    </tr>' . "\n";
  }
  print '  </tbody>' . "\n";
  print '</table>' . "\n";
  print mydiv('close');
  return;
}

# the metrics are bit more freeform
sub metrics {
  my $mfile = shift;
  my $n=0;
  print mydiv('right');
  print '<table class="metrics">';
  print '<tr><th colspan="2">Graph Properties</th></tr>';
  unless (open (FILE, $mfile)) {
    warn "WARNING: $bin: Can't read $mfile: $!\n";
    return;
  }
  while (<FILE>) {
    my $class = (++$n%2) ? 'odd' : 'even';
    my ($property, $value) = split ':';
    print '<tr class="'.$class.'"><td class="right">' . $property . '</td><td class="left">' . fmt($value) . '</td></tr>';
  }
  close (FILE)
      or warn "WARNING: $bin: Can't close $mfile: $!\n";
  print '</table>' . "\n" . mydiv('close');
  return;

}

sub fmt {
  my $in = shift;
# thank you mr. ancient perl
#  given( $in ) {
#    when( /^\d+\z/ )      { return $in; }
#    when( /^-?\d+\z/ )    { return $in; }
#    when( /^[+-]?\d+\z/ ) { return $in; }
#    when( /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i || /^-?(?:\d+\.?|\.\d)\d*\z/ ) {
#      return (sprintf "%.3f", $in) if ($in >= 0.01);
#      return (sprintf "%.5f", $in) if ($in >= 0.0001);
#      return (sprintf "%.7f", $in);
#    }
#  }
  if ( $in =~ /^\d+\z/ )      { return $in; }
  if ( $in =~ /^-?\d+\z/ )    { return $in; }
  if ( $in =~ /^[+-]?\d+\z/ ) { return $in; }
  if (($in =~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i)
  or  ($in =~ /^-?(?:\d+\.?|\.\d)\d*\z/ )) {
    return (sprintf "%.3f", $in) if ($in >= 0.01);
    return (sprintf "%.5f", $in) if ($in >= 0.0001);
    return (sprintf "%.7f", $in);
  }
  return ($in);
}

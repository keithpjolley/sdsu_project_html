#!/usr/bin/perl
#!/usr/local/bin/perl5.16.3 -w

# kjolley
# April 01, 2013

# for use on volta.
if (-d qw(/home/student/jolley/perl/lib/perl5/site_perl/5.8.8)) {
  use lib qw(/home/student/jolley/perl/lib/perl5/site_perl/5.8.8)
}
# for use on kjolley-oc.
if (-d qw(/usr/local/lib/perl5/site_perl/5.16.3)) {
  use lib qw(/usr/local/lib/perl5/site_perl/5.16.3)
}

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

# python http server acts differently than apache.
chdir("cgi-bin") if ((-d "cgi-bin") and (basename(getcwd) eq ("public_html")));
my $dir = getcwd;
die "ERROR: $bin: must be invoked from directory 'cgi-bin'. Called from: " . $dir unless (basename($dir) eq "cgi-bin");

# include is inside the cgi-bin directory. it contains all the js and css files
# input is created during pre-processing. it contains, at minimum, the netlist
my $include  = "../include";
my $input    = "../input.enron";
if ($bin eq "tw-qcom.pl") {
   $input    = "../input.qcom";
} elsif ($bin eq "tw-test.pl") {
   $input    = "../input.test"
}

# filesystem paths
my $thelist  = "$input/net.list";  
my $maillist = "$input/mailing-lists";
my $topicpop = "$input/interesting_topic.html";
my $mlistpop = "$input/interesting_list.html";
my $emailpop = "$input/interesting_people.html";
my $d3js     = "$include/js/myD3.js";  
my $jsondir  = "../__cache__/JSON";
my $pngdir   = "../__cache__/PNG";
my $attribdir= "$include/attributes";

# url paths
# note that i put all the js files local. i don't use cdn's because i am on a VERY high latency network at home
# and sometimes code while i have no internet access. feel free to change these to the cdn's if you like.
# jquery    -> <script src="http://code.jquery.com/jquery-1.10.0.min.js"></script>
# DataTable ->
#    <link rel="stylesheet" type="text/css" href="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/css/jquery.dataTables.css">
#    <script type="text/javascript" charset="utf8" src="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/jquery.dataTables.min.js"></script>
# D3        -> <script src="http://d3js.org/d3.v3.min.js" charset="utf-8"></script>
#    
my $inc_url  = url(-base=>1) . dirname (dirname (url(-absolute=>1)));
$inc_url    .= "/" unless (hostname eq 'volta');  # this is really httpd == (apache | python)
$inc_url    .= "include/";

my @css      = (
                $inc_url . "css/style.css",
                $inc_url . "css/dataTables.css",
               );
my @js       = (   # note that changing anything here requires an edit further down.  plus, order of the js files counts.
                $inc_url . "js/jquery-1.10.0.js",
                $inc_url . "js/d3.v3.min.js",
                $inc_url . "js/DataTables-1.9.4/jquery.dataTables.js",
                $inc_url . "js/tinycolor.js",
               );

my $favicon  = $inc_url . "images/favicon.ico";

if (! -d $jsondir) {
  warn "MESSAGE: $bin: creating JSON dir: $jsondir";
  warn "MESSAGE: $bin: cwd: " . getcwd;
  mkdir ($jsondir)
    or die "ERROR: $bin: no JSON dir: $jsondir: $!";
}

if (! -d $pngdir) {
  warn "MESSAGE: $bin: creating PNG dir: $pngdir";
  warn "MESSAGE: $bin: cwd: " . getcwd;
  mkdir ($pngdir)
    or die "ERROR: $bin: no png dir: $pngdir: $!";
}

$maillist = 0 if (! -d $maillist);
$topicpop = 0 if (! -f $topicpop);
$mlistpop = 0 if (! -f $mlistpop);
$emailpop = 0 if (! -f $emailpop);

sub dograph;
sub fixnans;
sub fmt;
sub footer;
sub json2table;
sub metrics;
#sub mychecker;
sub mydiv;
sub netword;
sub printtable;
sub search;
sub showgraph;
sub tooltipper;
sub wanted;

my $tablejs = <<'EOF';
    $(document).ready(function() {
        $('.dataTable').dataTable();
        } );
EOF

my $title = "ENRON";
if ($bin eq "tw-qcom.pl") {
  $title = "QUALCOMM";
} elsif ($bin eq "tw-test.pl") {
  $title = "TEST-DATA";
}

print
  header,
  start_html(
    -title =>$title . ' Community Network',
    -head  => [Link({-rel=>'icon',         -type=>'image/png',-href=>$favicon})],
    -style => {-type=>"text/css", -src=>[@css]},
    -script=> [ 
                { -language=>'javascript', -charset=>"utf-8",  -src=>$js[0]},  # not sure why i can't use @js like @css above.
                { -language=>'javascript', -charset=>"utf-8",  -src=>$js[1]},
                { -language=>'javascript', -charset=>"utf-8",  -src=>$js[2]},
                { -language=>'javascript', -charset=>"utf-8",  -src=>$js[3]},
                { -language=>'javascript', -charset=>"utf-8", -code=>$tablejs},
              ],
  ),
  mydiv('left'),
  start_form,
  table({-id=>"tokens"},
    Tr([
        th([
              "All Fields",
              "Topic",
              ($maillist
                ? ("Mail List", "People (email)")
                : "People (email)"
              ),
           ]),
        td([
            textfield(-name=>'all',   -size=>50),
            textfield(-name=>'topic', -size=>28),
            ($maillist
              ? (textfield(-name=>'mlist', -size=>28), textfield(-name=>'email', -size=>28))
              :  textfield(-name=>'email', -size=>28)
             ),
           ]),
        (
          ($topicpop or $mlistpop or $emailpop)
        ?
          td([
              (submit . "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Suggested queries:"),
              $topicpop ? a({-href=>"$topicpop", -target=>"_blank"}, "topics")          : "(none)",
              ($maillist
                ? (($mlistpop ? a({-href=>"$mlistpop", -target=>"_blank"}, "mail lists")      : "(none)"),
                   ($emailpop ? a({-href=>"$emailpop", -target=>"_blank"}, "email addresses") : "(none)"))
                :  ($emailpop ? a({-href=>"$emailpop", -target=>"_blank"}, "email addresses") : "(none)")
              ),])
        :
          td( {-colspan=>($maillist ? "4" : "3")}, (submit . '&nbsp run "goodword.pl" to enable suggestions')),
        ),
        td( {-colspan=>($maillist ? "4" : "3")},
          ('Using <strong>' . $title . '</strong> data.'), 
#            ('Using <strong>' . $title . '</strong> data. &nbsp;&nbsp;&nbsp; Size by: <form id="radius" class="radius">'), 
#            ('<input type="radio" name="whichradius" id="evc" value="evc" onClick="resize()">Eigenvector Centrality'),
#            ('<input type="radio" name="whichradius" id="pr"  value="pr"  onClick="resize()">PageRank' . '</form>'),
        ),
      ]),
  ),
  end_form,
  mydiv('close');
#  mychecker;

if (param) {
  mydiv('left');
  my ($json, $mfile) = dograph();
  mydiv('close');
  json2table($json);
  metrics($mfile);
  tooltipper;
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
  my $text = "Copyright 2013 Keith P. Jolley";
  $text = $text . ". Content may be QUALCOMM Proprietary" if ($bin eq "tw-qcom.pl");
  $text = '<div id="footer" style="background-color:#003399;clear:both;text-align:center;color:#FFF;">' . $text . '</div>' . "\n";
  return $text;
}

sub dograph {
  # prints the D3 script, returns the location of the $json and $mfile files
  die "ERROR: $bin: 16. no json dir $jsondir" unless -d $jsondir;
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

  my $tmpdir = tempdir(CLEANUP => 1)
    or die "ERROR: $bin: 18. couldn't create tempdir: $!";
  my $net  = "$tmpdir/$qfile.net";
  my $json = "$jsondir/$qfile.json";
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

  open (LIST, "<", $thelist)
      or die "ERROR: $bin: 1. Can't read $thelist: $!\n";
  my @lines = <LIST>;
  close (LIST)
      or die "ERROR: $bin: 2. Can't close $thelist: $!\n";
  open (NET, ">", $net)
      or die "ERROR: $bin: 3. Can't open $net: $!\n";

  for (@lines) {
    my $n = 0;
    my ($source, $target, $list, $subject) = split /\t/;
    $n++ if (($all   ne "") && (/$all/i));
    $n++ if (($topic ne "") && defined($subject) && ($subject  =~ /$topic/i));
    $n++ if (($mlist ne "") && defined($list)    && ($list     =~ /$mlist/i));
    $n++ if (($email ne "") && defined($source)  && ($source   =~ /$email/i));
    $n++ if (($email ne "") && defined($target)  && ($target   =~ /$email/i));
    print NET "$source\t$target\t$n\n" if $n;
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
  my $xfile = "$tmpdir/$q.communitymodularity.txt";

  # use the same name for the png as the json, except w/ png suffix and pngdir
  my $png = $pngdir . "/" . basename($json);
  $png =~ s/json$/png/;

  open (RFILE, ">", $rfile)
    or die "ERROR: $bin: 6. Can't open $rfile: $!\n";
  print RFILE <<EOF2;
rfile <- "$net"    # raw edges file
vfile <- "$vfile"  # vertices file
efile <- "$efile"  # edge file
cfile <- "$cfile"  # community file
mfile <- "$mfile"  # metrics output
jfile <- "$json"   # json output
xfile <- "$xfile"  # community modlularity
afile <- "$attribdir/nodes"; # names of node attributes, links variable names to display names
pfile <- "$png"; # names of node attributes, links variable names to display names
maillistdir <- "$maillist"
source("R_files/main.R")
EOF2
  close (RFILE)
    or die "ERROR: $bin: 7. Can't close $rfile: $!\n";

# handy for troubleshooting R issues
system("rsync", "-avP", "$tmpdir/", "/tmp/tmp2/");

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
  open (JFILE, "<", $json)
    or die "ERROR: $bin: 8. Can't read $json: $!\n";
  my @lines = <JFILE>;
  close (JFILE)
    or die "ERROR: 9. $bin: Can't close $json: $!\n";
  open (JFILE, ">", $json)
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
  open (FILE, "<", $d3js) or die "ERROR: $bin: 12. Can't read $d3js: $!\n";
  my @lines = <FILE>;
  for (@lines) {
    s#__JSON_FILE__#$json#;
    print;
  }
  close (FILE) or die "ERROR: $bin: 13. Can't close $d3js: $!\n";
}

# this is silly
sub json2table {
  my $json = shift;
#  warn "j2t: \$json $json: " . ((-r $json) ? "readable" : "nonsuch");
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
        graph_strength_tot
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
  my $json_text;
  {
    local($/);
    open (my $fh, "<", "$json") or die "ERROR: $bin: 12. Can't read $json: $!\n";
    $json_text = <$fh>;
    close ($fh) or die "ERROR: $bin: 13. Can't close $json: $!\n";
  }
  my $ps = decode_json($json_text);
  # if my brain was bigger i'd know an easier way of doing this.
  my %temphash = ();
  for my $foo (@{$ps->{'nodes'}}) {
    my $name = $foo->{'name'};
    $name = uc($name) unless $foo->{'isperson'};
    $temphash{$foo->{'index'}} = $name;
  }
  for my $key (keys %{$ps}) {
    my $attribfile = "$attribdir/$key";
    if ($key eq 'nodes') {
      printtable  ($key, $ps, {},         $attribfile, @nodeattribs);
    } elsif ($key eq 'links') {
      printtable  ($key, $ps, \%temphash, $attribfile, @linkattribs);
    }
  }
}

sub printtable {
  my ($key, $href, $hash, $attribfile, @attriblist) = @_;
  my $word = $key; 
  my $hashref = (-f $attribfile) ? getattrhash($attribfile) : 0;
  print mydiv('left');
  if ($word eq 'nodes') {
    $word = "People";
  } elsif ($word eq 'links') {
    $word = "Connections";
  }
  print '<h2>' . $word . ':</h2>';
  print '<table cellpadding="0" border="0" style="width:900px" class="display dataTable" id="' . $key . '">' . "\n";
  print '  <thead>' . "\n";
  print '    <tr>' . "\n";
  if ($hashref) { 
    @attriblist = ();
    for my $attr (sort { $hashref->{$a}->{'order'} <=> $hashref->{$b}->{'order'} } keys %$hashref) {
      my $name  = $hashref->{$attr}->{'display_name'};
      my $pop   = $hashref->{$attr}->{'popup_text'};
      push @attriblist, $attr;
      print '      <th><div title="'. $pop . '">' . $name . '</div></th>' . "\n";
    }
  } else {
    for my $attr (@attriblist) {
      print '      <th id="b">' . $attr . '</th>' . "\n";
    }
  }
  print '    </tr>' . "\n";
  print '  </thead>' . "\n";
  print '  <tbody>' . "\n";
  for my $foo (@{$href->{$key}}) {
    print '    <tr>' . "\n";
    for my $attr (@attriblist) {
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
  unless (open (FILE, "<", $mfile)) {
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
  return unless defined($in);
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

sub getattrhash {
  my $attribs =  shift;
  my $hashref;
  my @lines;
  {
    local($\);
    open (FILE, "<", $attribs) or return 0;
    @lines = <FILE>;
    close (FILE) or return 0;
  }
  my $order = 0;
  for (@lines) {
    next if /^#/; # allow comments, but don't mangle descriptions that may have a '#' in them.
    chomp;
    my ($attrib, $key, $value) = split (/;/);
    next unless (defined ($attrib) and defined ($key) and defined ($value));
    $hashref->{$attrib}->{$key} = $value;
    $hashref->{$attrib}->{'order'} = $order++; # eh, so i count by twos, or more. oh well.
  }
  return $hashref;
}

#sub mychecker {
#  my @lines;
#  {
#    local($\);
#    open (FILE, "<", $mychecker) or return;
#    @lines = <FILE>;
#    close (FILE) or return;
#  }
#  return @lines;
#}

# these span id values need to match those in include/js/myD3.js:node.on(mouseover)
sub tooltipper {
  print<<'EOF3';
  <div id="tooltip" class="hidden"><span id="tip">X</span></div>
EOF3
  return;
}

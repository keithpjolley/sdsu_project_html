#
# kjolley
# Thu May 23 17:41:45 PDT 2013
# 
# to git this:  (ssh is my preference. need to import ~/.ssh/id_rsa.pub to github for each new machine though)
#   ssh: 
#     git clone git@github.com:keithpjolley/sdsu_project_html.git
#  http:
#     git clone https://github.com/keithpjolley/sdsu_project_html.git
#
# to commit an edit:
# git commit -am 'comment goes here'
#
# to upload edits to github:
# git push origin master
#
# to sync changes from github to local without doing an 'rm -r'
# git pull
#
#
# presentation here:
# http://www.slideshare.net/keithpjolley/keith-jolley-project-report-final-rev-b
#
#
# if you are running under apache you must do this (and probably should even if you running under python):
cd public_html/cgi-bin/community
make clean all
cd ../..
#
#
# the following commands should run without errors and be in your path:
perl -MCGI -MCwd -MData::Dumper -MDate::Parse -MEmail::Address -MFile::Basename -MFile::Temp -MGetopt::Long -MJSON::PP -MMail::MboxParser -MPod::Usage -MSys::Hostname -Mv5.10 -MSys::Hostname -e 'say "Perl ok";'
#
echo 'library(igraph);library(ggplot2);library(data.table);library(RColorBrewer);print("R ok")' | R --slave --no-save
#
#
# see if you are comfortable with these permissions.
# if you are running the python server then they can be locked down "700".
# if you are running apache then delete "JSON" and make __cache__ "777" and
# run a query. the cgi will create JSON as the web server account. then lock
# down __cache__ to 711.
ls -ld __cache__/JSON
#
#
# run a local CGI server
python -m CGIHTTPServer 8000 &
disown
#
#
echo "now open http://`hostname`:8000/cgi-bin/tw.pl"

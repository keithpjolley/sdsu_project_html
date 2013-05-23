#
# you probably need to:
cd public_html/cgi-bin/community
make clean all
cd ../..
#
#
# see if you are comfortable with these permissions
ls -ld __cache__/JSON
#
#
# run a local CGI server
python -m CGIHTTPServer 8000 &
disown
#
#
echo "now open http://`hostname`:8000/cgi-bin/tw.pl"

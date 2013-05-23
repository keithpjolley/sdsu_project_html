#
# you probably need to:
cd public_html/cgi-bin/community
make clean all
cd ../..
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

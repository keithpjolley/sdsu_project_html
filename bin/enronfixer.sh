#!/bin/sh

# kjolley
# May 7 2013

# after untarring the enron 20110402 tarball in the html directory, run this

export LC_CTYPE=C 
export LANG=C 

bin=`basename "${0}"`
cd "${HOME}/Documents/sdsu/project/html/enron_mail_20110402" || exit 1

if [ -d maildir ]
then
  mv maildir/* .
  rmdir maildir
fi
[ -f "DELETIONS.txt" ] && rm "DELETIONS.txt"
[ -f "net.list"      ] && rm "net.list"

find . -type f -name \*.mbox.noexpand.cache -delete

before=`find . -type f | wc -l`
for dir in *
do
  if [ -d "${dir}" ]
  then
    cd "${dir}"
    pwd
    n=1
    for file in `find . -type f`
    do
      # insert a valid mbox header for perl parsing to work. the enron mail is all sorts of garbaged.
      if head -1 "${file}" | grep -q 'foo@bar.com'
      then
        true # do nothing
      else
        # make 'valid' mbox files.  remove dos ^M's, remove multibyte chars, add header line.
        sed -i'.bak'              \
        -e 's///'               \
        -e 's/[\x80-\xFF]//g'     \
        -e  '1 i\
From foo@bar.com Tue May 7 04:11:29 2013' "${file}"
      fi
      mv "${file}" "${n}.mbox"
      ../../../bin/mailar.parser.pl "${n}.mbox" >> "../net.list"
      let n=n+1
    done
   cd ..
  fi
done


find . -type f -name \*.bak -exec rm {} + > /dev/null 2>&1
find . -type d -depth    -exec rmdir {} + > /dev/null 2>&1  # ignore complaints about non-empty directories

after=`find . -type f -name \*.mbox | wc -l`
echo "number of files before: $before"
echo "number of files  after: $after"

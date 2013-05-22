#!/bin/sh
#
# kjolley
# Sat Apr 27 07:53:44 PDT 2013
#
bin=`basename "${0}"`
tmp=`mktemp -d /tmp/${bin}.tmpdir.XXXXXX` || exit 1
wordlist="${tmp}/wordlist.txt"
searchwords="searchwords"

[ -d "${searchwords}" ] || mkdir "${searchwords}" || exit 2

trap clean 0 1 2 3 6 14 15
clean() {
  [ -d "${tmp}" ] && rm -rf "${tmp}"
}

# words in subject
for list in ./input/*
do
  name=`echo "${list}" | sed -e 's#^./input/##'`
  out="${tmp}/${name}.words.txt"
  echo "INFO: ${bin}: parsing list ${name} for tokens"
  find "${list}" -type f -name \*noexpand.cache                                   \
  | xargs awk -F '\t' '{print $4}'                                                \
  | tr -cs '[:alnum:]' '[\n*]' 2>/dev/null                                        \
  | egrep -v '^(.{1,3}|mail|users|with|your|what|meeting|status|does|from)$'      \
  | sort                                                                          \
  | uniq -c                                                                       \
  | sort -nr                                                                      \
  | sed 's/$/ '"${name}"'/'                                                       \
  | head -20                                                                      \
  > "${tmp}/${name}.words.txt"
done

out="${tmp}/list-words.txt"
echo "INFO: ${bin}: parsing maillist names"
# words in maillist names
find ./input -type f -name \*.mbox                                                \
| sed                                                                             \
  -e 's#^./input/##'                                                              \
  -e 's#/.*##'                                                                    \
  -e 's#[-.]# #'                                                                  \
| tr -cs '[:alnum:]' '\n'                                                         \
| egrep -v '^(.{1,3}|mail|users)$'                                                \
| sort                                                                            \
| uniq -c                                                                         \
| sort -nr                                                                        \
> "${out}"

# find out which words appeared in the most lists - grab a random N from the top
N=100

(find "${tmp}" -type f                                                            \
| xargs awk '{print $2}'                                                          \
| sort                                                                            \
| uniq -c                                                                         \
| sort -nr                                                                        \
| head -20                                                                        \
| awk '{print $2}'                                                                \
;                                                                                 \
find "${tmp}" -name "*.words.txt"                                                 \
| xargs head -5                                                                   \
| grep '^[0-9]'                                                                   \
| awk '{print $2}'                                                                \
)                                                                                 \
| egrep -v '^(200.|does)$'                                                        \
| sed                                                                             \
  -e 's/\(issue\).*/\1/'                                                          \
  -e 's/\(update\).*/\1/'                                                         \
  -e 's/\(recommend\).*/\1/'                                                      \
  -e 's/\(minute\).*/\1/'                                                         \
  -e 's/\(build\).*/\1/'                                                          \
  -e 's/successful/success/'                                                      \
  -e 's/succeeded/success/'                                                       \
| sort                                                                            \
| uniq                                                                            \
| awk 'BEGIN{srand()}{print rand(),$0}'                                           \
| sort -n                                                                         \
| awk "NR<=${N}"'{print $2}'                                                      \
| sort                                                                            \
> "${wordlist}"

###################################################################################
###################################################################################
###################################################################################
###################################################################################
###################################################################################
###################################################################################
###################################################################################
###################################################################################
find "${tmp}" -print0 | xargs -0 cat > /tmp/words
exit
###################################################################################
###################################################################################
###################################################################################
###################################################################################
###################################################################################
###################################################################################
###################################################################################
###################################################################################


# output source, target, weight.  weight=1 if word in subject, 0 otherwise
# use 0.0001 because 0 weight edges causes page.rank to barf-up a little
# edit 3...  too many edges to be useful. have a weight 1 or ignore the edge.
#  | xargs gawk -F '\t' -v OFS='\t' '$4~/\y'"${word}"'\y/{print $1,$2,1;next}{print $1,$2,0}'    \
for word in `cat "${wordlist}"`
do
  echo "INFO: ${bin}: parsing for token: ${word}"
  find input/ -type f -name \*noexpand.cache                                \
  | xargs gawk -F '\t' -v OFS='\t' '$4~/\y'"${word}"'\y/{print $1,$2,1}'    \
  > "${searchwords}/${word}.net"
done

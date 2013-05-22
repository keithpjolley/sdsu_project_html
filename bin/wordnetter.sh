#!/bin/sh
# kjolley

bin=`basename "${0}"`
export PATH="./bin:${PATH}"
tmp=`mktemp -d /tmp/${bin}.tmpdir.XXXXXX` || exit 1

htmldir="./html/words"
JSON="JSON"
rJSON="JSON"
tfile="./html/template.words.html"

trap clean 0 1 2 3 6 14 15
clean() {
  [ -d "${tmp}" ] && rm -rf "${tmp}"
  exit
}

rm -rf "${htmldir}"
[ -d "${htmldir}/${JSON}"  ] || mkdir -p "${htmldir}/${JSON}"  || exit 2
[ -d "${htmldir}/${rJSON}" ] || mkdir -p "${htmldir}/${rJSON}" || exit 3

for net in searchwords/*
do
  word=`echo "${net}" | sed -e 's#.*/\(.*\).net#\1#'`
  echo '##############################################################################################'
  echo '##############################################################################################'
  echo "INFO: ${bin}: ${net} ${word}"
  echo '##############################################################################################'
  echo '##############################################################################################'

  # different files that the main R script needs to know about
  # make a temporary script that sets variables before calling the main R script
  Rin="${tmp}/${word}.script.R"
  rfile="${net}"
  cfile="${tmp}/${word}.communities.txt"
  vfile="${tmp}/${word}.vertices.txt"
  efile="${tmp}/${word}.edges.txt"
  mfile="${tmp}/${word}.metrics.txt"
  jfile="${JSON}/${word}.json"
  jrfile="${rJSON}/${word}.rand.json"
  hfile="${htmldir}/${word}.html"

  echo "${bin}: creating tmp files."
  cat<<EOF >"${Rin}"
    rfile <- "${rfile}" # raw edges file
    vfile <- "${vfile}" # vertices file
    efile <- "${efile}" # edge file
    cfile <- "${cfile}" # community file
    jfile <- "${htmldir}/${jfile}" # local json output
    mfile <- "${mfile}"
    token <- "${word}"
    source("R_files/main.R")
EOF
  echo "${bin}: Running R on ${Rin}."
  R -s -f "${Rin}"
  sed -i "" 's/:NaN/:null/g' "${htmldir}/${jfile}" # because R and json /really/ disagree on this subject
  randomize_names "${htmldir}/${jfile}" > "${htmldir}/${jrfile}"
  sed -e "s#__JSON_FILE__#${jfile}#"       \
      -e "/__METRICS_FILE__/r ${mfile}"    \
      -e "/__METRICS_FILE__/d"             \
      -e "s/__TITLE__/token: ${word}/"     \
      <  "${tfile}"                        \
      >  "${hfile}"
  echo ''
done

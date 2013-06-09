#!/bin/sh
#
# kjolley
# Sun Apr 13 02:44:16 PDT 2013
#
# all the 2>/dev/null because these programs send their verbiosity to stderr.  :/
#
bin=`basename "${0}"`
cd `dirname "${0}"`

nodes="$1"
edges="$2"
output="$3"
xfile="$4"

verbose=0

tmp=`mktemp -d "/tmp/${bin}.XXXXXXX"`

graph_txt="${tmp}/graph.txt"
graph_bin="${tmp}/graph.bin"
graph_weights="${tmp}/graph_weights.txt"
graph_tree="${tmp}/graph_tree.txt"
mapped="${tmp}/mapped.txt"
map_data="${tmp}/map_data.txt"
mod_data="${tmp}/modularity.txt"

function clean () {
  [ "${verbose}" -gt 1 ] && echo "cleaning tmp files"
  [ -d "${tmp}" ] && rm -rf "${tmp}"
}

trap clean 0 1 2 6 15

[ "${verbose}" -gt 0 ] && echo "${bin}: making sure i have the right binaries"
[ -x ./convert ] || make 

[ "${verbose}" -gt 0 ] && echo "${bin}: remaping source/targets to numbers"
./map.pl --direction=forward --map="${nodes}" --input="${edges}" > "${mapped}" 2>/dev/null

if [ "${verbose}" -gt 2 ]
then
  echo "${bin}: mapping example"
  nl "${mapped}" | head -3
  echo "..."
  nl "${mapped}" | tail -3
fi

[ "${verbose}" -gt 0 ] && echo "${bin}: converting from ascii to bin"
./convert -i "${mapped}" -o "${graph_bin}" -w "${graph_weights}" > /dev/null 2>&1
[ "${verbose}" -gt 0 ] && echo "${bin}: finding communities"
./community "${graph_bin}" -l -1 -v -q 0.00125 -w "${graph_weights}" > "${graph_tree}" 2> "${mod_data}"  # really?!
stat=$?
[ "${verbose}" -gt 0 ] && echo "${bin}: finding hierarchies"
iteration=`./hierarchy "${graph_tree}" | awk '/^Number of levels: /{print $NF-1}'`
[ "${verbose}" -gt 0 ] && echo "${bin}: extracting iteration ${iteration}"
./hierarchy "${graph_tree}" -l "${iteration}" > "${graph_tree}.iteration.${iteration}"  2>/dev/null
[ "${verbose}" -gt 0 ] && echo "${bin}: remapping ${iteration} back to orginal node ids"
./map.pl --direction=reverse --map="${nodes}" --input="${graph_tree}.iteration.${iteration}" > "${output}" 2>/dev/null

# well, this is kinda hackish
modularity="ERROR"
[ $stat -eq 0 ] &&  modularity=`tail -1 "${mod_data}" | awk 'NF!=1{print "ERROR";exit}//'`
echo "modularity=${modularity}" > "${xfile}"

echo "\$mod_data: $mod_data"  1>&2
cat "${mod_data}" 1>&2
echo "\$xfile: $xfile:"  1>&2
cat "${xfile}" 1>&2

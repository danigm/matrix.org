#!/bin/bash -eux

# update_docs.sh: regenerates the autogenerated files on the matrix.org site.
# At present this includes:
#   * the spec index, intro and appendices
#   * the guides and howtos
#
# It does *not* include the client-server API, which is generated by
# other scripts in this directory and then *committed to git*.

# Note that this file is world-readable unless someone plays some .htaccess hijinks

echo >&2 "Make sure you have run \`git submodule update --remote\` to pull in the latest changes."

SELF="${BASH_SOURCE[0]}"
if [[ "${SELF}" != /* ]]; then
  SELF="$(pwd)/${SELF}"
fi
SELF="${SELF/\/.\///}"
cd "$(dirname "$(dirname "${SELF}")")"

SITE_BASE="$(pwd)"
INCLUDES="${SITE_BASE}/includes/from_jekyll"

# figure out the most recent version of the C-S API
CS_VER=$(perl -ne 'if(/topic-title.*Version: (r\d+\.\d+.\d+)/) {print "$1\n"}' \
            docs/spec/client_server/latest.html)

if [ -z "$CS_VER" ]; then
    echo >&2 "Unable to find version number in client-server spec"
    exit 1
fi


# update the spec, except for the C-S API
SCRIPTS_DIR='./matrix-doc/scripts'
GENDOC="$SCRIPTS_DIR/gendoc.py"
TARGETS=$($GENDOC --list_targets | grep -v 'client_server')

rm -r "$SCRIPTS_DIR/gen"
$GENDOC -c $CS_VER $(for t in $TARGETS; do echo -t $t; done)
find "$SCRIPTS_DIR/gen" -name '*.html' |
    xargs "$SCRIPTS_DIR/add-matrix-org-stylings.pl" "${INCLUDES}"

# move the generated docs into docs/
#mkdir -p docs/howtos
#mv "$SCRIPTS_DIR/gen/howtos.html" docs/howtos/client-server.html
#cp -r "$SCRIPTS_DIR"/gen/* docs/spec


# now update other bits of the site
./jekyll/generate.sh

echo "generating olm specs"
rst2html.py olm/docs/olm.rst > docs/spec/olm.html
rst2html.py olm/docs/megolm.rst > docs/spec/megolm.html

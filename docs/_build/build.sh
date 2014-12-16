#!/bin/bash
#
# this generates the site in _site
# override --url /myMountPoint  (as an argument to this script) if you don't like the default set in /_config.yml

if [ ! -x _build/build.sh ] ; then
  echo script must be run in root of docs dir
  exit 1
fi

function help() {
  echo "This will build the documentation in _site/."
  echo "Usage:  _build/build.sh MODE [ARGS]"
  echo "where MODE is:"
  echo "* guide-root : to build the guide in the root"
  echo "* guide-version : to build the guide in the versioned namespace /v/VERSION/"
  echo "* default : to build the files in their natural location (e.g. guide in /guide/)"
  echo "and supported ARGS are:"
  echo "* --skip-javadoc : to skip javadoc build"
  echo 'with any remaining ARGS passed to jekyll as `jekyll build --config ... ARGS`.'
}

function deduce_config() {
  DIRS_TO_MOVE=( )
  case $1 in
  help)
    help
    exit 0 ;;
  guide-root)
    CONFIG=_config.yml,_build/config-production.yml,_build/config-guide-root.yml
    DIRS_TO_MOVE["guide"]=""
    SUMMARY="user guide files in the root"
    ;;
  guide-version)
    CONFIG=_config.yml,_build/config-production.yml,_build/config-guide-version.yml
    # Mac bash defaults to v3 not v4, so can't use assoc arrays :(
    DIRS_TO_MOVE[0]=guide
    # BROOKLYN_VERSION_BELOW
    DIRS_TO_MOVE_TARGET[0]=v/0.7.0-SNAPSHOT
    DIRS_TO_MOVE[1]=style
    DIRS_TO_MOVE_TARGET[1]=${DIRS_TO_MOVE_TARGET[0]}/style
    SUMMARY="user guide files in /${DIRS_TO_MOVE_TARGET[0]}"
    ;;
  default)
    CONFIG=_config.yml,_build/config-production.yml
    SUMMARY="all files in their default place"
    ;;
  "")
    echo "Arguments are required. Try 'help'."
    exit 1 ;;
  *)
    echo "Invalid argument '$1'. Try 'help'."
    exit 1 ;;
  esac
}

function build_jekyll() {
  echo JEKYLL running with: jekyll build $CONFIG $@
  jekyll build --config $CONFIG $@ || return 1
  echo JEKYLL completed
  for DI in "${!DIRS_TO_MOVE[@]}"; do
    D=${DIRS_TO_MOVE[$DI]}
    DT=${DIRS_TO_MOVE_TARGET[$DI]}
    echo moving _site/$D/ to _site/$DT
    mkdir -p _site/$DT
    # the generated files are already in _site/ due to url rewrites along the way, but images etc are not
    cp -r _site/$D/* _site/$DT
    rm -rf _site/$D
  done
  rm -rf _site/long_grass
}

rm -rf _site

deduce_config $@
shift

if [ "$1" = "--skip-javadoc" ]; then
  SKIP_JAVADOC=true
  shift
fi

build_jekyll || { echo ERROR: could not build docs in `pwd` ; exit 1 ; }

if [ "$SKIP_JAVADOC" != "true" ]; then
  pushd _build > /dev/null
  ./make-javadoc.sh || { echo ERROR: failed javadoc build ; exit 1 ; }
  popd > /dev/null
fi

# TODO build catalog

echo FINISHED: $SUMMARY of `pwd`/_site 
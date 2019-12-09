#!/usr/bin/env bash
function usage_exit() {
  echo "Usage: $0 [OPTIONS] <version1> [<version2> [...]]"
  echo
  echo "Options:"
  echo "  -h, --help"
  echo "  --parallel num (default: CPU physical core number)"
  echo "  --install-root-path path (default: \$HOME/src/local/php"
  echo "  --override"
  echo "  --show-versions"
  echo
  exit 1
}

# option defalut
PARALLEL=$(sysctl -n hw.physicalcpu_max)
INSTALL_ROOT_PATH="$HOME/local/php"
OVERRIDE=false
SHOW_VERSIONS=false

param=()
for OPT in "$@"
do
  case $OPT in
    -h | --help)
      usage_exit
      exit 1
      ;;
    --parallel)
      PARALLEL=$2
      shift 2
      ;;
    --install-root-path)
      INSTALL_ROOT_PATH=$2
      shift 2
      ;;
    --override)
      OVERRIDE=true
      shift 1
      ;;
    --show-versions)
      SHOW_VERSIONS=true
      shift 1
      ;;
    *)
      if [[ -n "$1" ]] && [[ ! "$1" =~ ^-+ ]]; then
        param+=( "$1" )
        shift 1
      fi
      ;;
  esac
done

if [ -p /dev/stdin ]; then
  IFS=$'\n'
  for line in $(cat -)
  do
    param+=( "$line" )
  done
fi

BUILD_VERSIONS=()
SKIP_VERSIONS=()
if [ $OVERRIDE = true ]; then
  BUILD_VERSIONS=$param
else
  for VERSION in "${param[@]}" ; do
    if [ -e "$INSTALL_ROOT_PATH/$VERSION/bin/php" ]; then
      SKIP_VERSIONS+=($VERSION)
    else
      BUILD_VERSIONS+=($VERSION)
    fi
  done
fi
echo "skip versions:"
echo "${SKIP_VERSIONS[@]}"
echo "build versions:"
echo "${BUILD_VERSIONS[@]}"

if [ $SHOW_VERSIONS = true ]; then
  exit 0
fi

export PHP_BUILD_CONFIGURE_OPTS="--with-zlib-dir=$(brew --prefix zlib) --with-bz2=$(brew --prefix bzip2) --with-iconv=$(brew --prefix libiconv) --with-libedit=$(brew --prefix libedit) --with-openssl=$(brew --prefix openssl) --with-libxml-dir=$(brew --prefix libxml2) --with-curl=$(brew --prefix curl) --without-tidy"
export YACC="$(brew --prefix bison)/bin/bison"
export "PHP_BUILD_EXTRA_MAKE_ARGUMENTS=-j$PARALLEL"
echo "${BUILD_VERSIONS[@]}" | xargs -n1 -t -I@ php-build -i development @ "$INSTALL_ROOT_PATH"/@/

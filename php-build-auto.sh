#!/usr/bin/env bash
function usage_exit() {
  echo "Usage: $0 [OPTIONS]"
  echo
  echo "Options:"
  echo "  -h, --help"
  echo "  --filter stable|minor-head (default: minor-head)"
  echo "  --oldest-version ver (default: 7.0.0)"
  echo "  --definition-path path (default: \$HOME/src/github.com/php-build/php-build/share/php-build/definitions/"
  echo "  --parallel num (default: CPU physical core number)"
  echo "  --install-root-path path (default: \$HOME/src/local/php"
  echo "  --override"
  echo "  --show-versions"
  echo
  exit 1
}

# option defalut
FILTER="minor-head"
OLDEST_VERSION="7.0.0"
PARALLEL=$(sysctl -n hw.physicalcpu_max)
DEFINITION_PATH="$HOME/src/github.com/php-build/php-build/share/php-build/definitions/"
INSTALL_ROOT_PATH="$HOME/local/php"
OVERRIDE=false
SHOW_VERSIONS=false

for OPT in "$@"
do
  case $OPT in
    -h | --help)
      usage_exit
      exit 1
      ;;
    --filter)
      FILTER=$2
      shift 2
      ;;
    --oldest-version)
      OLDEST_VERSION=$2
      shift 2
      ;;
    --parallel)
      PARALLEL=$2
      shift 2
      ;;
    --definition-path)
      DEFINITION_PATH=$2
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

VERSIONS=$(php ./listversion.php --filter "$FILTER" --oldest-version "$OLDEST_VERSION" --definition-path "$DEFINITION_PATH")
BUILD_VERSIONS=()

if [ $OVERRIDE = true ]; then
  BUILD_VERSIONS=$VERSIONS
else
  for VERSION in $VERSIONS ; do
    if [ -e "$INSTALL_ROOT_PATH/$VERSION/bin/php" ]; then
      echo "skip: $VERSION"
    else
      BUILD_VERSIONS+=($VERSION)
    fi
  done
fi

echo "build versions:"
echo "${BUILD_VERSIONS[@]}"

if [ $SHOW_VERSIONS = true ]; then
  exit 0
fi

export PHP_BUILD_CONFIGURE_OPTS="--with-zlib-dir=$(brew --prefix zlib) --with-bz2=$(brew --prefix bzip2) --with-iconv=$(brew --prefix libiconv) --with-libedit=$(brew --prefix libedit) --with-openssl=$(brew --prefix openssl) --with-libxml-dir=$(brew --prefix libxml2) --with-curl=$(brew --prefix curl) --without-tidy"
export YACC="$(brew --prefix bison@2.7)/bin/bison"
export PHP_BUILD_EXTRA_MAKE_ARGUMENTS=-j2
echo "${BUILD_VERSIONS[@]}" | xargs -n1 -t -P "$PARALLEL" -IVER php-build -i development VER "$INSTALL_ROOT_PATH"/VER/

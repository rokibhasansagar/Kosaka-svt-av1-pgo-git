#!/hint/bash
# Maintainer : Kosaka <kosaka@noreply.codeberg.org>
# Contributor: Maxime Gauduin <alucryd@archlinux.org>
# Contributor: Daniel Bermond <dbermond@archlinux.org>
# Contributor: Thomas Schneider <maxmusterm@gmail.com>
# shellcheck disable=SC2034,SC2154

pkgname=svt-av1-psy-pgo
#official svt-av1 version
pkgver=v1.9.0.rc1.r0.ge0b96d4
_pkgver=1.9.0
pkgrel=1
pkgdesc='Scalable Video Technology AV1 encoder and decoder'
arch=(x86_64)
url='https://github.com/gianni-rosato/svt-av1-psy'
provides=('svt-av1')
license=(
  BSD
  'custom: Alliance for Open Media Patent License 1.0'
)
depends=(glibc)
makedepends=(
  cmake
  git
  nasm
  ninja
  llvm
  llvm-bolt
  clang
  libdovi
  av1an
)
source=('git+https://github.com/gianni-rosato/svt-av1-psy'
        'encode.sh')
b2sums=('SKIP'
        'SKIP')
_where="$PWD"
_repo="svt-av1-psy"

#*OPTIONS
#Enable Bolting of SVT-AV1 for slightly better performance. Requires LLVM built with Bolt enabled to be in $PATH
#E.g the programs "llvm-bolt", and "merge-fdata" along with their required libraries.
BOLT=true

#Automatic input video download/usage. Only one can be used at a time.
#Downloads Xiph's test video archives which contain many small clips used to PGO optimisation. If disabled, you have to provide *all* of the input videos yourself.
#However, you can still provide your own videos if you use one of these options.
#The options are:
#  - objective-1-fast: roughly 3.5 gigabytes uncompressed. Recommended to use this if you don't want to provide your own.
#  - objective-1: roughly 26-27 gigabytes uncompressed.
#  - objective-2-fast: roughly 4.5 gigabytes uncompressed.
#  - objective-2-slow: roughly 21 gigabytes uncompressed.
#  - objective-3-fast: merge of objective-1-fast & objective-2-fast with low-res videos removed
#  - none: No video will be downloaded. You have to provide your own.
DOWNLOAD_OBJECTIVE_TYPE="objective-3-fast"

#*END OF OPTIONS

if test "$BOLT" == "true"; then
  pkgname="$pkgname-bolt-git"
  #Bolted binaries cannot be stripped (yet).
  options=('!strip')
else
  pkgname="$pkgname-git"
fi

#Add the selected tar file to the source array.

if test "$DOWNLOAD_OBJECTIVE_TYPE" == "objective-3-fast"; then
  source+=("https://media.xiph.org/video/derf/objective-1-fast.tar.gz")
  b2sums+=('SKIP')
  source+=("https://media.xiph.org/video/derf/objective-2-fast.tar.gz")
  b2sums+=('SKIP')
else
  if test "$DOWNLOAD_OBJECTIVE_TYPE" != "objective-3-fast" && "$DOWNLOAD_OBJECTIVE_TYPE" != "none"; then
    source+=("https://media.xiph.org/video/derf/${DOWNLOAD_OBJECTIVE_TYPE}.tar.gz")
    b2sums+=('SKIP')
  fi
fi

#Colourful colours
if ! test "$NO_COLOR"; then
  red="\e[1;31m"
  nc="\e[0m"
fi

prepare() {
  #Check for llvm-bolt if the user is Bolting.
  if test "$BOLT" == "true"; then
    if ! test "$(command -v "llvm-bolt")" ; then
      echo -e "${red}[ERROR] llvm-bolt is not installed! Please install and add it to your \$PATH before running this PKGBUILD${nc}"
      exit 1
    fi

    #Create the svt-bolt-data folder if missing.
    if ! test -d "${srcdir}"/svt-bolt-data; then
      mkdir "${srcdir}"/svt-bolt-data
    fi
  fi

  #Check for the video-input folder.
  if test -d "$_where"/video-input; then
    #Symlink the video-input folder into the srcdir
    if ! test -d "${srcdir}"/video_input; then
      ln -s "$_where"/video-input "${srcdir}"/video-input
    fi
  fi
}


pkgver() {
  cd "$_repo" || { echo "pkgver error"; exit 1; }
  git describe --long --tags --abbrev=7 | sed 's/\([^-]*-g\)/r\1/;s/-/./g'
}

build() {
  export LDFLAGS="$LDFLAGS -Wl,-z,noexecstack"
  #PGO requires using Clang.
  export CC=clang
  export CXX=clang++

  #Build SVT-AV1 to generate our PGO data.
  cmake -S "$_repo" -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DBUILD_SHARED_LIBS=ON \
    -DSVT_AV1_PGO=ON \
    -DSVT_AV1_PGO_DIR="${srcdir}"/svt-pgo-data \
    -DCMAKE_BUILD_TYPE=Release \
    -DSVT_AV1_LTO=ON \
    -DNATIVE=OFF
  ninja PGOCompileGen -C build

  #Generate our pgo data by encoding a video
  #Ideally we'd just run ffmpeg here but due to the 'uniqueness' of video encoding it is (probably?)
  #best if the user supplies their own encoding parameters in a script called 'encode.sh'.
  #This part most likely makes this PKGBUILD not allowed on the AUR.
  DOWNLOAD_OBJECTIVE_TYPE="$DOWNLOAD_OBJECTIVE_TYPE" _repo="$_repo" ./encode.sh

  #remove .ivf and .av1an files as we do not need them.
  rm "${srcdir}"/video-input/*.av1an

  #Merge the generated data into something useable.
  llvm-profdata merge "${srcdir}/svt-pgo-data"/*.profraw-real --output "${srcdir}"/svt-pgo-data/default.profdata

  if test "$BOLT" == "true"; then
    #Compile SVT-AV1 using our new PGO data.
    ninja PGOCompileUse -C build

    #Use Bolt on SVT-AV1 to generate profile data. This is different from PGO and of course more confusing.
    mv "$PWD/$_repo/Bin/Release/SvtAv1EncApp" "$PWD/$_repo/Bin/Release/non-bolt-SvtAv1EncApp"
    llvm-bolt "$PWD/$_repo/Bin/Release/non-bolt-SvtAv1EncApp" -instrument --instrumentation-file-append-pid --instrumentation-file="${srcdir}"/svt-bolt-data/svt-data.fdata -o "$PWD/$_repo/Bin/Release/SvtAv1EncApp"

    #Do more encoding to generate Bolt data
    BOLT="$BOLT" _repo="$_repo" ./encode.sh

    #remove .av1an files as we do not need them.
    if test -d "${srcdir}"/video-input; then
      rm "${srcdir}"/video-input/*.av1an
    elif test -d "${srcdir}/objective-*"; then
      rm "${srcdir}"/objective-*/*.av1an
    fi

    #compile all of our fdata files into one
    merge-fdata "${srcdir}/svt-bolt-data"/*.fdata-real > "${srcdir}/svt-bolt-data/final.fdata"

    #Finally Bolt on our generated data to the SVT binary using llvm-bolt.
    mv "$PWD/$_repo/Bin/Release/SvtAv1EncApp" "$PWD/$_repo/Bin/Release/pre-bolt-SvtAv1EncApp"
    llvm-bolt "$PWD/$_repo/Bin/Release/non-bolt-SvtAv1EncApp" -o "$PWD/$_repo/Bin/Release/SvtAv1EncApp" -data="${srcdir}/svt-bolt-data/final.fdata" -icf -icp-eliminate-loads -indirect-call-promotion=all -jump-tables=basic -align-macro-fusion=hot -dyno-stats -plt=hot -split-functions -split-all-cold -split-eh -reorder-blocks=ext-tsp
  fi
}

package() {
  if test "$BOLT" == "true"; then
    DESTDIR="${pkgdir}" cmake --install build
  else
    DESTDIR="${pkgdir}" ninja -C build install
  fi
  install -Dm 644 "$_repo"/{LICENSE,PATENTS}.md -t "${pkgdir}"/usr/share/licenses/svt-av1/
}

# vim: ts=2 sw=2 et:

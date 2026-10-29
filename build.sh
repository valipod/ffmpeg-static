#!/bin/sh

set -e
set -u

jflag=
jval=2
rebuild=0
download_only=0
uname -mpi | grep -qE 'x86|i386|i686' && is_x86=1 || is_x86=0

while getopts 'j:Bd' OPTION
do
  case $OPTION in
  j)
      jflag=1
      jval="$OPTARG"
      ;;
  B)
      rebuild=1
      ;;
  d)
      download_only=1
      ;;
  ?)
      printf "Usage: %s: [-j concurrency_level] (hint: your cores + 20%%) [-B] [-d]\n" $(basename $0) >&2
      exit 2
      ;;
  esac
done
shift $(($OPTIND - 1))

if [ "$jflag" ]
then
  if [ "$jval" ]
  then
    printf "Option -j specified (%d)\n" $jval
  fi
fi

[ "$rebuild" -eq 1 ] && echo "Reconfiguring existing packages..."
[ $is_x86 -ne 1 ] && echo "Not using yasm or nasm on non-x86 platform..."

cd `dirname $0`
ENV_ROOT=`pwd`
. ./env.source

# check operating system
OS=`uname`
platform="unknown"

case $OS in
  'Darwin')
    platform='darwin'
    ;;
  'Linux')
    platform='linux'
    ;;
esac

#if you want a rebuild
#rm -rf "$BUILD_DIR" "$TARGET_DIR"
mkdir -p "$BUILD_DIR" "$TARGET_DIR" "$DOWNLOAD_DIR" "$BIN_DIR"

#download and extract package
download(){
  filename="$1"
  if [ ! -z "$2" ];then
    filename="$2"
  fi
  ../download.pl "$DOWNLOAD_DIR" "$1" "$filename" "$3" "$4"
  #disable uncompress
  REPLACE="$rebuild" CACHE_DIR="$DOWNLOAD_DIR" ../fetchurl "http://cache/$filename"
}

echo "#### FFmpeg static build ####"

#this is our working directory
cd $BUILD_DIR

[ $is_x86 -eq 1 ] && download \
  "yasm-1.3.0.tar.gz" \
  "" \
  "fc9e586751ff789b34b1f21d572d96af" \
  "http://www.tortall.net/projects/yasm/releases/"

[ $is_x86 -eq 1 ] && download \
  "nasm-2.16.03.tar.bz2" \
  "" \
  "nil" \
  "https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/"

download \
  "openssl-3.6.5.tar.gz" \
  "" \
  "e1df3c3fea55e3dc8bcb6b422f436fbc" \
  "https://github.com/openssl/openssl/releases/download/openssl-3.6.5/"

download \
  "v1.3.2.tar.gz" \
  "zlib-1.3.2.tar.gz" \
  "d092e353ab96ab0d43384638f8ea0b41" \
  "https://github.com/madler/zlib/archive/"

download \
  "v1.5.7.tar.gz" \
  "" \
  "3ccc21ed2ed26fcfe6496b8c281137ac" \
  "https://github.com/Haivision/srt/archive/refs/tags/"

git -C x264 pull 2> /dev/null || git clone --depth 1 https://code.videolan.org/videolan/x264.git

rm -rf x265_git && git clone --depth 1 --branch 4.2 https://bitbucket.org/multicoreware/x265_git.git
git -C fdk-aac pull 2> /dev/null || git clone --depth 1 https://github.com/mstorsjo/fdk-aac

# libass dependency
download \
  "harfbuzz-15.0.0.tar.xz" \
  "" \
  "e489b638efdf8b1eb499030bbc7a394d" \
  "https://github.com/harfbuzz/harfbuzz/releases/download/15.0.0/"

download \
  "fribidi-1.0.17.tar.xz" \
  "" \
  "f86bb656ecfdee321b93a059734fc106" \
  "https://github.com/fribidi/fribidi/releases/download/v1.0.17/"

download \
  "0.17.5.tar.gz" \
  "libass-0.17.5.tar.gz" \
  "nil" \
  "https://github.com/libass/libass/archive/"

download \
  "lame-3.100.tar.gz" \
  "" \
  "nil" \
  "http://downloads.sourceforge.net/project/lame/lame/3.00"

download \
  "opus-1.6.1.tar.gz" \
  "" \
  "67cafc438c430aa74eeb605eef670886" \
  "https://downloads.xiph.org/releases/opus"

download \
  "v1.17.0.tar.gz" \
  "vpx-1.17.0.tar.gz" \
  "nil" \
  "https://github.com/webmproject/libvpx/archive"

rm -rf rtmpdump && mkdir rtmpdump && git -C rtmpdump init -q && \
  git -C rtmpdump fetch -q --depth 1 https://git.ffmpeg.org/rtmpdump.git 138fdb258d9fc26f1843fd1b891180416c9dc575 && \
  git -C rtmpdump checkout -q FETCH_HEAD

download \
  "soxr-0.1.2-Source.tar.xz" \
  "" \
  "0866fc4320e26f47152798ac000de1c0" \
  "https://sourceforge.net/projects/soxr/files/"

download \
  "v1.1.2.tar.gz" \
  "vid.stab-1.1.2.tar.gz" \
  "a91ff0221dd8ec1f85b2a80a07af4831" \
  "https://github.com/georgmartius/vid.stab/archive/"

download \
  "release-3.0.6.tar.gz" \
  "zimg-release-3.0.6.tar.gz" \
  "nil" \
  "https://github.com/sekrit-twc/zimg/archive/refs/tags/"

download \
  "v2.5.4.tar.gz" \
  "openjpeg-2.5.4.tar.gz" \
  "nil" \
  "https://github.com/uclouvain/openjpeg/archive/"
  
download \
  "v1.6.0.tar.gz" \
  "libwebp-1.6.0.tar.gz" \
  "d498caf9323a24ce3ed40b84c22a32cd" \
  "https://github.com/webmproject/libwebp/archive/"

download \
  "v1.3.7.tar.gz" \
  "vorbis-1.3.7.tar.gz" \
  "689dc495b22c5f08246c00dab35f1dc7" \
  "https://github.com/xiph/vorbis/archive/"

download \
  "v1.3.6.tar.gz" \
  "ogg-1.3.6.tar.gz" \
  "049c22ed9a2e2f9757b32cc47b6b4a48" \
  "https://github.com/xiph/ogg/archive/"

download \
  "Speex-1.2.1.tar.gz" \
  "Speex-1.2.1.tar.gz" \
  "2872f3c3bf867dbb0b63d06762f4b493" \
  "https://github.com/xiph/speex/archive/"

#download \
#  "n6.0.tar.gz" \
#  "ffmpeg6.0.tar.gz" \
#  "586ca7cc091d26fd0a4c26308950ca51" \
#  "https://github.com/FFmpeg/FFmpeg/archive"

wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
    tar xjvf ffmpeg-snapshot.tar.bz2

download \
  "SDL2-2.32.10.tar.gz" \
  "SDL2-2.32.10.tar.gz" \
  "7b234751c91737168d88c83041ca5aa9" \
  "https://github.com/libsdl-org/SDL/releases/download/release-2.32.10"

[ $download_only -eq 1 ] && exit 0

TARGET_DIR_SED=$(echo $TARGET_DIR | awk '{gsub(/\//, "\\/"); print}')

if [ $is_x86 -eq 1 ]; then
    echo "*** Building yasm ***"
    cd $BUILD_DIR/yasm*
    [ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
    [ ! -f config.status ] && ./configure --prefix=$TARGET_DIR --bindir=$BIN_DIR
    make -j $jval
    make install
fi

if [ $is_x86 -eq 1 ]; then
    echo "*** Building nasm ***"
    cd $BUILD_DIR/nasm*
    [ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
    [ ! -f config.status ] && ./configure --prefix=$TARGET_DIR --bindir=$BIN_DIR
    make -j $jval
    make install
fi

echo "*** Building OpenSSL ***"
cd $BUILD_DIR/openssl*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
if [ "$platform" = "darwin" ]; then
  PATH="$BIN_DIR:$PATH" ./Configure darwin64-x86_64-cc --prefix=$TARGET_DIR --libdir=lib
elif [ "$platform" = "linux" ]; then
  PATH="$BIN_DIR:$PATH" ./config --prefix=$TARGET_DIR --libdir=lib --openssldir=/etc/ssl
fi
PATH="$BIN_DIR:$PATH" make -j $jval
make install_sw

echo "*** Building zlib ***"
cd $BUILD_DIR/zlib*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
if [ "$platform" = "linux" ]; then
  [ ! -f config.status ] && PATH="$BIN_DIR:$PATH" ./configure --prefix=$TARGET_DIR
elif [ "$platform" = "darwin" ]; then
  [ ! -f config.status ] && PATH="$BIN_DIR:$PATH" ./configure --prefix=$TARGET_DIR
fi
PATH="$BIN_DIR:$PATH" make -j $jval
make install

echo "*** Building x264 ***"
cd $BUILD_DIR/x264*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
[ ! -f config.status ] && PATH="$BIN_DIR:$PATH" ./configure --prefix=$TARGET_DIR --enable-static --disable-shared --disable-opencl --enable-pic
PATH="$BIN_DIR:$PATH" make -j $jval
make install

echo "*** Building x265 ***"
cd $BUILD_DIR/x265_git
cd build/linux
[ $rebuild -eq 1 ] && find . -mindepth 1 ! -name 'make-Makefiles.bash' -and ! -name 'multilib.sh' -exec rm -r {} +
PATH="$BIN_DIR:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$TARGET_DIR" -DENABLE_SHARED:BOOL=OFF -DSTATIC_LINK_CRT:BOOL=ON -DENABLE_CLI:BOOL=OFF ../../source
sed -i 's/-lgcc_s/-lgcc_eh/g' x265.pc
make -j $jval
make install

echo "*** Building fdk-aac ***"
cd $BUILD_DIR/fdk-aac*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
autoreconf -fiv
[ ! -f config.status ] && ./configure --prefix=$TARGET_DIR --disable-shared
make -j $jval
make install

echo "*** Building harfbuzz ***"
cd $BUILD_DIR/harfbuzz-*
rm -rf build
PATH="$BIN_DIR:$PATH" meson setup build --default-library=static --prefix=$TARGET_DIR --libdir=lib -Dtests=disabled -Ddocs=disabled -Dglib=disabled -Dgobject=disabled -Dcairo=disabled -Dchafa=disabled -Dicu=disabled -Dintrospection=disabled -Dutilities=disabled
ninja -C build
ninja -C build install

echo "*** Building fribidi ***"
cd $BUILD_DIR/fribidi-*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
./configure --prefix=$TARGET_DIR --disable-shared --enable-static --disable-docs
make -j $jval
make install

echo "*** Building libass ***"
cd $BUILD_DIR/libass-*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
./autogen.sh
./configure --prefix=$TARGET_DIR --disable-shared
make -j $jval
make install

echo "*** Building mp3lame ***"
cd $BUILD_DIR/lame*
# The lame build script does not recognize aarch64, so need to set it manually
uname -a | grep -q 'aarch64' && lame_build_target="--build=arm-linux" || lame_build_target=''
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
[ ! -f config.status ] && ./configure --prefix=$TARGET_DIR --enable-nasm --disable-shared $lame_build_target
make
make install

echo "*** Building opus ***"
cd $BUILD_DIR/opus*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
[ ! -f config.status ] && ./configure --prefix=$TARGET_DIR --disable-shared
make
make install

echo "*** Building libvpx ***"
cd $BUILD_DIR/libvpx*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
[ ! -f config.status ] && PATH="$BIN_DIR:$PATH" ./configure --prefix=$TARGET_DIR --disable-examples --disable-unit-tests --enable-pic
PATH="$BIN_DIR:$PATH" make -j $jval
make install

echo "*** Building librtmp ***"
cd $BUILD_DIR/rtmpdump
cd librtmp
[ $rebuild -eq 1 ] && make distclean || true

# there's no configure, we have to edit Makefile directly
if [ "$platform" = "linux" ]; then
  sed -i "/INC=.*/d" ./Makefile # Remove INC if present from previous run.
  sed -i "s/prefix=.*/prefix=${TARGET_DIR_SED}\nINC=-I\$(prefix)\/include/" ./Makefile
  sed -i "s/SHARED=.*/SHARED=no/" ./Makefile
elif [ "$platform" = "darwin" ]; then
  sed -i "s/prefix=./prefix=${TARGET_DIR_SED}/" ./Makefile
fi
make install_base

echo "*** Building libsoxr ***"
cd $BUILD_DIR/soxr-*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
PATH="$BIN_DIR:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$TARGET_DIR" -DBUILD_SHARED_LIBS:bool=off -DWITH_OPENMP:bool=off -DBUILD_TESTS:bool=off
make -j $jval
make install

echo "*** Building libvidstab ***"
cd $BUILD_DIR/vid.stab-*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
PATH="$BIN_DIR:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$TARGET_DIR" -DBUILD_SHARED_LIBS:bool=off
make -j $jval
make install

echo "*** Building openjpeg ***"
cd $BUILD_DIR/openjpeg-*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
PATH="$BIN_DIR:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$TARGET_DIR" -DBUILD_SHARED_LIBS:bool=off
make -j $jval
make install

echo "*** Building zimg ***"
cd $BUILD_DIR
rm -rf zimg
git clone https://github.com/sekrit-twc/zimg.git
cd $BUILD_DIR/zimg*
git submodule update --init --recursive .
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
./autogen.sh
./configure --enable-static  --prefix=$TARGET_DIR --disable-shared
sed -i 's/size_t/std::size_t/g' src/zimg/colorspace/matrix3.cpp
make -j $jval
make install

echo "*** Building libwebp ***"
cd $BUILD_DIR/libwebp*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
./autogen.sh
./configure --prefix=$TARGET_DIR --disable-shared
make -j $jval
make install

echo "*** Building libvorbis ***"
cd $BUILD_DIR/vorbis*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
./autogen.sh
./configure --prefix=$TARGET_DIR --disable-shared
make -j $jval
make install

echo "*** Building libogg ***"
cd $BUILD_DIR/ogg*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
./autogen.sh
./configure --prefix=$TARGET_DIR --disable-shared
make -j $jval
make install

echo "*** Building libspeex ***"
cd $BUILD_DIR/speex*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
./autogen.sh
./configure --prefix=$TARGET_DIR --disable-shared
make -j $jval
make install

echo "*** Building libsdl ***"
cd $BUILD_DIR/SDL*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
./autogen.sh
./configure --prefix=$TARGET_DIR --disable-shared
make -j $jval
make install

echo "*** Building RIST ***"
cd $BUILD_DIR
rm -rf librist
git clone https://code.videolan.org/rist/librist.git
cd $BUILD_DIR/librist*
git checkout v0.2.10
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
mkdir -p build
cd build
meson --default-library=static .. --prefix=$TARGET_DIR --bindir="../bin/" --libdir="$TARGET_DIR/lib"
ninja
ninja install

echo "*** Building SRT ***"
cd $BUILD_DIR/srt*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
mkdir -p build
cd build
cmake -DENABLE_APPS=OFF -DCMAKE_INSTALL_PREFIX=$TARGET_DIR -DENABLE_C_DEPS=ON -DENABLE_SHARED=OFF -DENABLE_STATIC=ON -DOPENSSL_USE_STATIC_LIBS=ON ..
sed -i 's/-lgcc_s/-lgcc_eh/g' haisrt.pc
sed -i 's/-lgcc_s/-lgcc_eh/g' srt.pc
make
make install

echo "*** Building dav1d ***"
cd $BUILD_DIR
rm -rf dav1d
git clone --depth 1 --branch 1.5.4 https://code.videolan.org/videolan/dav1d.git
cd $BUILD_DIR/dav1d
PATH="$BIN_DIR:$PATH" meson setup build --default-library=static --prefix=$TARGET_DIR --libdir=lib -Denable_tools=false -Denable_tests=false -Denable_examples=false -Denable_docs=false
ninja -C build
ninja -C build install

echo "*** Building libaom ***"
cd $BUILD_DIR
rm -rf aom
git clone --depth 1 --branch v3.15.2 https://aomedia.googlesource.com/aom
cd $BUILD_DIR/aom
PATH="$BIN_DIR:$PATH" cmake -G "Unix Makefiles" -S . -B aom_build -DCMAKE_INSTALL_PREFIX="$TARGET_DIR" -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS:bool=off -DENABLE_DOCS=0 -DENABLE_EXAMPLES=0 -DENABLE_TESTS=0 -DENABLE_TOOLS=0 -DENABLE_NASM=1
make -C aom_build -j $jval
make -C aom_build install

echo "*** Building SVT-AV1 ***"
cd $BUILD_DIR
rm -rf SVT-AV1
git clone --depth 1 --branch v4.2.0 https://gitlab.com/AOMediaCodec/SVT-AV1.git
cd $BUILD_DIR/SVT-AV1
PATH="$BIN_DIR:$PATH" cmake -G "Unix Makefiles" -S . -B svt_build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$TARGET_DIR" -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS:bool=off -DBUILD_APPS:bool=off -DBUILD_TESTING:bool=off
make -C svt_build -j $jval
make -C svt_build install

# FFMpeg
echo "*** Building FFmpeg ***"
cd $BUILD_DIR/ffmpeg*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true

if [ "$platform" = "linux" ]; then
  [ ! -f config.status ] && PATH="$BIN_DIR:$PATH" \
  PKG_CONFIG_PATH="$TARGET_DIR/lib/pkgconfig" ./configure \
    --prefix="$TARGET_DIR" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I$TARGET_DIR/include" \
    --extra-ldflags="-L$TARGET_DIR/lib" \
    --extra-libs="-lpthread -lm -lz" \
    --extra-ldexeflags="-static" \
    --bindir="$BIN_DIR" \
    --enable-pic \
    --enable-ffplay \
    --enable-fontconfig \
    --enable-frei0r \
    --enable-gpl \
    --enable-version3 \
    --enable-libass \
    --enable-libfribidi \
    --enable-libfdk-aac \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libopencore-amrnb \
    --enable-libopencore-amrwb \
    --enable-libopenjpeg \
    --enable-libopus \
    --enable-librtmp \
    --enable-libsoxr \
    --enable-libspeex \
    --enable-libtheora \
    --enable-libvidstab \
    --enable-libvo-amrwbenc \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libwebp \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libxvid \
    --enable-libzimg \
    --enable-nonfree \
    --enable-openssl \
    --enable-librist \
    --enable-libsrt \
    --enable-libdav1d \
    --enable-libaom \
    --enable-libsvtav1
elif [ "$platform" = "darwin" ]; then
  [ ! -f config.status ] && PATH="$BIN_DIR:$PATH" \
  PKG_CONFIG_PATH="${TARGET_DIR}/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/local/Cellar/openssl/1.0.2o_1/lib/pkgconfig" ./configure \
    --cc=/usr/bin/clang \
    --prefix="$TARGET_DIR" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I$TARGET_DIR/include" \
    --extra-ldflags="-L$TARGET_DIR/lib" \
    --extra-ldexeflags="-Bstatic" \
    --bindir="$BIN_DIR" \
    --enable-pic \
    --enable-ffplay \
    --enable-fontconfig \
    --enable-frei0r \
    --enable-gpl \
    --enable-version3 \
    --enable-libass \
    --enable-libfribidi \
    --enable-libfdk-aac \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libopencore-amrnb \
    --enable-libopencore-amrwb \
    --enable-libopenjpeg \
    --enable-libopus \
    --enable-librtmp \
    --enable-libsoxr \
    --enable-libspeex \
    --enable-libvidstab \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libwebp \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libxvid \
    --enable-libzimg \
    --enable-nonfree \
    --enable-openssl \
    --enable-librist \
    --enable-libsrt \
    --enable-libdav1d \
    --enable-libaom \
    --enable-libsvtav1
fi

PATH="$BIN_DIR:$PATH" make -j $jval
make install
make distclean
hash -r

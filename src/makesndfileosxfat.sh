### RUN THIS FILE FROM THE LIBSNDFILE REPO FOLDER

mkdir -p osxfat
mkdir -p osxfat/include
mkdir -p osxfat/lib

# build 32-bit
export CFLAGS="-arch i386 -mmacosx-version-min=10.6 -O2"
export CXXFLAGS=$CFLAGS
export LDFLAGS=$CFLAGS
./configure --disable-sqlite --disable-external-libs
make clean; make -j4

cp src/.libs/libsndfile.1.dylib osxfat/lib/libsndfile32.1.dylib
cp src/.libs/libsndfile.a osxfat/lib/libsndfile32.a

# build 64-bit
export CFLAGS="-arch x86_64 -mmacosx-version-min=10.6 -O2"
export CXXFLAGS=$CFLAGS
export LDFLAGS=$CFLAGS
./configure --disable-sqlite --disable-external-libs
make clean; make -j4

cp src/.libs/libsndfile.1.dylib osxfat/lib/libsndfile64.1.dylib
cp src/.libs/libsndfile.a osxfat/lib/libsndfile64.a


# create FAT binary:
pushd osxfat/lib
lipo -create libsndfile32.a libsndfile64.a -output libsndfile.a
rm libsndfile32.a
rm libsndfile64.a
lipo -create libsndfile32.1.dylib libsndfile64.1.dylib -output libsndfile.1.dylib
rm libsndfile32.1.dylib 
rm libsndfile64.1.dylib
popd

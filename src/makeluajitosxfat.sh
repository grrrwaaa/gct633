### RUN THIS FILE FROM THE LUAJIT-2.0 REPO FOLDER

mkdir -p osxfat
mkdir -p osxfat/include
mkdir -p osxfat/lib

# build 32-bit
make clean
make CC="gcc -m32"
sudo make install
cp /usr/local/lib/libluajit-5.1.a osxfat/lib/libluajit32.a

# copy headers:
cp /usr/local/include/luajit-2.0/* osxfat/include/

# build 64-bit
make clean
make CC="gcc -m64"
make 
sudo make install
cp /usr/local/lib/libluajit-5.1.a osxfat/lib/libluajit64.a

# restore normality
make clean
make
sudo make install
sudo ln -sf /usr/local/bin/luajit-2.0.1 /usr/local/bin/luajit

# create FAT binary:
pushd osxfat/lib
lipo -create libluajit32.a libluajit64.a -output libluajit.a
rm libluajit64.a
rm libluajit32.a
popd

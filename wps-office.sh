#!/usr/bin/env bash

APP=wps-office
VERSION=$(wget -q https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=wps-office -O - | grep "pkgver=" | head -1 | cut -c 8-)

# CREATE A TEMPORARY DIRECTORY
mkdir -p tmp
cd tmp

# DOWNLOADING THE DEPENDENCIES
if test -f ./appimagetool; then
	echo " appimagetool already exists" 1> /dev/null
else
	echo " Downloading appimagetool..."
	wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
fi
if test -f ./pkg2appimage; then
	echo " pkg2appimage already exists" 1> /dev/null
else
	echo " Downloading pkg2appimage..."
	wget -q https://raw.githubusercontent.com/ivan-hc/AM-application-manager/main/tools/pkg2appimage
fi
chmod a+x ./appimagetool ./pkg2appimage
rm -f ./recipe.yml

# CREATING THE HEAD OF THE RECIPE
cat >> recipe.yml << 'EOF'
app: wps-office
binpatch: true

ingredients:

  dist: oldstable
  sources:
    - deb http://ftp.debian.org/debian/ oldstable main contrib non-free
    - deb http://security.debian.org/debian-security/ oldstable-security main contrib non-free
    - deb http://ftp.debian.org/debian/ oldstable-updates main contrib non-free
  script:
    - URL=$(wget -q https://aur.archlinux.org/packages/wps-office -O - | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | grep -i "amd64.deb" | head -1)
    - wget $URL
  packages:
    - wps-office
    
# From https://github.com/AppImageCommunity/pkg2appimage/blob/master/recipes/wps-office.yml
script:
  - cp ./usr/share/applications/wps-office-prometheus.desktop ./
  - cp ./usr/share/icons/hicolor/256x256/mimetypes/wps-office2019-kprometheus.png ./
  # Patch startup script to make sure it will start normally. Make the path be relative.
  # patching et
  - sed -i "2i#WPS startup script modified by linlinger " ./usr/bin/et
  - sed -i '3i currdir="$(dirname "$(readlink -f "${0}")")" ' ./usr/bin/et
  - sed -i '9,13d' ./usr/bin/et
  - sed -i '9i gInstallPath=$currdir/../../opt/kingsoft/wps-office/' ./usr/bin/et
  # patching wpp
  - sed -i "2i#WPS startup script modified by linlinger " ./usr/bin/wpp
  - sed -i '3i currdir="$(dirname "$(readlink -f "${0}")")" ' ./usr/bin/wpp
  - sed -i '9,13d' ./usr/bin/wpp
  - sed -i '9i gInstallPath=$currdir/../../opt/kingsoft/wps-office/' ./usr/bin/wpp
  # patching wps
  - sed -i "2i#WPS startup script modified by linlinger " ./usr/bin/wps
  - sed -i '3i currdir="$(dirname "$(readlink -f "${0}")")" ' ./usr/bin/wps
  - sed -i '9,13d' ./usr/bin/wps
  - sed -i '9i gInstallPath=$currdir/../../opt/kingsoft/wps-office/' ./usr/bin/wps
  # patching wpspdf
  - sed -i "2i#WPS startup script modified by linlinger " ./usr/bin/wpspdf
  - sed -i '3i currdir="$(dirname "$(readlink -f "${0}")")" ' ./usr/bin/wpspdf
  - sed -i '6,10d' ./usr/bin/wpspdf
  - sed -i '6i gInstallPath=$currdir/../../opt/kingsoft/wps-office/' ./usr/bin/wpspdf
EOF

# DOWNLOAD ALL THE NEEDED PACKAGES AND COMPILE THE APPDIR
./pkg2appimage ./recipe.yml

# LIBUNIONPRELOAD
#wget https://github.com/project-portable/libunionpreload/releases/download/amd64/libunionpreload.so
#chmod a+x libunionpreload.so
#mv ./libunionpreload.so ./$APP/$APP.AppDir/

# COMPILE SCHEMAS
glib-compile-schemas ./$APP/$APP.AppDir/usr/share/glib-2.0/schemas/ || echo "No ./usr/share/glib-2.0/schemas/"

# CUSTOMIZE THE APPRUN
rm -R -f ./$APP/$APP.AppDir/AppRun
cat >> ./$APP/$APP.AppDir/AppRun << 'EOF'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="$HERE/usr/lib":"$HERE/usr/lib/x86_64-linux-gnu":"$HERE/lib":"$HERE/lib/x86_64-linux-gnu":"$HERE/lib64":$LD_LIBRARY_PATH
case $1 in
	'')		echo -e "\n USAGE:	command [ARGUMENT]"
			echo -e '\n Where [ARGUMENT] is one between "et" "wpp" "wps" and "wpspdf"\n';;
	'et')		"$HERE/usr/bin/et" "$@" | cat;;
	'wpp')		"$HERE/usr/bin/wpp" "$@" | cat;;
	'wps')		"$HERE/usr/bin/wps" "$@" | cat;;
	'wpspdf')	"$HERE/usr/bin/wpspdf" "$@" | cat;;
esac
EOF
	
# MADE THE APPRUN EXECUTABLE
chmod a+x ./$APP/$APP.AppDir/AppRun
# END OF THE PART RELATED TO THE APPRUN, NOW WE WELL SEE IF EVERYTHING WORKS ----------------------------------------------------------------------

# IMPORT THE LAUNCHER AND THE ICON TO THE APPDIR IF THEY NOT EXIST
if test -f ./$APP/$APP.AppDir/*.desktop; then
	echo "The desktop file exists"
else
	echo "Trying to get the .desktop file"
	cp ./$APP/$APP.AppDir/usr/share/applications/*$(ls . | grep -i $APP | cut -c -4)*desktop ./$APP/$APP.AppDir/ 2>/dev/null
fi

ICONNAME=$(cat ./$APP/$APP.AppDir/*desktop | grep "Icon=" | head -1 | cut -c 6-)
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/22x22/apps/*$ICONNAME* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/24x24/apps/*$ICONNAME* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/32x32/apps/*$ICONNAME* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/48x48/apps/*$ICONNAME* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/64x64/apps/*$ICONNAME* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/128x128/apps/*$ICONNAME* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/256x256/apps/*$ICONNAME* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/512x512/apps/*$ICONNAME* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/scalable/apps/*$ICONNAME* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/applications/*$ICONNAME* ./$APP/$APP.AppDir/ 2>/dev/null

# EXPORT THE APP TO AN APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP/$APP.AppDir
cd ..
mv ./tmp/*.AppImage WPS-Office_$VERSION-x86_64.Appimage
chmod a+x *.AppImage

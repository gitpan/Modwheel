#!/bin/bash

#
#
#       This is a script for installing Modwheel on a vanilla installation
#       of Ubuntu Server Linux.
#
#       Run the script with: bash ./BUILD-ubuntu.sh
#

echo "--- Install Modwheel 0.001"
echo "This automatic installation tool requires root access. Please enter your sudo"
echo "password when asked to do so. In some time we will also require you to"
echo "make some decisions so please follow the progress carefully."
echo 
echo "[Press ENTER to continue...]"
read

build_dir="./build-modwheel-$$"
mkdir "$build_dir"
cd "$build_dir"

# ### Ubuntu install developer packages.
for package in \
    autoconf automake gcc-4.1 gcc-doc gdb \
    gdb-doc g++ gobjc autogen bin86 binutils binutils-dev \
    autotools-dev cpp-doc cvs svn gettext libtool \
    linux-headers-2.6.17-10 linux-headers-2.6.17-10-386 \
    linux-headers-2.6.17-10-generic linux-headers.2.6.17-10-server \
    linux-libc-dev make mcpp nasm libc6-dev perl-doc libperl-dev \
    libgdbm3 libgdbm-dev; do
sudo apt-get --assume-yes install $package
done
cd ..

# ### Install Crypt::Eksblowfish (required by Modwheel)
wget http://search.cpan.org/CPAN/authors/id/Z/ZE/ZEFRAM/Crypt-Eksblowfish-0.001.tar.gz
tar xvfz Crypt-Eksblowfish-0.001.tar.gz
cd Crypt-Eksblowfish-0.001
perl Makefile.PL
sudo make install
cd ..

# ### Install HTML::Tagset (required by Modwheel and HTML::Parser)
wget http://search.cpan.org/CPAN/authors/id/P/PE/PETDANCE/HTML-Tagset-3.10.tar.gz
tar xvfz HTML-Tagset-3.10.tar.gz
cd HTML-Tagset-3.10
perl Makefile.PL
sudo make install
cd ..

# ### Install HTML::Parser (required by Modwheel)
wget http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/HTML-Parser-3.56.tar.gz
tar xvfz HTML-Parser-3.56.tar.gz
cd HTML-Parser-3.56
perl Makefile.PL
sudo make install
cd ..

# ### Install URI (required by Modwheel)
wget http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/URI-1.35.tar.gz
tar xvfz URI-1.35.tar.gz
cd URI-1.35
perl Makefile.PL
sudo make install
cd ..

# ### Install YAML (required by Modwheel)
wget http://search.cpan.org/CPAN/authors/id/I/IN/INGY/YAML-0.62.tar.gz
tar xvfz YAML-0.62.tar.gz
cd YAML-0.62
perl Makefile.PL
sudo make install
cd ..

# ### Install File::HomeDir (required by AppConfig)
wget http://search.cpan.org/CPAN/authors/id/A/AD/ADAMK/File-HomeDir-0.64.tar.gz
tar xvfz File-HomeDir-0.64.tar.gz
cd File-HomeDir-0.64
perl Makefile.PL
sudo make install
cd ..

# ### Install AppConfig (required by Template Toolkit)
wget http://search.cpan.org/CPAN/authors/id/A/AD/ADAMK/AppConfig-1.64.tar.gz
tar xvfz AppConfig-1.64.tar.gz
cd AppConfig-1.64
perl Makefile.PL
sudo make install
cd ..

# ### Install Template Toolkit (required by Modwheel)
wget http://search.cpan.org/CPAN/authors/id/A/AB/ABW/Template-Toolkit-2.18.tar.gz
tar xvfz Template-Toolkit-2.18.tar.gz
cd Template-Toolkit-2.18
perl Makefile.PL
# [ answer yes to build the XS Stash module ]
sudo make install
cd ..

# ### Install Term::ReadKey (required by Modwheel)
wget http://search.cpan.org/CPAN/authors/id/J/JS/JSTOWE/TermReadKey-2.30.tar.gz
tar xvfz TermReadKey-2.30.tar.gz
cd TermReadKey-2.30
perl Makefile.PL
sudo make install
cd ..

# ### Install Modwheel
wget http://www.0x61736b.net/Modwheel/Modwheel-0.01.tar.gz
tar xvfz Modwheel-0.01.tar.gz
cd Modwheel-0.01
perl Makefile.PL
sudo make install
sudo bash ./bin/install.sh
# [carefully follow the instructions]
cd ..

cd ..

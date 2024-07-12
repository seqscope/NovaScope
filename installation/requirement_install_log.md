# Install dependencies for NovaScope

The following illustrates one example for installing dependent software tools for NovaScope on a **linux** system. Please note it's not the sole approach. As an HPC user, you have the option to load a tool rather than installing it. To check if the following software is available, use the `module avail` or `module spider` commands.

First, set up the tool directory.

```
tools_dir=<path_to_your_tool_dir>
```

## 1. Install Snakemake
For additional information, consult [Snakemake official Documntation](https://snakemake.readthedocs.io/en/stable/basic_usage/installation.html).

```
## In my case, conda is already installed. 
## Following the official guidance, I installed Mambdforge
conda install -n base -c conda-forge mamba

## Full installation of snakemake.
conda activate base
mamba create -c conda-forge -c bioconda -n snakemake snakemake

## Sanity check. Make sure the path is correct
mamba activate snakemake
snakemake --version
which snakemake 
smk_bindir=$(dirname $(which snakemake))

## I added it to $PATH
echo -e "export PATH=\"$smk_bindir:\$PATH\"" >> ~/.bashrc
source ~/.bashrc
```

## 2. Install spatula

To install spatula, you will need to its dependencies first. Please see below.

## 2.1 Install libdeflate
```
cd $tools_dir
git clone https://github.com/ebiggers/libdeflate.git
cd $tools_dir/libdeflate

#module load cmake/3.26.3 ## If needed
cmake -B build && cmake --build build

## Add it to LD_LIBRARY_PATH
echo -e "export LD_LIBRARY_PATH="$tools_dir/libdeflate/build:\$LD_LIBRARY_PATH\"" >> ~/.bashrc
source ~/.bashrc

## I also created a softlink of the libdeflate.so from the build folder to $tools_dir/libdeflate
ln -s $tools_dir/libdeflate/build/libdeflate.so $tools_dir/libdeflate/libdeflate.so
```

## 2.2 Install htslib
```
cd $tools_dir
git clone https://github.com/samtools/htslib
cd $tools_dir/htslib

## Build the configure script and install files it uses
autoreconf -i  

## Use the CPPFLAGS and LDFLAGS environment variables to assist in locating libdeflate as it was installed in non-standard places.
## The CPPFLAGS will help locate the libdeflate.h and the LDFLAGS should point to the directory containing libdeflate.so 
./configure --with-libdeflate CPPFLAGS=-I$tools_dir/libdeflate LDFLAGS='-L$tools_dir/libdeflate/build -Wl,-R$tools_dir/libdeflate/build'

## If you encounter this error: "configure: error: htscodecs submodule files not present.", 
## run `git submodule update --init --recursive`, then rerun the last step.

## Install
## (1) If you have access to /usr/local/lib or /usr/local/include
# make install  
## (2) If not, add `export PATH="$tools_dir/htslib:\$PATH"` to bashrc
echo -e "export PATH=\"$tools_dir/htslib:\$PATH\"" >> ~/.bashrc
source ~/.bashrc
```

## 2.3 Install qgenlib

```
cd $tools_dir
git clone  https://github.com/hyunminkang/qgenlib.git
cd $tools_dir/qgenlib

mkdir build
cd build
cmake ..
make
```

## 2.4 spatula

See more details for spatula on [GitHub](https://github.com/seqscope/spatula).

```
cd $tools_dir
git clone git@github.com:seqscope/spatula.git
cd spatula

mkdir build
cd build
cmake ..
make
```

# 3. Install samtools

```
cd $tools_dir
wget https://github.com/samtools/samtools/releases/download/1.19.2/samtools-1.19.2.tar.bz2 ./
tar -xvjf samtools-1.19.2.tar.bz2

mkdir $tools_dir/samtools

cd $tools_dir/samtools-1.19.2/
./configure --prefix=$tools_dir/samtools
make
make install

## Add to the PATH
echo -e "export PATH=\"$tools_dir/samtools/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc
```

# 4. Install Starsolo

```
cd $tools_dir
wget https://github.com/alexdobin/STAR/archive/2.7.11a.tar.gz
tar -xzf 2.7.11a.tar.gz
cd $tools_dir/STAR-2.7.11a

echo -e "export PATH=\"$tools_dir/STAR-2.7.11a/bin/Linux_x86_64:\$PATH\"" >> ~/.bashrc
source ~/.bashrc
```

# 5. Install python

You should already have python installed. But if needed, here is an example of installing python.

```
cd $tools_dir
wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz ./
tar -xvzf Python-3.10.0.tgz

mkdir $tools_dir/python310

cd $tools_dir/Python-3.10.0/

./configure --enable-optimizations --prefix $tools_dir/python310

make -j4    # use 4 cores
make altinstall

echo -e "export PATH=\"$tools_dir/python310/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc
```
 
# 6. Install imagemagick

```
cd $tools_dir
git clone https://github.com/ImageMagick/ImageMagick.git

mkdir $tools_dir/imagemagick

cd $tools_dir/ImageMagick
./configure --prefix $tools_dir/imagemagick

make
make install

echo -e "export PATH=\"$tools_dir/imagemagick/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc
```

# 7. gdal

## 7.1 gcc
To install gdal, you will need to install gcc first.
Here we installed it via GSRC (GNU Source Release Collection)

```
cd $tools_dir
bzr checkout --lightweight  bzr://bzr.savannah.gnu.org/gsrc/trunk/ gsrc
cd gsrc/

mkdir $tools_dir/GNU

./bootstrap      
./configure --prefix=$tools_dir/GNU

source ./setup.sh

echo "source $tools_dir/gsrc/setup.sh" >> ~/.bashrc
source ~/.bashrc

make install

## A test run 
make -C pkg/gnu/hello install

## Install some dependencies
make -C pkg/other/isl install
make -C pkg/gnu/gmp install
make -C pkg/gnu/mpfr install
make -C pkg/gnu/mpc install
make -C pkg/gnu/iconv install

## I manually revised the enable-languages to `c,c++,fortran` in the config.smk file and the Makefile in the pkg/gnu/gcc10.

## Install gcc
## Check available versions
ls pkg/gnu/|grep gcc 
## We installed gcc10 as it has been tested.
make -C pkg/gnu/gcc10 install
```

## 7.2 gdal
```
cd $tools_dir
wget https://github.com/OSGeo/gdal/releases/download/v3.5.1/gdal-3.5.1.tar.gz ./
tar -zxvf gdal-3.5.1.tar.gz

mkdir $tools_dir/gdal

cd gdal-3.5.1
./configure --prefix=$tools_dir/gdal 

make
make install
```


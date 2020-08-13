# inPsights
inPsights is a open-source software package for the probability density analysis (PDA) of the total electronic wave function Ψ.
It analyzes maxima data generated by the open-source quantum Monte Carlo software package [Amolqc](https://github.com/luechow-group/Amolqc).

## Installation
### Installing required packages
To install inPsights, Git, CMake, the GNU Compiler Collection (gcc) and the Eigen3 library must be installed. This is most easily achieved by employing a packet manager.

#### MacOS
Make sure that the Xcode Command Line Tools are installed already with: 
Make sure that the latest Xcode Command Line Tools are installed with: 
```bash
xcode-select --install
```
(**Note:** On macOS 10.15 (Catalina), `Command Line Tools 11.15` or greater seems to be required.)


To install the required packages on MacOS, the [homebrew package manager](https://brew.sh) can be used. 
It can be downloaded and installed from the command line as follows:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```
To download the packages with `homebrew` execute the following command in the terminal:
```bash
brew update
brew upgrade
brew install git cmake gcc@9 lapack eigen boost qt
```

Alternatively, the Qt5 online installer can be used, which is found on the [Qt webpage](https://www.qt.io/download).
During the installation, make sure to install Qt for the `x86_64` architecture and select `sources`, `Qt3D`, and additionally `QtCharts` (which will be required in future versions as well).


#### Ubuntu
On Ubuntu, the package manager `aptitude` can be used.
To download the required packages with `aptitude` execute the following command in the terminal:
```bash
sudo apt-get -y install \
    build-essential git cmake \
    gcc g++ gfortran \
    libgomp1 libblas-dev liblapack-dev libeigen3-dev libboost-all-dev \ 
```

The preferred method to install Qt5 on Ubuntu is the Qt5 online installer, which is found on the [Qt webpage](https://www.qt.io/download).
During the installation, make sure to install Qt for the `x86_64` architecture and select `sources`, `Qt3D`, and additionally `QtCharts` (which will be required in future versions as well).

Alternatively, the package manager `aptitude` can be used:
```bash
sudo apt-get -y install qtbase5-dev qt3d5-dev 
```
This might cause problems during the build of the inPsights GUI.

#### Submodules in inPsights
After cloning the repository, make sure to initialize and update the submodules
```bash
git submodule update --init --recursive
```
to initialize all the submodules.

The next time you checkout a branch e.g. the submodules do not need to be initialized again afterwards. Thus
```bash
git submodule update --recursive
```
should be sufficient.

### Setting environment variables

#### Compilers
Environment variables for different compilers and associated libraries can be specified e.g. 

for the `GNU Compiler Collection`
```bash
export CC=/usr/local/bin/gcc-9
export CXX=/usr/local/bin/g++-9
export FC=/usr/local/bin/gfortran-9
```
or `Intel Parallel Studio XE`
```bash
export FC=/opt/intel/bin/ifort
export CC=/opt/intel/bin/icc
export CXX=/opt/intel/bin/icpc
export INTELROOT=/opt/intel/
export MKLROOT=/opt/intel/mkl
```
Otherwise the default compilers are used.

#### Qt5
To build the inPsights GUI, environment variables to the Qt5 libraries are required.

If Qt5 was installed via homebrew, the following environment variable must be exported:

```bash
export CMAKE_PREFIX_PATH=/usr/local/Cellar/qt/5.XX.X
```

If Qt5 was download from the webpage and installed via the installer, the following environment variable must be exported:
```bash
export Qt5_DIR=/home/<username>/Qt/5.XX.X/gcc_64
```

If Qt5 was installed via `apt-get`, CMake should automatically find the library (not tested).

#### Amolqc
If the `AmolqcInterface` module is required, the following cmake option has to be set:
```bash
-DBUILD_AMOLQC=ON
```
Additionally, the path to `Amolqc` must be exported as an environment variable e.g.
```bash
export AMOLQC=/home/<username>/inPsights/src/AmolqcInterface/Amolqc
```
This is **not** necessary for building the `inPsights` and `ProcessMaxima` executable.

## Building ProcessMaxima and inPsights

Create a build directory e.g.
```bash
mkdir cmake-build-release
cd cmake-build-release
```
and configure CMake for an out-of-source release build:
```bash
cmake ..
```
CMake options can be specified to build the GUI or to use a precompiled version of the Eigen library
```bash
cmake .. -DBUILD_GUI=ON -DBUILD_EIGEN=OFF
```

To build the `ProcessMaxima` executable run
```bash
make ProcessMaxima
```
To build the `inPsights` executable run
```bash
make inPsights
```
which requires `-DBUILD_GUI=ON`.


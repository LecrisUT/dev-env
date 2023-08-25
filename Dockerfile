FROM fedora:latest

LABEL authors="Cristian Le"
LABEL org.opencontainers.image.source=https://github.com/LecrisUT/dev-env

########################
# Prepare Repositories #
########################

RUN dnf install -y \
    dnf5 dnf-plugins-core
RUN dnf5 upgrade -y
# Intel repositories
RUN echo -e '\
[oneAPI]\n\
name=Intel(R) oneAPI repository\n\
baseurl=https://yum.repos.intel.com/oneapi\n\
enabled=1\n\
gpgcheck=1\n\
repo_gpgcheck=1\n\
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB' > /etc/yum.repos.d/oneAPI.repo

################
# Common tools #
################

# Normally cmake should be from the Github action with arbitrary version
RUN dnf5 install -y \
        ninja-build git cmake

# C sanitizer libraries
RUN dnf5 install -y \
    libasan libhwasan libtsan libubsan liblsan

#################
# GCC Toolchain #
#################

RUN dnf5 install -y \
    gcc gcc-c++ gcc-fortran \
    lcov

##################
# LLVM Toolchain #
##################

RUN dnf5 install -y \
    clang flang flang-devel \
    clang-tools-extra

###################
# Intel toolchain #
###################

RUN dnf5 install -y \
    intel-oneapi-compiler-dpcpp-cpp intel-oneapi-compiler-fortran

# Install intel modules
RUN /opt/intel/oneapi/modulefiles-setup.sh
RUN ln -s /opt/intel/oneapi/modulefiles/mpi/latest /usr/share/modulefiles/mpi/intel
RUN echo -e '\
export MODULEPATH=$(/usr/share/lmod/lmod/libexec/addto --append MODULEPATH /opt/intel/oneapi/modulefiles\n\
' > /etc/profile.d/intel-modules.sh

#############################
# OpenMP and MPI toolchains #
#############################

RUN dnf5 install -y \
    openmpi-devel mpich-devel libomp-devel

###############
# BLAS/LAPACK #
###############

RUN dnf5 install -y \
    flexiblas-devel

###########
# Cleanup #
###########

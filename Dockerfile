FROM ubuntu:latest

LABEL authors="Cristian Le"
LABEL org.opencontainers.image.source=https://github.com/LecrisUT/dev-env

########################
# Prepare Repositories #
########################

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt upgrade -y
# software-properties-common: add-apt-repository
RUN apt install -y \
    wget software-properties-common
# Intel repositories
# TODO: Disabled intel toolchain because GPG key issue
#RUN wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | \
#      tee /etc/apt/trusted.gpg.d/intel.asc && \
#    add-apt-repository -y "deb https://apt.repos.intel.com/oneapi all main"
# Nightly gcc
RUN wget https://kayari.org/gcc-latest/gcc-latest.deb
# LLVM toolchains: see https://apt.llvm.org
RUN wget https://apt.llvm.org/llvm.sh && chmod +x llvm.sh

################
# Common tools #
################

# Normally cmake should be from the Github action with arbitrary version
RUN apt install -y \
        ninja-build git cmake

#################
# GCC Toolchain #
#################

#RUN apt install -y \
#        gcc-multilib g++-multilib g++ gcc gfortran
RUN for gcc_version in 10 11 12; do \
      apt install -y "gcc-${gcc_version}" "g++-${gcc_version}" "gfortran-${gcc_version}" && \
      update-alternatives --install /usr/bin/gcc gcc $(which gcc-${gcc_version}) "${gcc_version}0" \
        --slave /usr/bin/g++ g++ $(which g++-${gcc_version}) \
        --slave /usr/bin/gfortran gfortran $(which gfortran-${gcc_version}) \
        --slave /usr/bin/gcov gcov $(which gcov-${gcc_version}); \
    done
# Nightly gcc
RUN dpkg -i gcc-latest.deb
ENV PATH=${PATH}:/opt/gcc-latest/bin
RUN \
    gcc_version=latest && \
    ln -s g++ /opt/gcc-latest/bin/"g++-${gcc_version}" && \
    ln -s gcc /opt/gcc-latest/bin/"gcc-${gcc_version}" && \
    ln -s gcov /opt/gcc-latest/bin/"gcov-${gcc_version}" && \
    update-alternatives --install /usr/bin/gcc gcc $(which gcc-${gcc_version}) "99999" \
        --slave /usr/bin/g++ g++ $(which g++-${gcc_version}) \
        --slave /usr/bin/gcov gcov $(which gcov-${gcc_version})
# Other toolchain programs
RUN apt install -y \
    gcovr lcov
RUN rm gcc-latest.deb

##################
# LLVM Toolchain #
##################

# Pre-requisite for llvm.sh
RUN apt install -y \
    gnupg lsb-release
RUN for llvm_version in 14 15 16 17; do \
      ./llvm.sh "${llvm_version}" all && \
      apt install "flang-${llvm_version}" && \
      update-alternatives --install /usr/bin/clang clang $(which clang-${llvm_version}) "${llvm_version}0" \
        --slave /usr/bin/clang++ clang++ $(which clang++-${llvm_version}) \
        --slave /usr/bin/clang-cpp clang-cpp $(which clang-cpp-${llvm_version}) \
        --slave /usr/bin/clang-scan-deps clang-scan-deps $(which clang-scan-deps-${llvm_version}) \
        --slave /usr/bin/clang-format clang-format $(which clang-format-${llvm_version}) \
        --slave /usr/bin/clang-format-diff clang-format-diff $(which clang-format-diff-${llvm_version}) \
        --slave /usr/bin/clang-tidy clang-tidy $(which clang-tidy-${llvm_version}) \
        --slave /usr/bin/clangd clangd $(which clangd-${llvm_version}) \
        --slave /usr/bin/flang-new flang-new $(which flang-new-${llvm_version}) \
        --slave /usr/bin/llvm-cov llvm-cov $(which llvm-cov-${llvm_version}); \
    done

RUN rm llvm.sh

###################
# Intel toolchain #
###################

# TODO: Disabled intel toolchain because GPG key issue
#RUN apt install -y \
#    intel-oneapi-compiler-dpcpp-cpp intel-oneapi-compiler-fortran

#############################
# OpenMP and MPI toolchains #
#############################

# MPI providers
RUN apt install -y \
    openmpi-bin libopenmpi-dev mpich libmpich-dev
# OpenMP
RUN apt install -y \
    libomp-dev

###############
# BLAS/LAPACK #
###############

# FlexiBLAS is not avaliable on ubuntu :(
# BLAS
RUN apt install -y \
    libopenblas-dev libopenblas-openmp-dev libopenblas-pthread-dev libopenblas-serial-dev
# LAPACK
RUN apt install -y \
    liblapack-dev liblapacke-dev

###########
# Cleanup #
###########

RUN apt clean && \
    rm -rf /var/lib/apt/lists/*

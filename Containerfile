ARG fedora_version=latest

FROM fedora:$fedora_version

ARG toolchain_gcc=true
ARG toolchain_llvm=true
ARG toolchain_intel=true

LABEL authors="Cristian Le"

########################
# Prepare Repositories #
########################

RUN dnf upgrade -y

################
# Common tools #
################

RUN <<EOR
# Build tools
dnf install -y \
  cmake ninja-build

# C sanitizer libraries
RUN dnf install -y \
    libasan libhwasan libtsan libubsan liblsan

# Other common tools
dnf install -y \
  python3-devel git

# Github CLI
dnf install -y gh
EOR

#################
# GCC Toolchain #
#################

RUN <<EOR
if [ "$toolchain_gcc" = "true" ]; then
  dnf install -y \
    gcc gcc-c++ gcc-fortran
fi
EOR

##################
# LLVM Toolchain #
##################

RUN <<EOR
if [ "$toolchain_llvm" = "true" ]; then
  dnf install -y \
    clang flang \
    clang-tools-extra
fi
EOR

#############################
# OpenMP and MPI toolchains #
#############################

RUN <<EOR
# OpenMP and MPI toolchains (built for gcc actually)
dnf install -y \
  openmpi-devel mpich-devel libomp-devel
# BLAS/LAPACK: Using flexiblas as modern wrapper
dnf install -y flexiblas-devel
EOR

###################
# Intel toolchain #
###################

# Intel toolchain needs to be installed after any other tools
# See: https://community.intel.com/t5/oneAPI-Registration-Download/Fedora-package-interferes-with-OS-pacakges/m-p/1641662

RUN <<EOR
if [ "$toolchain_intel" = "true" ]; then
  cat <<EOF > /etc/yum.repos.d/oneAPI.repo
[oneAPI]
name=Intel(R) oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
EOF
  dnf install -y \
    intel-oneapi-compiler-dpcpp-cpp \
    intel-oneapi-compiler-fortran \
    intel-oneapi-mpi-devel
  ln -s /etc/modulefiles/intel/mpi/latest "/usr/share/modulefiles/mpi/intel-$(arch)"
  # Install intel modules
  /opt/intel/oneapi/modulefiles-setup.sh --output-dir=/etc/modulefiles/intel
fi
EOR

###########
# Cleanup #
###########

RUN dnf clean all

##############################
# Setup user and environment #
##############################

# See: https://github.com/actions/runner/blob/main/images/Dockerfile
ENV ImageOS=fedora40
ENV PATH="/github/home/.local/bin:$PATH"
RUN <<EOR
adduser --uid 1001 runner -d /github/home
groupadd docker --gid 123
usermod -aG wheel runner
usermod -aG docker runner
echo "%wheel   ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
EOR

WORKDIR /github/home
USER runner

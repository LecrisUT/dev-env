FROM fedora:41

LABEL authors="Cristian Le"

########################
# Prepare Repositories #
########################

RUN dnf upgrade -y

################
# Common tools #
################

# Normally cmake should be from the Github action with arbitrary version
RUN dnf install -y \
        ninja-build git cmake

# C sanitizer libraries
RUN dnf install -y \
    libasan libhwasan libtsan libubsan liblsan

#################
# GCC Toolchain #
#################

RUN dnf install -y \
    gcc gcc-c++ gcc-fortran \
    lcov

##################
# LLVM Toolchain #
##################

RUN dnf install -y \
    clang flang \
    clang-tools-extra

#############################
# OpenMP and MPI toolchains #
#############################

RUN dnf install -y \
    openmpi-devel mpich-devel libomp-devel
RUN ln -s /etc/modulefiles/intel/mpi/latest "/usr/share/modulefiles/mpi/intel-$(arch)"

###############
# BLAS/LAPACK #
###############

RUN dnf install -y \
    flexiblas-devel

###################
# Intel toolchain #
###################

# Intel toolchain needs to be installed after any other tools
# See: https://community.intel.com/t5/oneAPI-Registration-Download/Fedora-package-interferes-with-OS-pacakges/m-p/1641662

COPY <<EOF /etc/yum.repos.d/oneAPI.repo
[oneAPI]
name=Intel(R) oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
EOF

RUN dnf install -y \
    intel-oneapi-compiler-dpcpp-cpp \
    intel-oneapi-compiler-fortran \
    intel-oneapi-mpi

# Install intel modules
RUN /opt/intel/oneapi/modulefiles-setup.sh --output-dir=/etc/modulefiles/intel

###########################
# Other development tools #
###########################

RUN dnf install -y \
    python3-devel

#########################
# Github specific fixes #
#########################

# Mimic Ubuntu in order to be able to download experimental python
# https://github.com/actions/setup-python/issues/718
COPY <<EOF /etc/lsb-release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=24.04
DISTRIB_CODENAME=noble
DISTRIB_DESCRIPTION="Ubuntu 24.04 LTS"
EOF

# Add the github CLI
RUN dnf install -y \
    gh

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
RUN adduser --uid 1001 runner -d /github/home \
    && groupadd docker --gid 123 \
    && usermod -aG wheel runner \
    && usermod -aG docker runner \
    && echo "%wheel   ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

# Custom environment setup
COPY <<"EOF" /etc/profile.d/setup-runner.sh
# Default variables
TOOLCHAIN=${TOOLCHAIN:-gcc}
MPI_VARIANT=${MPI_VARIANT:-serial}

# Setup environment
if [[ "${TOOLCHAIN,,}" == "intel" ]]; then
	source /opt/intel/oneapi/setvars.sh
fi
if [[ "${MPI_VARIANT,,}" != "serial" ]]; then
	module load mpi/${MPI_VARIANT}
fi

# Print environment
echo "::group::Available modules"
module avail
echo "::endgroup::"
echo "::group::Loaded modules"
module list
echo "::endgroup::"
EOF

WORKDIR /github/home
USER runner

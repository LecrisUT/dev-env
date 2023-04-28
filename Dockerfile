FROM fedora:latest

LABEL authors="Cristian Le"
LABEL org.opencontainers.image.source=https://github.com/LecrisUT/dev-env

# Add intel repository
## TODO: heredoc are not yet supported on podman
## https://github.com/containers/buildah/issues/3474
#COPY <<EOF /etc/yum.repos.d/oneAPI.repo
#[oneAPI]
#name=Intel(R) oneAPI repository
#baseurl=https://yum.repos.intel.com/oneapi
#enabled=1
#gpgcheck=1
#repo_gpgcheck=1
#gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
#EOF

RUN echo -e '\
[oneAPI]\n\
name=Intel(R) oneAPI repository\n\
baseurl=https://yum.repos.intel.com/oneapi\n\
enabled=1\n\
gpgcheck=1\n\
repo_gpgcheck=1\n\
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB' > /etc/yum.repos.d/oneAPI.repo

RUN dnf install -y \
    cmake git ninja-build \
    clang clang-tools-extra lld llvm \
    gcc g++ lcov \
    findutils procps binutils \
    intel-oneapi-compiler-dpcpp-cpp

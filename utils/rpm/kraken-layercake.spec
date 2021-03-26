Name:           kraken-layercake
Version:        0.1.0
Release:        rc1%{?dist}
Summary:        Kraken/Layercake is a cluster management solution based on the Kraken framework. 
Group:          Applications/System
License:        BSD-3
URL:            https://github.com/kraken-hpc/kraken-layercake
Source0:        %{name}-%{version}.tar.gz
BuildRequires:  go, golang >= 1.15, golang-bin, golang-src %define  debug_package %{nil}

%bcond_with initramfs
%bcond_with vbox

%if "%{_arch}" == "x86_64"
%define GoBuildArch amd64
%endif
%if "%{_arch}" == "aarch64"
%define GoBuildArch arm64
%endif
%if "%{_arch}" == "ppc"
%define GoBuildArch ppc
%endif
%if "%{_arch}" == "ppc64"
%define GoBuildArch ppc64
%endif
# TODO - add more architectures

%description
Kraken/Layercake is a cluster management solution based on the Kraken framework.  It provides full-lifecycle maintenance of HPC compute clusters, from cold boot to ongoing system state maintenance and automation.

%if %{with initramfs}
# Define initramfs-<arch> sub-package
%package initramfs-%{GoBuildArch}
BuildArch: noarch
Group: Applications/System
Summary: A base initramfs for use with Kraken PXE configurations (%{GoBuildArch}).
%description initramfs-%{GoBuildArch}
This package installs a pre-built base initramfs (arch: %{GoBuildArch}) for use with a Kraken PXE setup.  This initramfs should be layered with at least two other pieces: 1. a set of needed system modules; 2. a set of configuration files (e.g. uinit.script).

%if %{with vbox}
# Build the initramfs-vbox
%package initramfs-vbox-%{GoBuildArch}
BuildArch: noarch
Group: Applications/System
Summary: A base initramfs for use with Kraken PXE configurations (%{GoBuildArch}).
%description initramfs-vbox-%{GoBuildArch}
This package installs a pre-built base initramfs (arch: %{GoBuildArch}) for use with a Kraken PXE setup.  This initramfs should be layered with at least two other pieces: 1. a set of needed system modules; 2. a set of configuration files (e.g. uinit.script).
%endif
%endif

%if %{with vbox}
%package vbox
Group: Applications/System
Summary: Provides a vbox-enabled Kraken/Layercake.
%description vbox
Provides a vbox-enabled kraken-layercake. This version of Layercake is primarily intended for demonstrations and examples using VirtualBox.
%endif

%if %{with vbox}
%package vboxapi
Group: Applications/System
Summary: Provides the vboxapi service which wraps Oracle VirtualBox with a simple restful API service for power control of VMs.
%description vboxapi
The vboxapi service wraps Oracle VirtualBox with a simple restful API service for power control that can be used by Kraken.
%endif

%prep
%setup -q

%build
# template systemd units
rpm -D "KrakenWorkingDirectory %{?KrakenWorkingDirectory}%{?!KrakenWorkingDirectory:/}" --eval "$(cat utils/rpm/kraken-layercake.service)" > kraken-layercake.service
rpm -D "KrakenWorkingDirectory %{?KrakenWorkingDirectory}%{?!KrakenWorkingDirectory:/}" --eval "$(cat utils/rpm/kraken-layercake-vbox.service)" > kraken-layercake-vbox.service
rpm --eval "$(cat utils/vboxapi/vboxapi.service)" > vboxapi.service
rpm --eval "$(cat utils/vboxapi/vboxapi.environment)" > vboxapi.environment

# build kraken
NATIVE_GOOS=$(go version | awk '{print $NF}' | awk -F'/' '{print $1}')
NATIVE_GOGOARCH=$(go version | awk '{print $NF}' | awk -F'/' '{print $2}')

GOARCH=%{GoBuildArch} go build ./cmd/kraken-layercake

# create default runtime config file
./kraken-layercake -state "/etc/kraken/layercake/state.json" -noprefix -sdnotify -printrc > layercake-config.yaml

%if %{with vbox}
(
  GOARCH=%{GoBuildArch} go build ./cmd/kraken-layercake-vbox
  ./kraken-layercake-vbox -state "/etc/kraken/layercake-vbox/state.json" -noprefix -sdnotify -printrc > layercake-vbox-config.yaml
)
%endif

%if %{with vbox}
# build vboxapi
(
  cd utils/vboxapi
  GOARCH=%{GoBuildArch} go build vboxapi.go
)
%endif

%if %{with initramfs}
# build initramfs
bash utils/layer0/build-layer0-base.sh -o layer0-base-%{GoBuildArch}.xz %{GoBuildArch}

%if %{with vbox}
# build an initramfs that has kraken-layercake-vbox in it
# note: still has non-vbox version too
bash utils/layer0/build-layer0-base.sh -o layer0-vbox-base-%{GoBuildArch}.xz %{GoBuildArch} github.com/kraken-hpc/kraken-layercake/cmd/kraken-layercake-vbox

%endif
%endif

%install
mkdir -p %{buildroot}
# kraken
install -D -m 0755 kraken-layercake %{buildroot}%{_sbindir}/kraken-layercake
install -D -m 0644 kraken-layercake.service %{buildroot}%{_unitdir}/kraken-layercake.service
install -D -m 0644 utils/rpm/state.json %{buildroot}%{_sysconfdir}/kraken/layercake/state.json
install -D -m 0644 layercake-config.yaml %{buildroot}%{_sysconfdir}/kraken/layercake/config.yaml
%if %{with vbox}
# kraken-layercake-vbox
install -D -m 0755 kraken-layercake-vbox %{buildroot}%{_sbindir}/kraken-layercake-vbox
install -D -m 0644 kraken-layercake-vbox.service %{buildroot}%{_unitdir}/kraken-layercake-vbox.service
install -D -m 0644 utils/rpm/state.json %{buildroot}%{_sysconfdir}/kraken/layercake-vbox/state.json
install -D -m 0644 layercake-vbox-config.yaml %{buildroot}%{_sysconfdir}/kraken/layercake-vbox/config.yaml
# vboxapi
install -D -m 0755 utils/vboxapi/vboxapi %{buildroot}%{_sbindir}/vboxapi
install -D -m 0644 vboxapi.service %{buildroot}%{_unitdir}/vboxapi.service
install -D -m 0644 vboxapi.environment %{buildroot}%{_sysconfdir}/sysconfig/vboxapi
%endif
%if %{with initramfs}
# initramfs
install -D -m 0644 initramfs-base-%{GoBuildArch}.xz %{buildroot}/tftp/layer0-base-%{GoBuildArch}.xz
%if %{with vbox}
install -D -m 0644 initramfs-vbox-base-%{GoBuildArch}.xz %{buildroot}/tftp/layer0-vbox-base-%{GoBuildArch}.xz
%endif
%endif

%files
%defattr(-,root,root)
%license LICENSE
%{_sbindir}/kraken-layercake
%config(noreplace) %{_sysconfdir}/kraken/layercake/state.json
%config(noreplace) %{_sysconfdir}/kraken/layercake/config.yaml
%{_unitdir}/kraken-layercake.service

%if %{with vbox}
%files vbox
%license LICENSE
%{_sbindir}/kraken-layercake-vbox
%config(noreplace) %{_sysconfdir}/kraken/layercake-vbox/state.json
%config(noreplace) %{_sysconfdir}/kraken/layercake-vbox/config.yaml
%{_unitdir}/kraken-layercake-vbox.service

%files vboxapi
%license LICENSE
%{_sbindir}/vboxapi
%config(noreplace) %{_sysconfdir}/sysconfig/vboxapi
%{_unitdir}/vboxapi.service
%endif

%if %{with initramfs}
%files initramfs-%{GoBuildArch}
%license LICENSE
/tftp/layer0-base-%{GoBuildArch}.gz
%if %{with vbox}
%files initramfs-vbox-%{GoBuildArch}
%license LICENSE
/tftp/layer0-vbox-base-%{GoBuildArch}.gz
%endif
%endif

%changelog
* Fri Mar 26 2021 J. Lowell Wofford <lowell@lanl.gov> 0.1.0-rc1
- Combine vbox and vboxapi options into one vbox option for all vbox-related packages
- Fix initramfs building
- Build an initramfs-vbox-base if vbox is specified

* Wed Mar 24 2021 J. Lowell Wofford <lowell@lanl.gov> 0.1.0-rc0
- Migrate to kraken-layercake from kraken
- Build/install kraken-layercake-vbox if vbox is specified
- Remove the depricated powermanapi
- Reset versioning to match intended git versioning scheme

* Tue Jan 26 2021 J. Lowell Wofford <lowell@lanl.gov> 1.0-1
- Add initramfs, powermanapi, and vboxapi packages

* Wed Jan 13 2021 J. Lowell Wofford <lowell@lanl.gov> 1.0-0
- Initial RPM build of kraken

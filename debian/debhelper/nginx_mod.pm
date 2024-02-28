# A build system class for handling nginx modules.
#
# Copyright: © 2022 Miao Wang
# License: MIT

package Debian::Debhelper::Buildsystem::nginx_mod;

use strict;
use warnings;
use Dpkg::Deps qw(deps_parse);
use Dpkg::Control::Info;
use Debian::Debhelper::Dh_Lib qw(error doit getpackages addsubstvar);
use File::Spec;
use parent qw(Debian::Debhelper::Buildsystem::makefile);
use Config;

sub DESCRIPTION {
	"Nginx Module (config)"
}

sub check_auto_buildable {
	my ($this, $step) = @_;

	return 1 if -e $this->get_sourcepath("config");
}

sub _NGINX_SRC_DIR {
	"/usr/share/nginx/src"
}

sub _NDK_SRC_DIR {
	"/usr/share/nginx-ndk/src"
}

sub new {
	my $class=shift;
	my $this= $class->SUPER::new(@_);
	my $ngx_ver = `grep 'define NGINX_VERSION' /usr/share/nginx/src/src/core/nginx.h | sed -e 's/^.*"\\(.*\\)".*/\\1/'`;
	chomp($ngx_ver);
	$this->prefer_out_of_source_building(@_);
	$this->{has_ndk} = $this->has_build_dep("libnginx-mod-http-ndk-dev");
	$this->{has_stream} = $this->has_build_dep("libnginx-mod-stream");
	foreach my $cur (getpackages('arch')) {
		if ($this->{has_ndk} == 1) {
			addsubstvar($cur, "misc:Depends", "libnginx-mod-http-ndk");
		}
		if ($this->{has_stream} == 1) {
			addsubstvar($cur, "misc:Depends", "libnginx-mod-stream (>= $ngx_ver), libnginx-mod-stream (<< $ngx_ver.1~)");
		}
	}
	return $this;
}

sub configure {
	my $this=shift;

	doit({
		"chdir" => $this->_NGINX_SRC_DIR,
		"update_env" => {
			"src_dir" => $this->get_sourcedir,
			"bld_dir" => $this->get_builddir,
			"pwd_dir" => $this->{cwd},
		},
	}, "bash", "-c", '. ./conf_flags
		./configure \\
		--with-cc-opt="$(cd "$pwd_dir/$src_dir"; dpkg-buildflags --get CFLAGS) -fPIC $(cd "$pwd_dir/$src_dir"; dpkg-buildflags --get CPPFLAGS)" \\
		--with-ld-opt="$(cd "$pwd_dir/$src_dir"; dpkg-buildflags --get LDFLAGS) -fPIC" \\
		"${NGX_CONF_FLAGS[@]}" \\
		--add-dynamic-module="$pwd_dir/$src_dir" \\
		--builddir="$pwd_dir/$bld_dir" \\
		' . ($this->{has_ndk} ? '--add-module=' . $this->_NDK_SRC_DIR : '') . ' \\
		' . ($this->{has_stream} ? '--with-stream' : '') . ' \\
		"$@"', "dummy", @_);
}

sub build {
	my $this=shift;

	$this->do_make("-f", File::Spec->catfile($this->{cwd}, $this->get_buildpath("Makefile")), "-C", $this->_NGINX_SRC_DIR, "modules");
}

sub test {
	my $this=shift;

	if ( $this->{has_ndk} and !grep( /^ndk_http_module.so$/, @_ ) ) {
		unshift @_, "ndk_http_module.so";
	}

	if ( $this->{has_stream} and !grep( /^ngx_stream_module.so$/, @_ ) ) {
		unshift @_, "ngx_stream_module.so";
	}

	$this->doit_in_builddir("bash", "-e", "-o", "pipefail", "-c", '
		tmp_conf=$(mktemp -p .)
		for pre_dep in "$@"; do
			echo "load_module modules/$pre_dep;" >> "$tmp_conf"
		done
		for i in *.so; do
			echo "load_module $PWD/$i;" >> "$tmp_conf"
		done
		echo "events{}" >> "$tmp_conf"
		/usr/sbin/nginx -g "error_log /dev/null; pid /dev/null;" -t -q -c "$PWD/$tmp_conf"
		rm -f "$tmp_conf"
	', "dummy", @_);
}

sub install {
	my $this=shift;
	my $destdir=shift;

	$this->doit_in_builddir("bash", "-e", "-o", "pipefail", "-c", '
		destdir=$1
		mkdir -p "$destdir/usr/lib/nginx/modules"
		for i in *.so; do
			cp "$i" "$destdir/usr/lib/nginx/modules/"
		done
	', "dummy", $destdir);
}

sub clean {
	my $this=shift;
	$this->rmdir_builddir();
}

sub has_build_dep {
	my $this=shift;
	my $bd=shift;
	my $control = Dpkg::Control::Info->new()->get_source();
	my $depends = deps_parse($control->{'Build-Depends'});
	foreach (split /,\s+/,$depends) {
		if ($_ =~ /$bd/) {
		return 1;
	}
	}
	return 0;
}

1

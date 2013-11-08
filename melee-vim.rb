# Forked from original mxcl/homebrew macvim.rb formula
# https://github.com/mxcl/homebrew/blob/master/Library/Formula/macvim.rb
#
require 'formula'

class MeleeVim < Formula
  homepage 'http://code.google.com/p/macvim/'
  url 'https://github.com/b4winckler/macvim/archive/snapshot-71.tar.gz'
  version '7.4-71'
  sha1 '09101e3e29ae517d6846159211ae64e1427b86c0'

  option "skip-system-override", "Skip system vim override"

  depends_on :xcode
  depends_on :python

  def full_name
    user = %x[dscl . -read /Users/$(id -un) RealName | tail -n1]
    user.strip
  end

  # Mavericks Patches, see: https://github.com/lsdr/homebrew-stan/issues/1
  def patches
    DATA unless build.head?
  end

  def install
    # Upstream settings, not touching those
    ENV['ARCHFLAGS'] = "-arch #{MacOS.preferred_arch}"
    ENV.clang if MacOS.version >= :lion

    # There is no reason to compile using big/huge features. Multibyte is enabled
    # as a build option and this formula removes cscope completely.
    # references:
    # http://vimdoc.sourceforge.net/htmldoc/various.html#+feature-list
    # http://www.drchip.org/astronaut/vim/vimfeat.html
    args = %W[
      --with-features=normal
      --with-tlib=ncurses
      --enable-multibyte
      --with-macarchs=#{MacOS.preferred_arch}
      --enable-pythoninterp=dynamic
      --enable-rubyinterp=dynamic
    ]

    args << "--with-compiledby=#{full_name}"
    args << "--with-macsdk=#{MacOS.version}" unless MacOS::CLT.installed?

    # See https://github.com/mxcl/homebrew/issues/17908
    ENV.prepend 'LDFLAGS', "-L#{python2.libdir} -F#{python2.framework}" if python && python.brewed?

    unless MacOS::CLT.installed?
      # On Xcode-only systems:
      # Macvim cannot deal with "/Applications/Xcode.app/Contents/Developer" as
      # it is returned by `xcode-select -print-path` and already set by
      # Homebrew (in superenv). Instead Macvim needs the deeper dir to directly
      # append "SDKs/...".
      args << "--with-developer-dir=#{MacOS::Xcode.prefix}/Platforms/MacOSX.platform/Developer/"
    end

    system "./configure", *args

    inreplace "src/MacVim/icons/Makefile", "$(MAKE) -C makeicns", ""
    inreplace "src/MacVim/icons/make_icons.py", "dont_create = False", "dont_create = True"

    system "make"

    prefix.install "src/MacVim/build/Release/MacVim.app"
    inreplace "src/MacVim/mvim", /^# VIM_APP_DIR=\/Applications$/,
                                 "VIM_APP_DIR=#{prefix}"
    bin.install "src/MacVim/mvim"

    # Create MacVim vimdiff, view, ex equivalents
    executables = %w[mvimdiff mview mvimex gvim gvimdiff gview gvimex]
    # Always override system vim, unless explicitly configured not to
    executables += %w[vi vim vimdiff view vimex] unless build.include? "skip-system-override"
    executables.each {|f| ln_s bin+'mvim', bin+f}
  end

  def caveats; <<-EOS.undent
    MacVim.app installed to:
      #{prefix}

    To link the application:
        ln -s #{prefix}/MacVim.app /Applications
    EOS
  end
end

__END__
diff --git a/src/auto/configure b/src/auto/configure
index 4fd7b82..08af7f3 100755
--- a/src/auto/configure
+++ b/src/auto/configure
@@ -7206,8 +7208,9 @@ echo "${ECHO_T}$rubyhdrdir" >&6; }
	  librubyarg="$librubyarg"
	  RUBY_LIBS="$RUBY_LIBS -L$rubylibdir"
         elif test -d "/System/Library/Frameworks/Ruby.framework"; then
-                        RUBY_LIBS="-framework Ruby"
-                        RUBY_CFLAGS=
+            ruby_fw_ver=`$vi_cv_path_ruby -r rbconfig -e "print $ruby_rbconfig::CONFIG['ruby_version'][0,3]"`
+            RUBY_LIBS="/System/Library/Frameworks/Ruby.framework/Versions/$ruby_fw_ver/Ruby"
+            RUBY_CFLAGS="-I/System/Library/Frameworks/Ruby.framework/Versions/$ruby_fw_ver/Headers -DRUBY_VERSION=$rubyversion"
             librubyarg=
	fi

diff --git a/src/if_ruby.c b/src/if_ruby.c
index 4436e06..44fd5ee 100644
--- a/src/if_ruby.c
+++ b/src/if_ruby.c
@@ -96,11 +96,7 @@
 # define rb_num2int rb_num2int_stub
 #endif

-#ifdef FEAT_GUI_MACVIM
-# include <Ruby/ruby.h>
-#else
-# include <ruby.h>
-#endif
+#include <ruby.h>
 #ifdef RUBY19_OR_LATER
 # include <ruby/encoding.h>
 #endif
diff --git a/src/os_mac.h b/src/os_mac.h
index 78b79c2..54009ab 100644
--- a/src/os_mac.h
+++ b/src/os_mac.h
@@ -16,6 +16,9 @@
 # define OPAQUE_TOOLBOX_STRUCTS 0
 #endif

+/* Include MAC_OS_X_VERSION_* macros */
+#include <AvailabilityMacros.h>
+
 /*
  * Macintosh machine-dependent things.
  *

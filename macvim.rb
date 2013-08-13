# Forked from original mxcl/homebrew macvim.rb formula
# https://github.com/mxcl/homebrew/blob/master/Library/Formula/macvim.rb
#
require 'formula'

class Macvim < Formula
  homepage 'http://code.google.com/p/macvim/'
  url 'https://github.com/b4winckler/macvim/archive/snapshot-70.tar.gz'
  version '7.4-70'
  sha1 '66432ae0fe81b2787b23343b6c99ef81f6b52c3e'

  option "skip-system-override", "Skip system vim override"

  depends_on :xcode
  depends_on :python

  def full_name
    user = %x[dscl . -read /Users/$(id -un) RealName | tail -n1]
    user.strip
  end

  def install
    # Upstream settings, not touching those
    arch = MacOS.prefer_64_bit? ? 'x86_64' : 'i386'
    ENV['ARCHFLAGS'] = "-arch #{arch}"
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
      --with-macarchs=#{arch}
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

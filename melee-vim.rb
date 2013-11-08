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
    {
      :p0 => [
        'https://gist.github.com/lsdr/7364336/raw/d8ed8fd460455b1a4fb1290680bebc102fdb706a/framework-detection.patch',
        'https://gist.github.com/lsdr/7364336/raw/6d97cea4883bdd9b353c8cd8b1bcff86b6799f98/framework-version-match.patch',
        'https://gist.github.com/lsdr/7364336/raw/1d5ac8bcc40f75b10020b4dc81577ccfd0bb4b21/missing-macros.patch'
      ]
    }
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

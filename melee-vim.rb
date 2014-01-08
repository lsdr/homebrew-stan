# Forked from original mxcl/homebrew macvim.rb formula
# https://github.com/Homebrew/homebrew/blob/master/Library/Formula/macvim.rb
# reference: https://github.com/b4winckler/macvim/wiki/building
#
require 'formula'

class MeleeVim < Formula
  homepage  'http://code.google.com/p/macvim/'
  url       'https://github.com/b4winckler/macvim/archive/snapshot-72.tar.gz'
  version   '7.4-72'
  sha1      '3fb5b09d7496c8031a40e7a73374424ef6c81166'

  option 'skip-system-override', 'Skip system vim override'

  depends_on :xcode
  depends_on :python

  def full_name
    user = %x[dscl . -read /Users/$(id -un) RealName | tail -n1]
    user.strip
  end

  def install
    # Upstream settings, not touching those
    ENV['ARCHFLAGS'] = "-arch #{MacOS.preferred_arch}"
    ENV.clang if MacOS.version >= :lion

    # MacVim doesn't require any Python, unset PYTHONPATH
    ENV.delete('PYTHONPATH')

    # There is no reason to compile using big/huge features. Multibyte is
    # enabled as a build option and this formula removes cscope completely.
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

    # See https://github.com/Homebrew/homebrew/issues/17908
    if build.with? 'python'
      py_prefix = Pathname.new `python-config --prefix`.chomp
      ENV.prepend 'LDFLAGS', "-L#{py_prefix}/lib/python2.7/config -F#{py_prefix.parent.parent}"
    end

    unless MacOS::CLT.installed?
      # On Xcode-only systems:
      # Macvim cannot deal with "/Applications/Xcode.app/Contents/Developer" as
      # it is returned by `xcode-select -print-path` and already set by
      # Homebrew (in superenv). Instead Macvim needs the deeper dir to directly
      # append "SDKs/...".
      args << "--with-developer-dir=#{MacOS::Xcode.prefix}/Platforms/MacOSX.platform/Developer/"
    end

    system './configure', *args

    # No custom icons
    inreplace 'src/MacVim/icons/Makefile', '$(MAKE) -C makeicns', ''
    inreplace 'src/MacVim/icons/make_icons.py', 'dont_create = False', 'dont_create = True'

    system 'make'

    prefix.install 'src/MacVim/build/Release/MacVim.app'
    inreplace      'src/MacVim/mvim', /^# VIM_APP_DIR=\/Applications$/,
                                 "VIM_APP_DIR=#{prefix}"
    bin.install    'src/MacVim/mvim'

    # Create MacVim vimdiff, view, ex equivalents and override system vim,
    # unless explicitly configured not to:
    executables =  %w[mvimdiff mview mvimex gvim gvimdiff gview gvimex]
    executables += %w[vi vim vimdiff view vimex] unless build.include? 'skip-system-override'
    executables.each { |f| ln_s bin+'mvim', bin+f }
  end

  def caveats; <<-EOS.undent
    MacVim.app installed to:
      #{prefix}

    To link the application:
        ln -s #{prefix}/MacVim.app /Applications
    EOS
  end
end

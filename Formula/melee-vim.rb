# Forked from original mxcl/homebrew macvim.rb formula
# https://github.com/Homebrew/homebrew/blob/master/Library/Formula/macvim.rb
# reference: https://github.com/b4winckler/macvim/wiki/building
#
class MeleeVim < Formula
  desc      'GUI for vim'
  homepage  'https://github.com/macvim-dev/macvim'
  url       'https://github.com/macvim-dev/macvim/archive/snapshot-96.tar.gz'
  version   '7.4-96'
  sha256    'c594b6b76c54820cee09a397974c901ea310254c626466033edc63a7e52992c7'

  option 'skip-system-override', 'Skip system vim override'

  depends_on xcode: :build

  def full_name
    user = %x[dscl . -read /Users/$(id -un) RealName | tail -n1]
    user.strip
  end

  def install
    # Upstream settings, not touching those
    ENV.clang if MacOS.version >= :lion

    # MacVim doesn't require any packages, unset PYTHONPATH
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
      --with-local-dir=#{HOMEBREW_PREFIX}
    ]

    args << "--with-compiledby=#{full_name}"

    unless MacOS::CLT.installed?
      # On Xcode-only systems:
      # Macvim cannot deal with "/Applications/Xcode.app/Contents/Developer" as
      # it is returned by `xcode-select -print-path` and already set by
      # Homebrew (in superenv). Instead Macvim needs the deeper dir to directly
      # append "SDKs/...".
      args << "--with-developer-dir=#{MacOS::Xcode.prefix}/Platforms/MacOSX.platform/Developer"
      args << "--with-macsdk=#{MacOS.version}"
    end

    system './configure', *args
    system 'make'

    prefix.install 'src/MacVim/build/Release/MacVim.app'
    inreplace      'src/MacVim/mvim', /^# VIM_APP_DIR=\/Applications$/, "VIM_APP_DIR=#{prefix}"
    bin.install    'src/MacVim/mvim'

    # Create MacVim vimdiff, view, ex equivalents and override system vim,
    # unless explicitly configured not to:
    executables =  %w[mvimdiff mview mvimex gvim gvimdiff gview gvimex]
    executables += %w[vi vim vimdiff view vimex] unless build.include? 'skip-system-override'
    executables.each { |ex| bin.install_symlink 'mvim' => ex }
  end
end


# Forked from original mxcl/homebrew macvim.rb formula
# references:
#   https://github.com/Homebrew/homebrew/blob/master/Library/Formula/macvim.rb
#   https://github.com/macvim-dev/homebrew-macvim/blob/master/macvim.rb
#
class MeleeVim < Formula
  desc      "GUI for vim"
  homepage  "http://macvim-dev.github.io/macvim/"
  url       "https://github.com/macvim-dev/macvim/archive/snapshot-124.tar.gz"
  version   "8.0-124"
  sha256    "589898c797b81050f1a2604eb98e9227eba160e5d96e71ed751b7312a3c833a3"

  option "skip-system-override", "Skip system vim override"

  depends_on :xcode => :build
  depends_on "lua" => :build

  def compiled_by
    user = %x[dscl . -read /Users/$(id -un) RealName | tail -n1]
    user.strip
  end

  def install
    # set CC to "clang" and unset PYTHONPATH (not required)
    ENV.clang and ENV.delete("PYTHONPATH")

    # http://vimdoc.sourceforge.net/htmldoc/various.html#+feature-list
    # http://www.drchip.org/astronaut/vim/vimfeat.html
    opts = %W[
      --with-features=big
      --with-tlib=ncurses
      --enable-multibyte
      --with-macarchs=#{MacOS.preferred_arch}
      --with-properly-linked-python2-python3
      --enable-pythoninterp=dynamic
      --enable-rubyinterp=dynamic
      --enable-luainterp=dynamic
      --with-lua-prefix=#{HOMEBREW_PREFIX}
      --with-local-dir=#{HOMEBREW_PREFIX}
      --disable-netbeans
    ]

    opts << "--with-compiledby=#{compiled_by}"

    system "./configure", *opts
    system "make"

    prefix.install "src/MacVim/build/Release/MacVim.app"
    inreplace      "src/MacVim/mvim", /^# VIM_APP_DIR=\/Applications$/, "VIM_APP_DIR=#{prefix}"
    bin.install    "src/MacVim/mvim"

    # Create MacVim vimdiff, view, ex equivalents and override system vim,
    # unless explicitly configured not to:
    executables =  %w[mvimdiff mview mvimex gvim gvimdiff gview gvimex]
    executables += %w[vi vim vimdiff view vimex] unless build.include? "skip-system-override"
    executables.each { |ex| bin.install_symlink "mvim" => ex }
  end
end


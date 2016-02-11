class FortuneDune < Formula
  desc     "Fortune quotes from Frank Herbert's Dune Chronicles"
  homepage "https://github.com/lsdr/fortune-mod-dune"

  url     "https://github.com/lsdr/fortune-dune/archive/2.0.1.tar.gz"
  version "2.0.1"
  sha256  "45f7e5979936976641bc64a2f3135edd147bbe7a0fc10f2e86e285d24cdc1f24"

  depends_on "fortune"

  option "without-symlinks", "do not symlink definitions to fortune database dir"

  def install
    ENV.deparallelize

    fortune_files = %w[
      dune
      dune-messiah
      children-of-dune
      god-emperor
      heretics-of-dune
      chapterhouse-dune
      house-atreides
      house-harkonnen
    ]

    fortune_files.each do |ff|
      system "strfile", "-s", ff, "#{ff}.dat"
      pkgshare.install ff, "#{ff}.dat"
    end

    if build.without? "symlinks"
      opoo "Definitions installed in '#{pkgshare}', but not symlinked."
    else
      games_dir = HOMEBREW_PREFIX/"Cellar/fortune/9708/share/games/fortunes"
      games_dir.install_symlink Dir["#{pkgshare}/*"]
    end
  end

  test do
    system "fortune", "-l", "dune"
  end
end


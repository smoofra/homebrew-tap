
class GitPatchDownloadStrategy < GitDownloadStrategy
  def initialize name, resource
    super
    @baseref = meta[:base]
  end
  def stage
    Homebrew._system("git", "-C", cached_location, "diff", @baseref, @ref) do
      $stdout.reopen('patch')
    end
  end
end

class Bear < Formula
  desc "Generate compilation database for clang tooling"
  homepage "https://github.com/rizsotto/Bear"

  url "https://github.com/rizsotto/Bear/archive/2.1.2.tar.gz"
  sha256 "e321df1e8ff8d0b1203613e0bc5642736b4f1b1a71fd95d96b11b1e38bdbfcfc"

  head "https://github.com/rizsotto/Bear.git"

  patch :p1 do
    url "https://github.com/smoofra/Bear.git", :using => GitPatchDownloadStrategy, :base => "2.1.2"
  end

  depends_on :python if MacOS.version <= :snow_leopard
  depends_on "cmake" => :build

  def install
    ENV.universal_binary
    mkdir "build" do
      system "cmake", "..", *std_cmake_args
      system "make", "install"
    end
  end

  test do
    system "#{bin}/bear", "true"
    assert File.exist? "compile_commands.json"
  end
end


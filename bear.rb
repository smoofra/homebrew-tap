class Bear < Formula
  desc "Generate compilation database for clang tooling"
  homepage "https://github.com/rizsotto/Bear"

  # url "https://github.com/rizsotto/Bear/archive/2.0.3.tar.gz"
  # sha256 "e9d217465198453ce87237e650dedb77f92cb530a10eac53b4a062ba779bd6c1"

  head "https://github.com/rizsotto/Bear.git"
  
  def patch
    url = "https://github.com/smoofra/Bear.git"
    ohai "merging patches from #{url}"
    system "git", "pull", "--no-edit", url, "master"
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


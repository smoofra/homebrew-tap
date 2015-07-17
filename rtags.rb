class Rtags < Formula
  homepage "https://github.com/Andersbakken/rtags"

  # stable do
  #   url "https://github.com/Andersbakken/rtags/archive/v2.0.tar.gz"
  #   sha256 "36733945ea34517903a0e5b800b06a41687ee25d3ab360072568523e5d610d6f"

  #   resource "rct" do
  #     url "https://github.com/Andersbakken/rct.git", :revision => "10700c615179f07d4832d459e6453eed736cfaef"
  #   end
  # end

  head "https://github.com/Andersbakken/rtags.git"

  patch :DATA

  depends_on "cmake" => :build
  depends_on "llvm" => "with-clang"
  depends_on "openssl"

  def install
    unless build.head?
      (buildpath/"src/rct").install resource("rct")
    end

    # we use brew's LLVM instead of the macosx llvm because the macosx one
    # doesn't include libclang.
    ENV.prepend_path "PATH", "#{opt_libexec}/llvm/bin"

    mkdir "build" do
      args = std_cmake_args
      args << ".."

      system "cmake", *args
      system "make"
      system "make", "install"
    end
  end

  test do
    system "sh", "-c", "rc >/dev/null --help  ; test $? == 1"
  end
end

__END__
diff --git a/compiler.cmake b/compiler.cmake
index 6448cc4..d0cc029 100644
--- a/src/rct/compiler.cmake
+++ b/src/rct/compiler.cmake
@@ -10,6 +10,7 @@ endif()
 if (CMAKE_SYSTEM_NAME MATCHES "Darwin")
   add_definitions(-D_DARWIN_UNLIMITED_SELECT)
   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
+  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lc++abi")
 else ()
   if (NOT CMAKE_SYSTEM_NAME MATCHES "CYGWIN")
     set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fpic")

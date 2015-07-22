class Oclint < Formula
  desc "A clang-based static analyser for C, C++, and Objective C"
  homepage "http://oclint.org"
  ### doesn't build, I think because of some clang API change.x
  # url "http://archives.oclint.org/releases/0.8/oclint-0.8.1-src.tar.gz"
  # sha256 "fb6dab9ac619bacfea42e56469147cfc40e680642cedf352b87986c0bf1f7510"

  head do
    url "https://github.com/oclint/oclint.git"
    resource "oclint-xcodebuild" do
      url "https://github.com/oclint/oclint-xcodebuild.git"
    end
  end

  depends_on "cmake" => :build
  depends_on "llvm" => "with-clang"

  patch :DATA

  def install
    (buildpath/"oclint-xcodebuild").install resource("oclint-xcodebuild")
    bin.install "oclint-xcodebuild/oclint-xcodebuild"

    chdir "oclint-scripts" do
      system "sh", "./makeWithExternClang", "#{HOMEBREW_PREFIX}/opt/llvm"
    end
    system "cp", "-a", "./build/oclint-release/", "#{prefix}/"
  end
end


__END__
diff --git a/oclint-core/cmake/OCLintConfig.cmake b/oclint-core/cmake/OCLintConfig.cmake
index ebf7292..6b61de6 100644
--- a/oclint-core/cmake/OCLintConfig.cmake
+++ b/oclint-core/cmake/OCLintConfig.cmake
@@ -6,7 +6,9 @@ IF (${CMAKE_SYSTEM_NAME} MATCHES "Win")
 ELSE()
     SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_LINKER_FLAGS} -fno-rtti -fcolor-diagnostics -Wno-c++11-extensions -fPIC")
 ENDIF()
-SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_CXX_LINKER_FLAGS} -fno-rtti")
+SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_CXX_LINKER_FLAGS} -lc++abi -fno-rtti")
+
+SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_CXX_LINKER_FLAGS} -lc++abi")

 IF(APPLE)
     SET(CMAKE_CXX_FLAGS "-std=c++11 -stdlib=libc++ ${CMAKE_CXX_FLAGS}")

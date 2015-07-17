class Bear < Formula
  desc "Generate compilation database for clang tooling"
  homepage "https://github.com/rizsotto/Bear"
  url "https://github.com/rizsotto/Bear/archive/2.0.3.tar.gz"
  sha256 "e9d217465198453ce87237e650dedb77f92cb530a10eac53b4a062ba779bd6c1"
  head "https://github.com/rizsotto/Bear.git"

  # bottle do
  #   sha256 "c2a70963145a8ec644ebd7c0025ced786b8311fae9d10f858649b9418dba065e" => :yosemite
  #   sha256 "c9b63970285cbd5b341f18dddaaed63de3cc36582aa673058111bfb05a5deecf" => :mavericks
  #   sha256 "5aae5f1bd8f92e2528304ecb6719f0bd495f2b7f0fb9a5051e266bcfade6ee70" => :mountain_lion
  # end

  patch :DATA

  depends_on :python if MacOS.version <= :snow_leopard
  depends_on "cmake" => :build

  def install
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

__END__
diff --git a/bear/main.py.in b/bear/main.py.in
old mode 100644
new mode 100755
index 6181fb6..9e37409
--- a/bear/main.py.in
+++ b/bear/main.py.in
@@ -163,7 +163,7 @@ def format_entry(entry):
         fullname = name if os.path.isabs(name) else os.path.join(cwd, name)
         return os.path.normpath(fullname)
 
-    atoms = classify_parameters(entry['command'])
+    atoms = classify_parameters(entry['command'], entry['directory'])
     if atoms['action'] <= Action.Compile:
         for filename in atoms.get('files', []):
             if is_source_file(filename):
@@ -336,7 +336,7 @@ class Action(object):
     Link, Compile, Preprocess, Info = range(4)
 
 
-def classify_parameters(command):
+def classify_parameters(command, directory):
     """ Parses the command line arguments of the given invocation.
 
     To run analysis from a compilation command, first it disassembles the
@@ -470,7 +470,7 @@ def classify_parameters(command):
 
     def take_from_file(*keys):
         def take(values, iterator, _match):
-            with open(iterator.next()) as handle:
+            with open(os.path.join(directory, iterator.next())) as handle:
                 current = [line.strip() for line in handle.readlines()]
                 for key in keys:
                     values[key] = current

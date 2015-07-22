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

__END__
diff --git a/bear/main.py.in b/bear/main.py.in
index 6181fb6..b5f3c85 100644
--- a/bear/main.py.in
+++ b/bear/main.py.in
@@ -48,7 +48,7 @@ import os.path
 import re
 import shlex
 import itertools
-
+from contextlib import contextmanager

 ENVIRONMENTS = [("ENV_OUTPUT", "BEAR_OUTPUT")]

@@ -68,7 +68,7 @@ def main():
         logging.getLogger().setLevel(to_logging_level(args.verbose))
         logging.debug(args)

-        if not args.build:
+        if not args.build and not args.trace_directory:
             parser.print_help()
             return 0

@@ -103,10 +103,19 @@ def run(args):
                     if os.path.exists(entry['file']) and not duplicate(entry))
         return commands

-    with TemporaryDirectory(prefix='bear-', dir=tempdir()) as tmpdir:
+    if args.trace_directory is not None:
+        if args.build:
+            tmpdir_context = NewDirectory(args.trace_directory)
+        else:
+            tmpdir_context = ExistingDirectory(args.trace_directory)
+    else:
+        tmpdir_context = TemporaryDirectory(prefix='bear-', dir=tempdir())
+
+    with tmpdir_context as tmpdir:
         # run the build command
-        exit_code = run_build(args.build, tmpdir, args.libear)
-        logging.debug('build finished with exit code: {0}'.format(exit_code))
+        if args.build:
+            exit_code = run_build(args.build, tmpdir, args.libear)
+            logging.debug('build finished with exit code: {0}'.format(exit_code))
         # read the intercepted exec calls
         commands = (parse_exec_trace(os.path.join(tmpdir, filename))
                     for filename
@@ -163,7 +172,7 @@ def format_entry(entry):
         fullname = name if os.path.isabs(name) else os.path.join(cwd, name)
         return os.path.normpath(fullname)
 
-    atoms = classify_parameters(entry['command'])
+    atoms = classify_parameters(entry['command'], entry['directory'])
     if atoms['action'] <= Action.Compile:
         for filename in atoms.get('files', []):
             if is_source_file(filename):
@@ -247,6 +256,17 @@ else:
                 rmtree(self.name)


+@contextmanager
+def NewDirectory(name):
+    if os.path.exists(name):
+        raise Exception, "directory already exists: " + name
+    os.mkdir(name)
+    yield name
+
+@contextmanager
+def ExistingDirectory(name):
+    yield name
+
 def duplicate_check(method):
     """ Predicate to detect duplicated entries.

@@ -314,6 +334,10 @@ def create_parser():
         help="""specify libear file location.""")

     parser.add_argument(
+        '--trace-directory',
+        metavar='<dir>')
+
+    parser.add_argument(
         dest='build',
         nargs=argparse.REMAINDER,
         help="""command to run.""")
@@ -336,7 +360,7 @@ class Action(object):
     Link, Compile, Preprocess, Info = range(4)
 
 
-def classify_parameters(command):
+def classify_parameters(command, directory):
     """ Parses the command line arguments of the given invocation.
 
     To run analysis from a compilation command, first it disassembles the
@@ -470,7 +494,7 @@ def classify_parameters(command):
 
     def take_from_file(*keys):
         def take(values, iterator, _match):
-            with open(iterator.next()) as handle:
+            with open(os.path.join(directory, iterator.next())) as handle:
                 current = [line.strip() for line in handle.readlines()]
                 for key in keys:
                     values[key] = current
diff --git a/libear/ear.c b/libear/ear.c
index 45795cb..5efcf0c 100644
--- a/libear/ear.c
+++ b/libear/ear.c
@@ -40,6 +40,7 @@
 #include <string.h>
 #include <unistd.h>
 #include <dlfcn.h>
+#include <pthread.h>

 #if defined HAVE_POSIX_SPAWN || defined HAVE_POSIX_SPAWNP
 #include <spawn.h>
@@ -382,9 +383,13 @@ static void bear_report_call(char const *fun, char const *const argv[]) {
     static int const RS = 0x1e;
     static int const US = 0x1f;

+    static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
+
     if (!initialized)
         return;

+    pthread_mutex_lock(&lock);
+
     const char *cwd = getcwd(NULL, 0);
     if (0 == cwd) {
         perror("bear: getcwd");
@@ -416,6 +421,8 @@ static void bear_report_call(char const *fun, char const *const argv[]) {
         exit(EXIT_FAILURE);
     }
     free((void *)cwd);
+
+    pthread_mutex_unlock(&lock);
 }

 /* update environment assure that chilren processes will copy the desired

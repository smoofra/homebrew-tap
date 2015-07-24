
require 'Find'

FOO_C = <<END
int main() {
   return 0;
}
END

MAKEFILE = <<END

install: $(DSTROOT)/foo

$(OBJROOT)/foo.o: foo.c
	clang -c foo.c -o $(OBJROOT)/foo.o

$(DSTROOT)/foo: $(OBJROOT)/foo.o
	clang $(OBJROOT)/foo.o -o $(DSTROOT)/foo

END

class <<nil
  def file?
    return false
  end
end

class FoobarDownloadStrategy < AbstractDownloadStrategy
  def stage
    File.open('foo.c', 'w') do |f|
      f.write(FOO_C)
    end
    File.open('Makefile', 'w') do |f|
      f.write(MAKEFILE)
    end
  end
end
    

class Foobar < Formula

  url "lol-1.0", :using => FoobarDownloadStrategy

  option :dsym

  def install
    mktemp do
      system 'make', '-C', buildpath, "OBJROOT=#{Pathname.pwd}", "DSTROOT=#{prefix}", "install"
      install_dsym if build.dsym?
    end
  end

end

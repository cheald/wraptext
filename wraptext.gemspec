# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.authors       = ["Chris Heald"]
  gem.email         = ["cheald@gmail.com"]
  gem.description   = %q{
    Performs Wordpress-style conversion of single and double newlines to <p> and <br /> tags. Produces well-formed HTML and intelligently ignores unbreakable
    sections like <script> and <pre> tags. Conveniently turns Wordpress post content into valid HTML.
  }
  gem.summary       = %q{Wraps bare text nodes from an HTML document in <p> tags and splits text nodes on double newlines.}
  gem.homepage      = "http://github.com/cheald/wraptext"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "wraptext"
  gem.require_paths = ["lib"]
  gem.version       = "0.1.6"
  gem.signing_key = '/home/chris/.gemcert/gem-private_key.pem'
  gem.cert_chain  = ['/home/chris/.gemcert/gem-public_cert.pem']

  gem.add_dependency('nokogiri')
end

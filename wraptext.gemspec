# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.authors       = ["Chris Heald"]
  gem.email         = ["cheald@gmail.com"]
  gem.description   = %q{Wraps bare text nodes from an HTML document in <p> tags and splits text nodes on double newlines. Conveniently serves to format Wordpress post content properly as a side effect.}
  gem.summary       = %q{Wraps bare text nodes from an HTML document in <p> tags and splits text nodes on double newlines.}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "wraptext"
  gem.require_paths = ["lib"]
  gem.version       = "0.1.1"

  gem.add_dependency('nokogiri')
end

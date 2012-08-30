require File.expand_path('../lib/ovo_templatesnmptraps_summarizer/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Kenichi Kamiya']
  gem.email         = ['kachick1+ruby@gmail.com']
  gem.summary       = %q{"trap.dat" to some CSV files.}
  gem.description   = %q{A utility for the OVO(OpenViewOperations).  
"trap.dat" to some CSV files.}
  gem.homepage      = 'https://github.com/kachick/ovo_template-snmptraps_summarizer'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'ovo_template-snmptraps_summarizer'
  gem.require_paths = ['lib']
  gem.version       = OVO_TemplateSNMPTraps_Summarizer::VERSION.dup # dup for https://github.com/rubygems/rubygems/commit/48f1d869510dcd325d6566df7d0147a086905380#-P0

  gem.required_ruby_version = '>=1.9.3'
  gem.add_development_dependency 'yard', '>=0.8.2.1'
  gem.add_development_dependency 'redcarpet'
end


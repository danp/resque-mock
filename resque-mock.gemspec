Gem::Specification.new do |gem|
  gem.authors       = ["Dan Peterson"]
  gem.email         = ["dpiddy@gmail.com"]
  gem.description   = gem.summary = %q{Mock resque with threads}
  gem.homepage      = 'https://github.com/dpiddy/resque-mock'

  gem.files         = ['lib/resque/mock.rb']
  gem.test_files    = ['Rakefile'] + Dir['spec/**.rb']
  gem.name          = "resque-mock"
  gem.require_paths = ['lib']
  gem.version       = '0.1.1.pre'

  gem.add_runtime_dependency     'resque'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
end

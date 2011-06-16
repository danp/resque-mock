begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new do |t|
    t.rspec_opts = %w[ -c ]
    t.pattern = 'spec/**/*_spec.rb'
  end

  task :default => :spec
rescue LoadError
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << ["tiny_proxy", 'spec']
  t.test_files = FileList['spec/**/*_spec.rb']
  t.verbose = true
end

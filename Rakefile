
task :sanity do
  ruby "-c lib/gds2.rb"
end

task :rspec do
  sh "rspec -f d --fail-fast"
end

task :default => :rspec



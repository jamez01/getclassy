Gem::Specification.new do |s|
  s.name    = 'GetClassy'
  s.version = '0.1.1'
  s.summary = 'Generate Sinatra applications'
  s.executables = [ 'getclassy' ]
  s.default_executable = [ 'getclassy' ]
  s.author   = 'James Paterni'
  s.email    = 'james@ruby-code.com'
  s.homepage = 'http://ruby-code.com/projects/getclassy'

  # These dependencies are only for people who work on this gem
  s.add_development_dependency 'rspec'

  # Include everything in the lib folder
  s.files = Dir['lib/**/*']

  # Supress the warning about no rubyforge project
  s.rubyforge_project = 'nowarning'
end


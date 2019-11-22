folders = ['app', 'lib', 'config']

Gem::Specification.new do |s|
  s.name = 'includes_iidx'
  s.version = "0.1.0"
  s.summary = 'generate includes / select scope to optimize queries'
  s.files = Dir['{app,config,lib}/**/*']
  s.author = "Adrien LENGLET"
  s.require_paths = folders
end

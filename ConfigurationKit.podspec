Pod::Spec.new do |s|
  s.name         = 'ConfigurationKit'
  s.version      = '1.1.0'
  s.license      =  { :type => 'MIT' }
  s.homepage     = 'https://github.com/delannoyk/ConfigurationKit'
  s.authors      = {
    'Kevin Delannoy' => 'delannoyk@gmail.com'
  }
  s.summary      = 'ConfigurationKit is a framework that helps you to always have right configuration for your apps.'

# Source Info
  s.source       =  {
    :git => 'https://github.com/delannoyk/ConfigurationKit.git',
    :tag => s.version.to_s
  }
  s.source_files = 'sources/ConfigurationKit/**/*.swift'

  s.ios.deployment_target = '8.0'

  s.osx.deployment_target = '10.9'
  s.osx.exclude_files = 'sources/ConfigurationKit/event/ApplicationEventProducer.swift'

  s.tvos.deployment_target = '9.0'

  s.requires_arc = true
end

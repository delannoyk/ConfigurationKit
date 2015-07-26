Pod::Spec.new do |s|
  s.name         = 'ConfigurationKit'
  s.version      = '0.2.0'
  s.license      =  { :type => 'MIT' }
  s.homepage     = 'https://github.com/delannoyk/ConfigurationKit'
  s.authors      = {
    'Kevin Delannoy' => 'delannoyk@gmail.com'
  }
  s.summary      = ''

# Source Info
  s.platform     =  :ios, '8.0'
  s.source       =  {
    :git => 'https://github.com/delannoyk/ConfigurationKit.git',
    :tag => s.version.to_s
  }
  s.source_files = 'sources/ConfigurationKit/**/*.swift'
  s.framework    =  'UIKit'

  s.requires_arc = true
end

Pod::Spec.new do |s|
  s.name             = 'call_state'
  s.version          = '0.1.0'
  s.summary          = 'Detects active phone calls and call state changes.'
  s.description      = 'Flutter plugin that exposes call state through MethodChannel and EventChannel.'
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Example' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'
  s.frameworks       = 'CallKit'
  s.swift_version    = '5.0'
end

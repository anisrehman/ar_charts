Pod::Spec.new do |s|
  s.name             = 'ar_charts'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'https://flutter.dev'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'ar_charts/Sources/ar_charts/**/*.{swift,h,m}'
  s.dependency       'Flutter'
  s.dependency       'Charts'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.9'
end

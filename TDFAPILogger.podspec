Pod::Spec.new do |s|
  s.name         = "TDFAPILogger"
  s.version      = "0.0.4"
  s.summary      = "API日志"

  s.description  = <<-DESC
  provide developer convenience when compose some api request code..
                   DESC

  s.homepage     = "git@git.2dfire-inc.com:ios/TDFAPILogger.git"

  s.license      = "LICENSE"
  s.author       = { "oufen" => "oufen@2dfire.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "git@git.2dfire-inc.com:ios/TDFAPILogger.git", tag: s.version }

s.ios.deployment_target = '8.0'
s.source_files = 'TDFAPILoggerExample/TDFAPILoggerExample/Classes/**/*.{h,m}'

s.dependency 'AFNetworking'

end

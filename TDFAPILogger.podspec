Pod::Spec.new do |s|
  s.name         = "TDFAPILogger"
  s.version      = '1.0.0'
  s.summary      = "API日志输出工具"

  s.description  = <<-DESC
  provide developer convenience when compose some api request code..
                   DESC

  s.homepage     = "https://github.com/summer20140803/TDFAPILogger"
  s.social_media_url = 'http://silentcat.top/2017/07/21/iOS-Pretty-Format-API%E6%97%A5%E5%BF%97%E6%89%93%E5%8D%B0/'

  s.license      = "LICENSE"
  s.author       = { '开不了口的猫' => 'summer20140803@gmail.com' }
  s.source       = { :git => "https://github.com/summer20140803/TDFAPILogger.git', tag: s.version }

s.ios.deployment_target = '9.0'
s.source_files = 'TDFAPILoggerExample/TDFAPILoggerExample/Classes/**/*.{h,m}'

s.dependency 'AFNetworking'

end

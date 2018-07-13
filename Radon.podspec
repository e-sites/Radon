Pod::Spec.new do |s|
  s.name           = "Radon"
  s.version        = `sh get_version.sh`
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.summary        = "R.swift minimized"
  s.author         = { "Bas van Kuijck" => "bas@e-sites.nl" }
  s.license        = { :type => "MIT", :file => "LICENSE" }
  s.homepage       = "https://github.com/e-sites/#{s.name}"
  s.source         = { :git => "https://github.com/e-sites/#{s.name}.git", :tag => s.version.to_s }
  s.preserve_paths = "bin/radon"
  s.source_files   = "bin/*.h"
  s.requires_arc   = true
  s.frameworks    = 'Foundation', 'UIKit'
end
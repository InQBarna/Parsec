Pod::Spec.new do |s|
s.name             = "Parsec"
s.version          = "1.1.3"
s.summary          = "Modular JSON API to Core Data parser and validator"
s.description      = <<-DESC
**Parsec** eases the task of getting `JSON API` documents into Core Data.
DESC
s.homepage         = 'https://github.com/InQBarna/Parsec'
s.license          = 'MIT'
s.author           = { 'David Romacho' => 'david.romacho@inqbarna.com', 'Santiago Becerra' => 'santiago.becerra@inqbarna.com' }
s.source           = { :git => "https://github.com/InQBarna/Parsec/Parsec.git", :tag => 'v1.1.3' }

s.ios.deployment_target = '10.0'
s.requires_arc = true
s.source_files = 'Source/**/*'
s.swift_version = '5.0'

s.frameworks = 'Foundation', 'CoreData'
end

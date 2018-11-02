Pod::Spec.new do |s|
s.name             = "Parsec"
s.version          = "0.1.0"
s.summary          = "Modular JSON API to Core Data parser and validator"
s.description      = <<-DESC
**Parsec** eases the task of getting a `JSON API` response into Core Data.
DESC
s.homepage         = 'https://github.com/InQBarna/Parsec'
s.license          = 'MIT'
s.author           = { "David Romacho" => "david.romacho@inqbarna.com" }
s.source           = { :git => "https://github.com/InQBarna/Parsec/Parsec.git" }

s.ios.deployment_target = '10.0'
s.requires_arc = true
s.source_files = 'Source/**/*'

s.frameworks = 'Foundation', 'CoreData'
end

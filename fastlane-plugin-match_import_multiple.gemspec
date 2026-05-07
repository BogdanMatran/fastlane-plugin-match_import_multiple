lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/match_import_multiple/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-match_import_multiple'
  spec.version       = Fastlane::MatchImportMultiple::VERSION
  spec.author        = 'Bogdan Matran'
  spec.email         = 'bogdancristian.matran@gmail.com'

  spec.summary       = "Import multiple provisioning profiles into a match repo in a single invocation"
  spec.description   = "Wraps fastlane match's Importer to accept an array of provisioning profile paths so you can register many profiles for the same certificate in one command, instead of running fastlane match import once per profile."
  # spec.homepage      = "https://github.com/<GITHUB_USERNAME>/fastlane-plugin-match_import_multiple"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = '>= 2.7'

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'
end

require "English"
lib = File.expand_path("lib", __dir__)
  s.name = "tdlib-ruby".freeze
require "tdlib/version"
  gem.summary       = "Ruby bindings and client for TDlib"
  gem.description   = "Ruby bindings and client for TDlib"

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR) - ["lib/tdlib/td_api_tl_parser.rb"]
  s.require_paths = ["lib".freeze]
  s.authors = ["Southbridge".freeze]
  s.date = "2022-03-02"
  s.description = "Ruby bindings and client for TDlib".freeze
  s.email = "ask@southbridge.io".freeze
  s.executables = ["build".freeze, "console".freeze]
  s.files = [".document".freeze, ".gitignore".freeze, ".gitmodules".freeze, ".rspec".freeze, ".travis.yml".freeze, ".yardopts".freeze, "ChangeLog.md".freeze, "Gemfile".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "bin/build".freeze, "bin/console".freeze, "lib/tdlib-ruby.rb".freeze, "lib/tdlib/api.rb".freeze, "lib/tdlib/client.rb".freeze, "lib/tdlib/errors.rb".freeze, "lib/tdlib/update_handler.rb".freeze, "lib/tdlib/update_manager.rb".freeze, "lib/tdlib/version.rb".freeze, "spec/integration/tdlib_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/tdlib_spec.rb".freeze, "tdlib-ruby.gemspec".freeze]
  s.homepage = "https://github.com/centosadmin/tdlib-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.2.32".freeze
  s.summary = "Ruby bindings and client for TDlib".freeze
  s.test_files = ["spec/integration/tdlib_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/tdlib_spec.rb".freeze]

  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "async"
  gem.add_runtime_dependency "dry-configurable", "~> 0.13"
  gem.add_runtime_dependency "fast_jsonparser"
  gem.add_runtime_dependency "ffi", "~> 1.0"
  gem.add_runtime_dependency "tdlib-schema"

  gem.add_development_dependency "bundler", "~> 2.0"
  gem.add_development_dependency "pry", "~> 0.11"
  gem.add_development_dependency "rake", "~> 13.0"
  gem.add_development_dependency "rspec", "~> 3.0"
  gem.add_development_dependency "rubygems-tasks", "~> 0.2"
  gem.add_development_dependency "yard", "~> 0.9"
  gem.metadata["rubygems_mfa_required"] = "true"
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_development_dependency(%q<rubygems-tasks>.freeze, ["~> 0.2"])
    s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
    s.add_development_dependency(%q<pry>.freeze, ["~> 0.11"])
  else
    s.add_dependency(%q<dry-configurable>.freeze, ["~> 0.14.0"])
    s.add_dependency(%q<concurrent-ruby>.freeze, ["~> 1.1"])
    s.add_dependency(%q<ffi>.freeze, ["~> 1.0"])
    s.add_dependency(%q<tdlib-schema>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 2.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<rubygems-tasks>.freeze, ["~> 0.2"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.9"])
    s.add_dependency(%q<pry>.freeze, ["~> 0.11"])
  end
end

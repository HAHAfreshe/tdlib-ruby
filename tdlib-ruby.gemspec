# -*- encoding: utf-8 -*-
<<<<<<< HEAD
# stub: tdlib-ruby 3.0.6 ruby lib

Gem::Specification.new do |s|
  s.name = "tdlib-ruby".freeze
  s.version = "3.0.6"
=======
# stub: tdlib-ruby 3.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "tdlib-ruby".freeze
  s.version = "3.0.8"
>>>>>>> f53de388403909bd9f6d283bc60e34cae71278c6

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Southbridge".freeze]
<<<<<<< HEAD
  s.date = "2022-03-04"
=======
  s.date = "2022-03-02"
>>>>>>> f53de388403909bd9f6d283bc60e34cae71278c6
  s.description = "Ruby bindings and client for TDlib".freeze
  s.email = "ask@southbridge.io".freeze
  s.executables = ["build".freeze, "console".freeze]
  s.files = [".document".freeze, ".gitignore".freeze, ".gitmodules".freeze, ".rspec".freeze, ".travis.yml".freeze, ".yardopts".freeze, "ChangeLog.md".freeze, "Gemfile".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "bin/build".freeze, "bin/console".freeze, "lib/tdlib-ruby.rb".freeze, "lib/tdlib/api.rb".freeze, "lib/tdlib/client.rb".freeze, "lib/tdlib/errors.rb".freeze, "lib/tdlib/update_handler.rb".freeze, "lib/tdlib/update_manager.rb".freeze, "lib/tdlib/version.rb".freeze, "spec/integration/tdlib_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/tdlib_spec.rb".freeze, "tdlib-ruby.gemspec".freeze]
  s.homepage = "https://github.com/centosadmin/tdlib-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.2.32".freeze
  s.summary = "Ruby bindings and client for TDlib".freeze
  s.test_files = ["spec/integration/tdlib_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/tdlib_spec.rb".freeze]

  s.installed_by_version = "3.2.32" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
<<<<<<< HEAD
    s.add_runtime_dependency(%q<dry-configurable>.freeze, ["~> 0.13"])
=======
    s.add_runtime_dependency(%q<dry-configurable>.freeze, ["~> 0.9"])
>>>>>>> f53de388403909bd9f6d283bc60e34cae71278c6
    s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.1"])
    s.add_runtime_dependency(%q<ffi>.freeze, ["~> 1.0"])
    s.add_runtime_dependency(%q<tdlib-schema>.freeze, [">= 0"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_development_dependency(%q<rubygems-tasks>.freeze, ["~> 0.2"])
    s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
    s.add_development_dependency(%q<pry>.freeze, ["~> 0.11"])
  else
<<<<<<< HEAD
    s.add_dependency(%q<dry-configurable>.freeze, ["~> 0.13"])
=======
    s.add_dependency(%q<dry-configurable>.freeze, ["~> 0.9"])
>>>>>>> f53de388403909bd9f6d283bc60e34cae71278c6
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

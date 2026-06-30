require_relative 'lib/fillable-pdf/version'

Gem::Specification.new do |spec|
  spec.name = 'fillable-pdf'
  spec.version = FillablePDF::VERSION
  spec.authors = ['Vadim Kononov']
  spec.email = ['vadim@konoson.com']

  spec.summary = 'Fill out or extract field values from simple fillable PDF forms using iText.'
  spec.description = 'FillablePDF is an extremely simple and lightweight utility that bridges iText and Ruby in order to fill out fillable PDF forms or extract field values from previously filled out PDF forms.'
  spec.homepage = 'https://github.com/vkononov/fillable-pdf'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.4.0'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ example/ .git .rubocop Appraisals Gemfile Rakefile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'base64', '~> 0.1'
  spec.add_dependency 'fiddle', '>= 1.0'
  spec.add_dependency 'rjb', '~> 1.6'
  spec.requirements << 'JDK >= 8'

  spec.metadata['rubygems_mfa_required'] = 'true'
end

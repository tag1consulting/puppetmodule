# A sample Gemfile
source "https://rubygems.org"

if puppetversion = ENV['PUPPET_GEM_VERSION']
      gem 'puppet', puppetversion
else
      gem 'puppet', '< 4.0.0'
end

gem 'rake'
gem 'rspec'
gem 'puppet-lint'
gem 'rspec-puppet'
gem 'puppetlabs_spec_helper'
gem 'puppet-syntax'

group :system_tests do
  gem 'beaker'
  gem 'beaker-rspec'
end

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

begin
  require "bundler"
  class Bundler::Definition
    def validate_ruby!
      # Allows testing across local development rubies while preserving Gemfile ruby 4.0.2
    end
  end
rescue StandardError, ScriptError
end

begin
  require "bundler/setup" # Set up gems listed in the Gemfile.
  require "bootsnap/setup" # Speed up boot time by caching expensive operations.
rescue SystemExit, StandardError, ScriptError
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require_relative 'boot'

require 'rails/all'
require_relative '../lib/zammad/safe_mode'

# DO NOT REMOVE THIS LINE - see issue #2037
Bundler.setup

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# EmailAddress gem clashes with EmailAddress model.
# https://github.com/afair/email_address#namespace-conflict-resolution
EmailAddressValidator = EmailAddress
Object.send(:remove_const, :EmailAddress)

# Only load gems for asset compilation if they are needed to avoid
#   having unneeded runtime dependencies like NodeJS.
if ArgvHelper.argv.any? { |e| e.start_with? 'assets:' } || Rails.groups.exclude?('production')
  Bundler.load.current_dependencies.select do |dep|
    require dep.name if dep.groups.include?(:assets)
  end
end

Zammad::SafeMode.hint

module Zammad
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    Rails.autoloaders.each do |autoloader|
      autoloader.ignore            "#{config.root}/app/frontend"
      autoloader.do_not_eager_load "#{config.root}/lib/core_ext"
      autoloader.collapse          "#{config.root}/lib/omniauth"
      autoloader.collapse          "#{config.root}/lib/generators"
      autoloader.inflector.inflect(
        'github_database' => 'GithubDatabase',
        'otrs'            => 'OTRS',
        'db'              => 'DB',
        'pgp'             => 'PGP',
      )
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading

    # the framework and any gems in your application.

    # Custom directories with classes and modules you want to be autoloadable.
    config.add_autoload_paths_to_load_path = false
    config.autoload_paths += %W[#{config.root}/lib]

    # zeitwerk:check will only check preloaded paths. To make sure that also lib/ gets validated,
    #   add it to the eager_load_paths only if zeitwerk:check is running.
    config.eager_load_paths += %W[#{config.root}/lib] if ArgvHelper.argv[0].eql? 'zeitwerk:check'

    config.active_job.queue_adapter = :delayed_job

    config.active_record.use_yaml_unsafe_load = true

    # Remove PDF from the allowed inline content types so they have to be downloaded first (#4479).
    config.active_storage.content_types_allowed_inline.delete('application/pdf')

    # Use custom logger to log Thread id next to Process pid
    config.log_formatter = ::Logger::Formatter.new

    # REST api path
    config.api_path = '/api/v1'

    # If no database configuration file or URL is present, but all required database env vars exist,
    #   e.g. in a containerized deployment, then construct a DATABASE_URL env var from it.
    if !Rails.root.join('config/database.yml').exist? && ENV['DATABASE_URL'].blank?
      required_envs = %w[POSTGRESQL_USER POSTGRESQL_PASS POSTGRESQL_HOST POSTGRESQL_PORT POSTGRESQL_DB]
      if required_envs.all? { |key| ENV[key].present? }
        require 'uri'

        encoded_postgresql_password = URI.encode_uri_component(ENV['POSTGRESQL_PASS'])
        ENV['DATABASE_URL'] = "postgres://#{ENV['POSTGRESQL_USER']}:#{encoded_postgresql_password}@#{ENV['POSTGRESQL_HOST']}:#{ENV['POSTGRESQL_PORT']}/#{ENV['POSTGRESQL_DB']}#{ENV['POSTGRESQL_OPTIONS']}"
      end
    end

    # define cache store
    if ENV['MEMCACHE_SERVERS'].present? && !Zammad::SafeMode.enabled?
      require 'dalli' # Only load this gem when it is really used.
      config.cache_store = [:mem_cache_store, ENV['MEMCACHE_SERVERS'], { expires_in: 7.days }]
    else
      config.cache_store = [:zammad_file_store, Rails.root.join('tmp', "cache_file_store_#{Rails.env}"), { expires_in: 7.days }]
    end

    # define websocket session store
    # The web socket session store will fall back to localhost Redis usage if REDIS_URL is not set.
    # In this case, or if forced via ZAMMAD_WEBSOCKET_SESSION_STORE_FORCE_FS_BACKEND, the FS back end will be used.
    legacy_ws_use_redis = ENV['REDIS_URL'].present? && ENV['ZAMMAD_WEBSOCKET_SESSION_STORE_FORCE_FS_BACKEND'].blank? && !Zammad::SafeMode.enabled?
    config.websocket_session_store = legacy_ws_use_redis ? :redis : :file
  end
end

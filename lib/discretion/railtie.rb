require 'rails'

module Discretion
  class Railtie < ::Rails::Railtie
    initializer 'discretion.insert_middleware' do |app|
      if defined?(Clearance::RackSession)
        app.config.middleware.insert_after(
          Clearance::RackSession,
          Discretion::Middleware,
        )
      end
    end
  end
end

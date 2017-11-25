module Discretion
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      # From Clearance
      if env[:clearance]&.signed_in?
        Discretion.set_current_viewer(env[:clearance].current_user)
      end
      @app.call(env)
    end
  end
end

module Discretion
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      Discretion.set_current_viewer(env[:clearance].current_user)
      @app.call(env)
    end
  end
end

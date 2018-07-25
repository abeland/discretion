module Discretion
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      # From Clearance

      # Have to do this omnisciently so that when Clearance loads the signed in User, we
      # can gurarantee can_see?() will return true.
      Discretion.omnisciently do
        if env[:clearance]&.signed_in?
          Discretion.set_current_viewer(env[:clearance].current_user)
        end
      end

      @app.call(env)
    end
  end
end

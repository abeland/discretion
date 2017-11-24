module Discretion
  class << self
    CURRENT_VIEWER_KEY = :__discretion_current_viewer

    def current_viewer
      RequestStore[CURRENT_VIEWER_KEY]
    end

    def set_current_viewer(current_viewer)
      RequestStore[CURRENT_VIEWER_KEY] = current_viewer
    end
  end
end

module Discretion
  OMNISCIENT_VIEWER = :__discretion_omnisient_viewer_val
  OMNIPOTENT_VIEWER = :__discretion_omnipotent_viewer_val

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

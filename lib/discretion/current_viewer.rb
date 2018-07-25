module Discretion
  OMNISCIENT_VIEWER = :__discretion_omnisient_viewer_val
  OMNIPOTENT_VIEWER = :__discretion_omnipotent_viewer_val

  class << self
    CURRENT_VIEWER_KEY = :__discretion_current_viewer
    CURRENTLY_ACTING_AS_KEY = :__discretion_currently_acting_as

    def current_viewer
      RequestStore[CURRENT_VIEWER_KEY]
    end

    def set_current_viewer(current_viewer)
      RequestStore[CURRENT_VIEWER_KEY] = current_viewer
    end

    def currently_acting_as
      RequestStore[CURRENTLY_ACTING_AS_KEY]
    end

    def currently_acting_as?(as)
      currently_acting_as == as
    end

    def set_currently_acting_as(as)
      RequestStore[CURRENTLY_ACTING_AS_KEY] = as
    end
  end
end

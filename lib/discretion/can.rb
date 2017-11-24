module Discretion
  class << self
    def can_see_record?(viewer, record)
      return true unless record.is_a?(Discretion::DiscreetModel)

      raise Discretion::CannotSeeError unless record.send(:can_see?, viewer)
    end

    def current_viewer_can_see_record?(record)
      can_see_record?(Discretion.current_viewer, record)
    end

    def can_write_record?(viewer, record)
      return true unless record.is_a?(Discretion::DiscreetModel)

      if record.respond_to?(:can_write?, true)
        raise Discretion::CannotWriteError unless can_see_model?(viewer, record)
      else
        raise Discretion::CannotWriteError unless record.send(:can_write?, viewer)
      end
    end

    def current_viewer_can_write_record?(record)
      can_write_record?(Discretion.current_viewer, record)
    end
  end
end

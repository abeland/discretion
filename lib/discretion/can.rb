module Discretion
  class << self
    def can_see_record?(viewer, record)
      return true unless record.is_a?(Discretion::DiscreetModel)
      return true if Discretion.currently_acting_as?(Discretion::OMNISCIENT_VIEWER) ||
                     Discretion.currently_acting_as?(Discretion::OMNIPOTENT_VIEWER)

      record.send(:can_see?, viewer)
    end

    def current_viewer_can_see_record?(record)
      can_see_record?(Discretion.current_viewer, record)
    end

    def can_write_record?(viewer, record, changes, new_record)
      return true unless record.is_a?(Discretion::DiscreetModel)
      return true if Discretion.currently_acting_as?(Discretion::OMNIPOTENT_VIEWER)

      record.respond_to?(:can_write?, true) ?
        record.send(:can_write?, viewer, changes, new_record) :
        can_see_record?(viewer, record)
    end

    def current_viewer_can_write_record?(record, changes, new_record)
      can_write_record?(Discretion.current_viewer, record, changes, new_record)
    end

    def can_destroy_record?(viewer, record)
      return true unless record.is_a?(Discretion::DiscreetModel)
      return true if Discretion.currently_acting_as?(Discretion::OMNIPOTENT_VIEWER)

      record.respond_to?(:can_destroy?, true) ?
        record.send(:can_destroy?, viewer) : can_write_record?(viewer, record, {}, false)
    end

    def current_viewer_can_destroy_record?(record)
      can_destroy_record?(Discretion.current_viewer, record)
    end
  end
end

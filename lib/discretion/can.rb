module Discretion
  class << self
    def can_see_record?(viewer, record)
      return true unless record.is_a?(Discretion::DiscreetModel)
      return true if Discretion::OMNISCIENT_VIEWER == viewer || Discretion::OMNIPOTENT_VIEWER == viewer

      record.send(:can_see?, viewer)
    end

    def current_viewer_can_see_record?(record)
      can_see_record?(Discretion.current_viewer, record)
    end

    def can_write_record?(viewer, record, changes, new_record)
      return true unless record.is_a?(Discretion::DiscreetModel)
      return true if Discretion::OMNIPOTENT_VIEWER == viewer

      record.respond_to?(:can_write?, true) ?
        record.send(:can_write?, viewer, changes, new_record) :
        can_see_record?(viewer, record)
    end

    def current_viewer_can_write_record?(record, changes, new_record)
      can_write_record?(Discretion.current_viewer, record, changes, new_record)
    end
  end
end

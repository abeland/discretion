module Discretion
  class << self
    def in_console?
      defined?(Rails::Console).present?
    end

    def in_test?
      Rails.env.test?
    end

    def try_to(viewer)
      orig_viewer = Discretion.current_viewer
      Discretion.set_current_viewer(viewer)
      yield
      true
    rescue Discretion::CannotSeeError, Discretion::CannotWriteError
      false
    ensure
      Discretion.set_current_viewer(orig_viewer)
    end

    def omnisciently
      # Calling Proc.new will create a Proc from the implicitly given block to
      # the current method.
      # cf. http://ruby-doc.org/core-2.5.0/Proc.html#method-c-new
      acting_as(Discretion::OMNISCIENT_VIEWER, &Proc.new)
    end

    def omnipotently
      # Calling Proc.new will create a Proc from the implicitly given block to
      # the current method.
      # cf. http://ruby-doc.org/core-2.5.0/Proc.html#method-c-new
      acting_as(Discretion::OMNIPOTENT_VIEWER, &Proc.new)
    end

    private

    def acting_as(as)
      orig_as = Discretion.currently_acting_as
      Discretion.set_currently_acting_as(as)
      yield
    ensure
      Discretion.set_currently_acting_as(orig_as)
    end
  end
end

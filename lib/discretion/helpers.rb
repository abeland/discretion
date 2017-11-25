module Discretion
  class << self
    def in_console?
      defined?(Rails::Console)
    end

    def in_test?
      Rails.env.test?
    end

    def can_see_models?(viewer, *models)
      models.all? { |model| Discretion.can_see_record?(viewer, model) }
    end

    def can_write_models?(viewer, *models)
      models.all? { |model| Discretion.can_write_record?(viewer, model) }
    end
  end
end

module Discretion
  class << self
    def in_console?
      defined?(Rails::Console)
    end

    def in_test?
      Rails.env.test?
    end

    def can_see_records?(viewer, *records)
      records.all? { |record| Discretion.can_see_record?(viewer, record) }
    end

    def can_write_records?(viewer, *records)
      records.all? { |record| Discretion.can_write_record?(viewer, record) }
    end
  end
end

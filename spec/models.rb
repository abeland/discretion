require 'active_record'
require 'discretion'

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Staff < ApplicationRecord
  self.table_name = 'staff'
  has_many :donations, dependent: :destroy

  use_discretion

  private

  def can_see?(viewer)
    return true if Discretion.in_test?

    # Only Staff of the organization can see Staff members.
    viewer.is_a?(Staff)
  end
end

class Donor < ApplicationRecord
  has_many :donations, dependent: :destroy

  use_discretion

  private

  def can_see?(viewer)
    return true if Discretion.in_test?

    # Only the Donor herself or Staff of the organization can see the Donor.
    viewer.is_a?(Staff) || viewer&.id == id
  end
end

class Donation < ApplicationRecord
  belongs_to :recipient, class_name: 'Staff', foreign_key: 'staff_id'
  belongs_to :donor, class_name: 'Donor', foreign_key: 'donor_id'

  use_discretion

  private

  def can_see?(viewer)
    return true if Discretion.in_test?

    # Only the Donor for the donation or the Staff recipient
    # of the donation can see the Donation.
    viewer&.id == donor.id || viewer&.id == recipient.id
  end

  def can_write?(viewer)
    return true if Discretion.in_test?

    # Only the recipient can edit existing donations.
    viewer&.id == recipient.id
  end
end

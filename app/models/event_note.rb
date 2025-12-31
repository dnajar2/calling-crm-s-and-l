class EventNote < ApplicationRecord
  belongs_to :event
  belongs_to :user

  validates :content, presence: true
  validates :visible_to_client, inclusion: { in: [true, false] }
  validates :follow_up_required, inclusion: { in: [true, false] }

  scope :visible_to_client, -> { where(visible_to_client: true) }
  scope :follow_up_required, -> { where(follow_up_required: true) }
  scope :ordered_by_occurred_at, -> { order(occurred_at: :desc, created_at: :desc) }

  # Set occurred_at to current time if not provided
  before_validation :set_occurred_at, on: :create

  private

  def set_occurred_at
    self.occurred_at ||= Time.current
  end
end

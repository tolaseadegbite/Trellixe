class EventSeries < ApplicationRecord
  belongs_to :owner, polymorphic: true

  has_many :events, dependent: :destroy
  has_many :tagged_event_series, dependent: :destroy
  has_many :tags, through: :tagged_event_series

  attribute :recurrence_rule, :json, default: -> { {} }

  attr_accessor :recurrence_frequency, :day_of_week

  after_initialize :derive_virtual_attributes, if: :persisted?
  before_validation :compile_recurrence_rule

  validates :name, :starts_at, :duration_in_minutes, presence: true

  scope :active, -> { where(cancelled_series: false) }

  def occurrences(from:, to:)
    return [] if recurrence_rule.blank?

    to = [ to, ends_on&.end_of_day ].compact.min
    schedule = ::IceCube::Schedule.new(starts_at.to_time, duration: duration_in_minutes * 60)
    schedule.add_recurrence_rule(::IceCube::Rule.from_hash(recurrence_rule.deep_symbolize_keys))
    schedule.occurrences_between(from.to_time, to.to_time)
  end

  def generate_occurrence!(occurrence_time)
    return if cancelled_series?
    return if ends_on.present? && occurrence_time.to_date > ends_on
    return if events.exists?(starts_at: occurrence_time.beginning_of_day..occurrence_time.end_of_day)

    transaction do
      event = events.create!(
        name: name,
        starts_at: occurrence_time,
        duration_in_minutes: duration_in_minutes,
        owner: owner
      )

      if tag_ids.any?
        Contact.joins(:tags).where(tags: { id: tag_ids }).distinct.find_each do |contact|
          event.invitations.create!(contact: contact, status: :invited)
        end
      end

      event
    end
  end

  private

  def derive_virtual_attributes
    return if recurrence_rule.blank?

    rule_hash = recurrence_rule.with_indifferent_access

    self.recurrence_frequency = case rule_hash[:rule_type]
    when /WeeklyRule/ then "weekly"
    when /MonthlyRule/ then "monthly"
    end

    days = rule_hash.dig(:validations, :day)
    self.day_of_week = days.map(&:to_s) if days.present?
  end

  def compile_recurrence_rule
    if recurrence_frequency.blank?
      self.recurrence_rule = {}
      return
    end

    rule = case recurrence_frequency
    when "weekly"  then ::IceCube::Rule.weekly
    when "monthly" then ::IceCube::Rule.monthly
    else return
    end

    if day_of_week.present?
      days = day_of_week.reject(&:blank?).map(&:to_i)
      rule.day(*days) if days.any?
    end

    self.recurrence_rule = rule.to_hash
  end
end

class GenerateSeriesOccurrencesJob < ApplicationJob
  queue_as :default

  def perform
    Account.find_each do |account|
      account.event_series.active
             .where("starts_at <= ?", Time.current)
             .where("ends_on IS NULL OR ends_on >= ?", Date.current)
             .find_each do |series|
        to = [ series.ends_on&.end_of_day, 60.days.from_now ].compact.min
        next_occurrence = series.occurrences(from: Time.current, to: to).first
        next if next_occurrence.nil?
        next if series.events.exists?(
          starts_at: next_occurrence.beginning_of_day..next_occurrence.end_of_day
        )

        series.generate_occurrence!(next_occurrence)
      end
    end
  end
end

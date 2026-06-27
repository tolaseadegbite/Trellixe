class TaggedEventSeries < ApplicationRecord
  belongs_to :tag
  belongs_to :event_series
end

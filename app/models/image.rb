class Image < ApplicationRecord
  enum :status, [ :pending, :in_progress, :complete, :error ]

  # serialize :keywords, Array
  # serialize :keywords, JSON

  # Returns the keywords as an array.
  def keywords_array
    JSON.parse(keywords) rescue []
  end
end

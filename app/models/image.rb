class Image < ApplicationRecord
  # Returns the keywords as an array.
  def keywords_array
    JSON.parse(keywords) rescue []
  end
end

module Entities
  class Image < Grape::Entity
    expose :id
    expose :prompt
    expose :keywords do |image, _options|
      image.keywords_array
    end
    expose :image_name
    expose :image_url do |image, _options|
      image.image_name ? "https://#{ENV['S3_BUCKET']}.s3.amazonaws.com/#{image.image_name}" : ''
    end
    expose :created_at, format_with: :date_format
    expose :status
  end
end

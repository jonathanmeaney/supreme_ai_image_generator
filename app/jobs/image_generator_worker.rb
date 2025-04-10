# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'securerandom'
require 'fileutils'

class ImageGeneratorWorker
  include Sidekiq::Job

  def perform(keywords)
    Rails.logger.info "Job started with keywords: #{keywords.inspect}"

    # Step 1: Generate a detailed image prompt using ChatGPT API
    Rails.logger.info 'Generating prompt from keywords...'
    prompt = generate_prompt(keywords)
    unless prompt
      Rails.logger.error 'Failed to generate prompt from ChatGPT API.'
      return
    end
    Rails.logger.info "Generated prompt: #{prompt}"

    # Step 2: Call OpenAI's DALL·E API with the generated prompt
    Rails.logger.info 'Generating image with prompt...'
    image_data = generate_image(prompt)
    unless image_data
      Rails.logger.error 'Failed to generate image from DALL·E API.'
      return
    end
    Rails.logger.info "Image data received (size: #{image_data.bytesize} bytes)"

    # Step 3: Store the image file on S3 (or locally) and create an Image model record.
    Rails.logger.info 'Storing image...'
    storage_url = store_image(image_data, prompt, keywords)
    if storage_url
      Rails.logger.info "Image generated and stored at: #{storage_url}"
    else
      Rails.logger.error 'Failed to store image.'
    end
  rescue StandardError => e
    Rails.logger.error "An unexpected error occurred in perform: #{e.message}\n#{e.backtrace.join("\n")}"
  end

  private

  # Generate an image prompt using ChatGPT API from keywords.
  def generate_prompt(keywords)
    Rails.logger.debug "Preparing ChatGPT API request with keywords: #{keywords.join(', ')}"
    uri = URI('https://api.openai.com/v1/chat/completions')
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req['Authorization'] = "Bearer #{ENV['OPENAI_API_KEY']}"

    messages = [
      { 'role' => 'system',
        'content' => 'You are a creative assistant that turns a list of keywords into a detailed, imaginative image prompt. Ensure the prompt is no longer than 1000 characters.' },
      { 'role' => 'user',
        'content' => "Generate an image prompt using these keywords: #{keywords.join(', ')}. Ensure the prompt is vivid, descriptive, and utilizes all keywords." }
    ]
    req.body = { model: 'gpt-3.5-turbo', messages: messages }.to_json

    Rails.logger.debug 'Sending request to ChatGPT API...'
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    Rails.logger.debug "ChatGPT API response code: #{response.code}"
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      prompt_text = data['choices'].first['message']['content']
      Rails.logger.debug "Raw prompt received: #{prompt_text}"
      prompt_text.strip
    else
      Rails.logger.error "ChatGPT API call failed: #{response.code} #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Error in generate_prompt: #{e.message}\n#{e.backtrace.join("\n")}"
    nil
  end

  # Generate an image using OpenAI's DALL·E API.
  def generate_image(prompt)
    Rails.logger.debug "Preparing DALL·E API request with prompt: #{prompt}"
    uri = URI('https://api.openai.com/v1/images/generations')
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req['Authorization'] = "Bearer #{ENV['OPENAI_API_KEY']}"

    # Use custom parameters as needed (size, model, quality)
    req.body = { prompt: prompt, n: 1, size: '1792x1024', model: 'dall-e-3', quality: 'hd' }.to_json

    Rails.logger.debug 'Sending request to DALL·E API...'
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    Rails.logger.debug "DALL·E API response code: #{res.code}"
    if res.is_a?(Net::HTTPSuccess)
      response_data = JSON.parse(res.body)
      generated_url = response_data['data'].first['url']
      Rails.logger.info "Generated image URL from DALL·E: #{generated_url}"

      Rails.logger.debug 'Downloading generated image...'
      image_uri = URI(generated_url)
      image_response = Net::HTTP.get_response(image_uri)
      if image_response.is_a?(Net::HTTPSuccess)
        Rails.logger.info 'Image downloaded successfully.'
        image_response.body
      else
        Rails.logger.error "Failed to download the generated image from #{generated_url}"
        nil
      end
    else
      Rails.logger.error "DALL·E API request failed with status: #{res.code} - #{res.body} - Failed Prompt: #{prompt}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Error in generate_image: #{e.message}\n#{e.backtrace.join("\n")}"
    nil
  end

  # Store the image file on S3 and create an Image model record with prompt and keywords.
  def store_image(image_data, prompt, keywords)
    storage_mode = ENV.fetch('STORAGE_MODE', 's3') # default to s3 if not set
    image_key = "#{SecureRandom.uuid}.jpg"

    image_record = Image.create!(
      prompt: prompt,
      keywords: keywords.to_json,
      image_name: image_key
    )
    Rails.logger.info "Image record created with ID #{image_record.id}"

    if storage_mode == 'local'
      Rails.logger.info 'Storing image locally...'
      local_dir = Rails.root.join('public', 'uploads')
      Rails.logger.debug "Creating directory: #{local_dir}"
      FileUtils.mkdir_p(local_dir) unless Dir.exist?(local_dir)

      image_path = File.join(local_dir, image_key)
      Rails.logger.debug "Writing image to #{image_path}"
      File.write(image_path, image_data)

      # Instead of storing prompt and keywords on disk, we save them in the Image model
      local_url = "http://localhost:4567/uploads/#{image_key}"
      Rails.logger.info "Local image stored at #{local_url}"
      local_url
    else
      Rails.logger.info 'Storing image to S3...'
      s3_client = Aws::S3::Client.new(
        region: ENV['AWS_REGION'],
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
      )
      bucket = ENV['S3_BUCKET']

      # Upload the image file to S3
      Rails.logger.debug "Uploading image to S3 key: #{image_key}"
      s3_client.put_object(bucket: bucket, key: image_key, body: image_data, acl: 'public-read')
      s3_url = "https://#{bucket}.s3.amazonaws.com/#{image_key}"
      Rails.logger.info "Image stored on S3 at #{s3_url}"
      s3_url
    end
  rescue StandardError => e
    Rails.logger.error "Error in store_image: #{e.message}\n#{e.backtrace.join("\n")}"
    nil
  end

  # Alternative method for S3 upload (if needed)
  def upload_to_s3(image_data)
    Rails.logger.info 'Uploading image to S3 (alternative method)...'
    s3_client = Aws::S3::Client.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
    bucket = ENV['S3_BUCKET']
    s3_key = "#{SecureRandom.uuid}.jpg"
    s3_client.put_object(bucket: bucket, key: s3_key, body: image_data, acl: 'public-read')
    s3_url = "https://#{bucket}.s3.amazonaws.com/#{s3_key}"
    Rails.logger.info "Image uploaded to S3 at #{s3_url}"
    s3_url
  rescue StandardError => e
    Rails.logger.error "S3 upload failed: #{e.message}\n#{e.backtrace.join("\n")}"
    nil
  end
end

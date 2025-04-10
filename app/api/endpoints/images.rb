module Endpoints
  class Images < Grape::API
    resource :images do
      desc "List generated images and associated metadata"
      get do
        begin
          s3_client = Aws::S3::Client.new(
            region: ENV["AWS_REGION"],
            access_key_id: ENV["AWS_ACCESS_KEY_ID"],
            secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
          )
          bucket = ENV["S3_BUCKET"]

          # List all objects from the bucket
          response = s3_client.list_objects_v2(bucket: bucket)

          image_sets = {}
          if response.contents
            response.contents.each do |object|
              # Expect keys to be in the format "unique_id/filename"
              parts = object.key.split("/")
              next unless parts.size >= 2

              unique_id = parts[0]
              filename  = parts[1]
              image_sets[unique_id] ||= {}

              case filename
              when "image.jpg"
                # Rename key "image.jpg" to "image"
                image_sets[unique_id]["image"] = "https://#{bucket}.s3.amazonaws.com/#{object.key}"
              when "prompt.txt"
                obj = s3_client.get_object(bucket: bucket, key: object.key)
                image_sets[unique_id]["prompt"] = obj.body.read
              when "keywords.json"
                obj = s3_client.get_object(bucket: bucket, key: object.key)
                image_sets[unique_id]["keywords"] = JSON.parse(obj.body.read)
              end
            end
          end

          { image_sets: image_sets }
        rescue StandardError => e
          error!({ error: e.message }, 500)
        end
      end

      desc "Enqueue image generation job with random keywords"
      post do
        # Load JSON data from files using Rails.root.join to get the absolute paths
        people = JSON.parse(File.read("lib/data/people.json"))
        people_addons = JSON.parse(File.read("lib/data/people-addons.json"))
        people_adjectives = JSON.parse(File.read("lib/data/people-adjectives.json"))
        places = JSON.parse(File.read("lib/data/places.json"))
        things = JSON.parse(File.read("lib/data/things.json"))

        # Choose 1 or 2 random people
        num_people = [ 1, 2 ].sample
        chosen_people = people.sample(num_people)

        # Enhance each person with a random adjective and addon
        people = chosen_people.map do |person|
          "#{people_adjectives.sample} #{person} with #{people_addons.sample}"
        end

        # Choose 1 random place
        chosen_place = places.sample

        # Choose 1 to 3 random things
        num_things = rand(1..3)
        chosen_things = things.sample(num_things)

        # Combine the keywords
        keywords = people + [ chosen_place ] + chosen_things

        # Enqueue the background job with the generated keywords
        jid = ImageGeneratorWorker.perform_async(keywords)

        { job_id: jid, message: "Image generation job enqueued.", keywords: keywords }
      end
    end
  end
end

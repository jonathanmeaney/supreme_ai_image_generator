module Endpoints
  class Images < Grape::API
    resource :images do
      desc 'List generated images and associated metadata'
      get do
        images = Image.order(created_at: :desc)
        present images, with: Entities::Image
      end

      desc 'Enqueue image generation job with random keywords'
      post do
        # Load JSON data from files using Rails.root.join to get the absolute paths
        people = JSON.parse(File.read('lib/data/people.json'))
        people_addons = JSON.parse(File.read('lib/data/people-addons.json'))
        people_adjectives = JSON.parse(File.read('lib/data/people-adjectives.json'))
        places = JSON.parse(File.read('lib/data/places.json'))
        things = JSON.parse(File.read('lib/data/things.json'))
        adjectives = JSON.parse(File.read('lib/data/adjectives.json'))

        # Choose 1 to 3 random people
        chosen_people = people.sample(rand(1..3))

        # Enhance each person with a random adjective and addon
        people = chosen_people.map do |person|
          "#{people_adjectives.sample} #{person} with #{people_addons.sample}"
        end

        # Choose 1 random place
        chosen_place = "#{adjectives.sample} #{places.sample}"

        # Choose 1 to 3 random things
        chosen_things = things.sample(rand(1..3))

        # Combine the keywords
        keywords = [ people.join(' and ') ] + [ chosen_place ] + chosen_things

        # Enqueue the background job with the generated keywords
        jid = ImageGeneratorWorker.perform_async(keywords)

        { job_id: jid, message: 'Image generation job enqueued.', keywords: keywords }
      end
    end
  end
end

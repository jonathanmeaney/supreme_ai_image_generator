module Endpoints
  class Images < Grape::API
    resource :images do
      desc 'List generated images and associated metadata, paginated'
      params do
        optional :page,      type: Integer, desc: 'Page number',    default: 1
        optional :per_page,  type: Integer, desc: 'Items per page', default: 20
      end
      get do
        page     = params[:page]
        per_page = params[:per_page]

        # fetch & paginate
        images = Image.order(created_at: :desc)
                      .page(page)
                      .per(per_page)

        # represent with your Grape Entity
        payload = {
          images: Entities::Image.represent(images),
          pagination: {
            total_count:  images.total_count,
            total_pages:  images.total_pages,
            current_page: images.current_page,
            per_page:     images.limit_value
          }
        }

        present payload
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

        # create the record, defaults to status: :pending
        image = Image.create!(
          keywords: keywords.to_json,
          prompt: nil,
          image_name: nil
        )

        # enqueue the worker, passing the new record’s id
        ImageGeneratorWorker.perform_async(image.id)

        # return the image’s id (not the Sidekiq jid)
        { image_id: image.id, status: image.status, keywords: }
      end

      route_param :id, type: Integer do
        desc 'Fetch a single Image by its ID'
        get do
          image = Image.find_by(id: params[:id])
          error!({ error: 'Not Found' }, 404) unless image
          present image, with: Entities::Image
        end
      end
    end
  end
end

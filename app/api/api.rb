class API < Grape::API
  prefix :api
  format :json

  # helpers Authentication
  helpers APIHelpers

  rescue_from :all do |e|
    error!({ error: e.message }, 500)
  end

  # before { authenticate! }

  # mount Endpoints::Authentication
  # mount Endpoints::Users
  # mount Endpoints::Profile
  mount Endpoints::Images
end

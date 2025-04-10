web: bundle exec ruby app.rb -p 4567 -o 0.0.0.0
worker: bundle exec sidekiq -r ./app/jobs/image_generator_worker.rb

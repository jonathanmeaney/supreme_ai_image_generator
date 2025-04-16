# docker build -t supreme_ai_image_generator:latest .
# docker tag supreme_ai_image_generator:latest jonathanmeaney/supreme_ai_image_generator:latest
# docker push jonathanmeaney/supreme_ai_image_generator:latest

docker buildx build --platform linux/amd64 -t jonathanmeaney/supreme_ai_image_generator:latest --push .

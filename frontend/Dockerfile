FROM node:22-alpine

WORKDIR /app

# Copy only package manifests, install deps
COPY package.json package-lock.json ./
RUN npm ci

# Copy the rest of your frontend code
COPY . .

# tell Docker that the app listens on Vite's default port
EXPOSE 5173

CMD ["npm", "run", "dev"]

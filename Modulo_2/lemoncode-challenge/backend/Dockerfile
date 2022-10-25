FROM node:16.18.0-alpine

WORKDIR /app

COPY ["package.json", "package-lock.json*", "./"]

RUN npm install --silent

COPY . .

EXPOSE 5000

CMD npm start

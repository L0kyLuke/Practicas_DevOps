# Ejercicio 1 (NOTA: No funciona el Front)
### Creación de la red
docker network create lemoncode-challenge

### Creación del volumen
docker volume create lemon-volume

### Ejecución del contenedor de MongoDB
docker run -d --name some-mongo --network lemoncode-challenge -p 27017:27017 --mount source=lemon-volume,target=/data/db mongo

### Modificación del fichero config.ts del backend
url: process.env.DATABASE_URL || 'mongodb://some-mongo:27017'

### Creación del Dockerfile para el backend de Node.js
FROM node:16

WORKDIR /app

COPY ["package.json", "package-lock.json*", "./"]

RUN npm install

COPY . .

CMD npm start

### Creación de la imagen del backend
docker build -t backend .

### Ejecución del contenedor del backend
docker run -d --name mybackend --network lemoncode-challenge backend

### Se agregan registros a la base de datos a través del backend
docker exec -it mybackend bash

curl -d '{"Name":"Devops"}' -H "Content-Type: application/json" -X POST http://localhost:5000/api/topics

curl -d '{"Name":"K8s"}' -H "Content-Type: application/json" -X POST http://localhost:5000/api/topics

curl -d '{"Name":"Docker"}' -H "Content-Type: application/json" -X POST http://localhost:5000/api/topics

curl -d '{"Name":"Prometheus"}' -H "Content-Type: application/json" -X POST http://localhost:5000/api/topics

### Modificación del fichero server.js del frontend
const LOCAL = 'http://topics-api:5000/api/topics';

### Creación del Dockerfile para el frontend de Node.js
FROM node:16

WORKDIR /app

COPY ["package.json", "package-lock.json*", "./"]

RUN npm install

COPY . .

EXPOSE 3000

CMD npm start

### Creación de la imagen del frontend
docker build -t frontend .

### Ejecución del contenedor del frontend
docker run -d --name myfrontend  -p 8080:3000 -e API_URI=http://topics-api:5000/api/topics --network lemoncode-challenge frontend

# Ejercicio 2 (NOTA: a la espera de solucionar el 1)
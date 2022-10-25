# Ejercicio 1 (NOTA: No funciona el Front)
## Creación de la red
```bash
docker network create lemoncode-challenge
```
## Contenedor MongoDB

### Creación del volumen
```bash
docker volume create lemon-volume
```
### Ejecución del contenedor de MongoDB
```bash
docker run -d --name some-mongo --network lemoncode-challenge --mount source=lemon-volume,target=/data/db mongo
```
## Contenedor del Backend

### Modificación del fichero config.ts del backend
```diff
if (process.env.NODE_ENV === 'development') {
    require('dotenv').config;
}

export default {
    database: {
-        url: process.env.DATABASE_URL || 'mongodb://localhost:27017',
+        url: process.env.DATABASE_URL || 'mongodb://some-mongo:27017',
        name: process.env.DATABASE_NAME || 'TopicstoreDb'
    },
    app: {
        host: process.env.HOST || 'localhost',
        port: +process.env.PORT || 5000
    }
}
```
### Creación del Dockerfile para el backend de Node.js
```Dockerfile
FROM node:16.18.0-alpine

WORKDIR /app

COPY ["package.json", "package-lock.json*", "./"]

RUN npm install

COPY . .

EXPOSE 5000

CMD npm start
```
### Creación de la imagen del backend
docker build -t backend .

### Ejecución del contenedor del backend
docker run -d --name topics-api --network lemoncode-challenge backend

### Se agregan registros a la base de datos a través del backend
docker exec -it topics-api bash

curl -d '{"Name":"Devops"}' -H "Content-Type: application/json" -X POST http://localhost:5000/api/topics

curl -d '{"Name":"K8s"}' -H "Content-Type: application/json" -X POST http://localhost:5000/api/topics

curl -d '{"Name":"Docker"}' -H "Content-Type: application/json" -X POST http://localhost:5000/api/topics

curl -d '{"Name":"Prometheus"}' -H "Content-Type: application/json" -X POST http://localhost:5000/api/topics

### Creación del Dockerfile para el frontend de Node.js
FROM node:16.18.0-alpine

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
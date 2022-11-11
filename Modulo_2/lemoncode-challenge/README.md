# Ejercicio 1
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
### Se agregan registros a la base de datos
```bash
docker exec -it some-mongo mongosh

> use TopicstoreDb

> db.Topics.insert({Name:"Docker"})

> db.Topics.insert({Name:"Kubernetes"})
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

### Modificación del fichero Properties/launchSettings.json del backend
```diff
{
  "$schema": "http://json.schemastore.org/launchsettings.json",
  "iisSettings": {
    "windowsAuthentication": false,
    "anonymousAuthentication": true,
    "iisExpress": {
      "applicationUrl": "http://localhost:49704",        
      "sslPort": 0
    }
  },
  "profiles": {
    "IIS Express": {
      "commandName": "IISExpress",
      "launchBrowser": true,
      "launchUrl": "weatherforecast",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    },
    "backend": {
      "commandName": "Project",
      "launchBrowser": true,
      "launchUrl": "weatherforecast",
-      "applicationUrl": "http://localhost:5000",      
+      "applicationUrl": "http://0.0.0.0:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
```
### Creación del Dockerfile para el backend de .Net
```Dockerfile
FROM mcr.microsoft.com/dotnet/sdk:3.1

WORKDIR /app

COPY . .

CMD ["dotnet", "run"]
```
### Creación de la imagen del backend
```bash
docker build -t backend .
```
### Ejecución del contenedor del backend
```bash
docker run -d --name topics-api --network lemoncode-challenge backend
```
## Contenedor del Frontend

### Creación del Dockerfile para el frontend de Node.js
```Dockerfile
FROM node:16.18.0-alpine

WORKDIR /app

COPY ["package.json", "package-lock.json*", "./"]

RUN npm install

COPY . .

EXPOSE 3000

CMD npm start
```
### Creación de la imagen del frontend
```bash
docker build -t frontend .
```
### Ejecución del contenedor del frontend
```bash
docker run -d --name myfrontend  -p 8080:3000 -e API_URI=http://topics-api:5000/api/topics --network lemoncode-challenge frontend
```
# Ejercicio 2
### Creación del docker-compose.yml
```yml
version: "3.9" 
services:
   db:
     image: mongo:latest
     container_name: some-mongo
     volumes:
       - lemon-volume:/data/db
     restart: always
     networks: 
        - lemoncode-challenge
   back:
     depends_on:
       - db
     build: ./backend
     container_name: topics-api
     restart: always
     networks: 
       - lemoncode-challenge
   front:
     depends_on:
       - back
     build: ./frontend
     container_name: myfront
     ports:
       - "8080:3000"
     restart: always
     environment:
       API_URI: http://topics-api:5000/api/topics
     networks: 
       - lemoncode-challenge       
volumes:
    lemon-volume: 
networks:
    lemoncode-challenge: 
```
### Levantamos el entorno
```bash
docker-compose up -d
```
### Paramos la aplicación y eliminamos el entorno
```bash
docker-compose stop # Solo detiene la aplicación

docker-compose down #Detiene la aplicación y elimina los contenedores
docker-compose down --rmi all #Detiene la aplicación, elimina los contenedores y las imágenes
```
**_Nota:_** Para eliminar volúmenes que no se usen. Con los contenedores de nuestra aplicación activos, ejecutar
```bash
docker volume prune -f  
```
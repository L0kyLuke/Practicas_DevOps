# Ejercicio 1. Monolito en memoria

## Paso 1. Crear todo-app
Creamos la imagen a partir del `Dockerfile`
```shell
docker build . -t xopiploky/todo-app
```
Subimos la imagen a mi repositorio de DockerHub
```
docker push xopiploky/todo-app
```
Creamos el fichero `Yaml` del `Deployment` con las variables de entorno
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-app
spec:
  selector:
    matchLabels:
      app: todo-app
  template:
    metadata:
      labels:
        app: todo-app
    spec:
      containers:
      - env:
        - name: NODE_ENV
          value: production
        - name: PORT
          value: "3000"
        image: xopiploky/todo-app
        name: todo-app    
        ports:
        - containerPort: 3000
status: {}
```
Creamos el `Deployment` a partir del fichero `Yaml`
```shell
kubectl apply -f deployment.yaml
```
## Paso 2. Acceder a todo-app desde fuera del clúster
Creo el fichero `Yaml` del servicio `LoadBalancer`
```yaml
# svc.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: todo-app
  name: todo-app-svc
spec:
  ports:
  - port: 3000
    protocol: TCP
    targetPort: 3000
  selector:
    app: todo-app
  type: LoadBalancer 
```
Creamos el servicio `LoadBalancer` a partir del fichero `Yaml`
```shell
kubectl apply -f svc.yaml
```
Creamos el túnel para probar el `LoadBalancer`
```shell
minikube tunnel
```
Verifico la IP Externa del servicio
```shell
kubectl get svc
```
Abro la aplicación a través de esa IP Externa y el puerto seleccionado

# Ejercicio 2. Monolito

## Paso 1. Crear una capa de persistencia de datos
Creamos el fichero `yaml` del `ConfigMap` con las variables de entorno necesarias para el ejercicio
```yaml
# cm-bd.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cm-bd
data:
  NODE_ENV: develop
  PORT: "3000"
  DB_HOST: localhost
  DB_USER: postgres
  DB_PASSWORD: postgres
  DB_PORT: "5432"
  DB_NAME: todos_db
  DB_VERSION: "10.4"
```
Creamos el `ConfigMap` a partir del fichero `Yaml`
```shell
kubectl apply -f cm-bd.yaml
```
Creamos el fichero `yaml` de `StorageClass` para el ejercicio
```yaml
# sc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
  name: ejercicio
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Delete
volumeBindingMode: Immediate
```
Creamos la `StorageClass` a partir del fichero `Yaml`
```shell
kubectl apply -f sc.yaml
```
Creamos el `yaml` del `PersistentVolume`
```yaml
# pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mypv
spec:
  storageClassName: ejercicio
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 1Gi
  hostPath:
    path: /data/pv001
```
Creamos el `PersistentVolume` a partir del fichero `Yaml`
```shell
kubectl apply -f pv.yaml
```
Creamos el fichero `yaml` del `PersistentVolumeClaim`
```yaml
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mypvclaim
spec:
  storageClassName: ejercicio
  accessModes:
    - ReadWriteOnce
  resources:
    requests: 
      storage: 500Mi
```
Creamos el `PersistentVolumeClaim` a partir del fichero `yaml`
```shell
kubectl apply -f pvc.yaml
```
Creamos un fichero `yaml` de un svc de `ClusterIP` para el `StatefulSet`
```yaml
# svc-bd.yaml
apiVersion: v1
kind: Service
metadata:
  name: ss-svc
spec:
  selector:
    app: ss
  ports:
  - port: 5432
```
Creamos el svc a partir del fichero `yaml`
```shell
kubectl apply -f svc-bd.yaml
```
Creamos el fichero `yaml` del `StatefulSet`
```yaml
#ss.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ss
spec:
  serviceName: ss
  selector:
    matchLabels:
      app: ss
  template:
    metadata:
      labels:
        app: ss
    spec:
      volumes:
      - name: external
        persistentVolumeClaim:
          claimName: mypvclaim   
      containers:
      - image: postgres:10.4
        name: postgres    
        ports:
        - containerPort: 5432
        envFrom:
          - configMapRef:
              name: cm-bd
        volumeMounts:
          - mountPath: /var/lib/postgresql/data
            name: external
```
Creamos el `StatefulSet` a partir del fichero `yaml`
```shell
kubectl apply -f ss.yaml
```
Verifico el nombre del pod que ha generado el `StatefulSet`
```shell
kubectl get pods
```
Accedo al shell del pod y creo la base de datos
```shell
kubectl exec -it ss-0 -- /bin/sh

# Me autentifico con el usuario "postgres"
psql -U postgres

# Creo la base de datos pegando el contenido de todos_db.sql
```
## Paso 2. Crear todo-app
Creamos la imagen a partir del `Dockerfile`
```shell
docker build . -t xopiploky/todo-app
```
Subimos la imagen a mi repositorio de DockerHub
```
docker push xopiploky/todo-app
```
Creamos el fichero `yaml` del `ConfigMap` con las variables de entorno necesarias todo-app
```yaml
# cm-bd.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cm-app
data:
  NODE_ENV: develop
  PORT: "3000"
  DB_HOST: ss-svc
  DB_USER: postgres
  DB_PASSWORD: postgres
  DB_PORT: "5432"
  DB_NAME: todos_db
  DB_VERSION: "10.4"
```
Creamos el `ConfigMap` a partir del fichero `Yaml`
```shell
kubectl apply -f cm-app.yaml
```
Creamos el fichero `Yaml` del `Deployment` con las variables de entorno
```yaml
#deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-app
spec:
  selector:
    matchLabels:
      app: todo-app
  template:
    metadata:
      labels:
        app: todo-app
    spec:
      containers:
      - image: xopiploky/todo-app:latest
        name: todo-app    
        ports:
        - containerPort: 3000
        envFrom:
          - configMapRef:
              name: cm-app        
status: {}  
```
Creamos el `Deployment` a partir del fichero `Yaml`
```shell
kubectl apply -f deployment.yaml
```
## Paso 3. Acceder a todo-app desde fuera del clúster
Creo el fichero `Yaml` del servicio `LoadBalancer`
```yaml
# svc-app.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: todo-app
  name: todo-app-svc
spec:
  ports:
  - port: 3000
    protocol: TCP
    targetPort: 3000
  selector:
    app: todo-app
  type: LoadBalancer 
```
Creamos el servicio `LoadBalancer` a partir del fichero `Yaml`
```shell
kubectl apply -f svc-app.yaml
```
Creamos el túnel para probar el `LoadBalancer`
```shell
minikube tunnel
```
Verifico la IP Externa del servicio
```shell
kubectl get svc
```
Abro la aplicación a través de esa IP Externa y el puerto seleccionado

# Ejercicio 3. Aplicación distribuida

## Paso 1. Crear todo-front
Creamos la imagen a partir del `Dockerfile`
```shell
docker build . -t xopiploky/todo-front
```
Subimos la imagen a mi repositorio de DockerHub
```
docker push xopiploky/todo-front
```
Creamos el fichero `Yaml` del `Deployment`
```yaml
# deployment-front.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-front
spec:
  selector:
    matchLabels:
      app: todo-front
  template:
    metadata:
      labels:
        app: todo-front
    spec:
      containers:
      - image: xopiploky/todo-front
        name: todo-front   
        ports:
        - containerPort: 80
status: {}
```
Creamos el `Deployment` a partir del fichero `Yaml`
```shell
kubectl apply -f deployment-front.yaml
```
Creamos el fichero `Yaml` del servicio `ClusterIP`
```yaml
# svc-front.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: todo-front
  name: todo-front-svc
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: todo-front

```
Creamos el servicio `ClusterIP` a partir del fichero `Yaml`
```shell
kubectl apply -f svc-front.yaml
```
## Paso 2. Crear todo-api
Creamos la imagen a partir del `Dockerfile`
```shell
docker build . -t xopiploky/todo-api
```
Subimos la imagen a mi repositorio de DockerHub
```
docker push xopiploky/todo-api
```
Creamos el fichero `Yaml` del `Deployment`
```yaml
# deployment-api.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-api
spec:
  selector:
    matchLabels:
      app: todo-api
  template:
    metadata:
      labels:
        app: todo-api
    spec:
      containers:
      - env:
        - name: NODE_ENV
          value: production
        - name: PORT
          value: "3000"      
        image: xopiploky/todo-api
        name: todo-api  
        ports:
        - containerPort: 3000
status: {}
```
Creamos el `Deployment` a partir del fichero `Yaml`
```shell
kubectl apply -f deployment-api.yaml
```
Creamos el fichero `Yaml` del servicio `ClusterIP`
```yaml
# svc-api.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: todo-api
  name: todo-api-svc
spec:
  ports:
  - port: 3000
    targetPort: 3000
  selector:
    app: todo-api
```
Creamos el servicio `ClusterIP` a partir del fichero `Yaml`
```shell
kubectl apply -f svc-api.yaml
```
## Paso 3. Crear un Ingress para acceder a los servicios del clúster
Creamos el fichero `Yaml` del `Ingress`
```yaml
#ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: todo-app
spec:
  ingressClassName: nginx
  rules:
    - host: testjose.xyz
      http:
        paths:        
          - path: /
            pathType: Prefix
            backend:
              service:
                name: todo-front-svc
                port:
                  number: 80    
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: todo-api-svc
                port:
                  number: 3000  
```
Creamos el `Ingress` a partir del fichero `Yaml`
```shell
kubectl apply -f ingress.yaml
```
Obtenemos la IP del `Ingress`
```shell
kubectl get ingress
# Obtenemos IP 192.168.49.2
```
Añadimos `testjose.xyz` al fichero /etc/hosts
```shell
sudo nano /etc/hosts
# Añadimos la linea: 192.168.49.2  testjose.xyz
```
Probamos la conexión a la app
```shell
curl -v testjose.xyz # front
curl -v testjose.xyz/api # back
```
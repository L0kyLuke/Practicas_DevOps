# Ejercicios Jenkins

### Instalar Jenkins en local con dependencias necesarias
Para la ejecución en local construimos una imagen a partir del Dockerfile aportado y ejecutamos el contenedor de Jenkins
```shell
docker run -p 8080:8080 -p 50000:50000 --restart=on-failure jenkins:latest
```
Posteriormente lo cargamos desde localhost:8080 e instalamos los plugins recomendados

## 1. CI/CD de una Java + Gradle

1. Creamos el repositorio en GitHub para la app y lo clonamos
   
    ```
    git clone https://github.com/L0kyLuke/lab_mod_4.git
    ```

2. Posteriormente copiamos `gradle.Dockerfile` y todo el contenido de la carpeta `/calculator` en el directorio raíz del repositorio local

3. Creamos el Jenkinsfile en el directorio raíz del repositorio local
    ```groovy
    pipeline {
        agent any

        stages {
            stage('Checkout') {
                steps {
                    git url: 'https://github.com/L0kyLuke/lab_mod_4.git', branch: 'main'
                }
            }
            stage('Compile') {
                steps {
                    sh './gradlew compileJava'
                }
            }
            stage('Unit Tests') {
                steps {
                    sh './gradlew test'
                }
            }
        }
    }
    ```
4. Le doy permisos de ejecución al fichero `gradlew`
    ```shell
    chmod +x gradlew
    ```

5. Al usar WSL para evitar el error "/usr/bin/env: ‘bash\r’: No such file or directory" al ejecutar `gradlew`, uso el comando `sed` sobre gradlew
    ```shell
    sed -i 's/\r$//' gradlew
    ```

6. Subimos los cambios al repositorio
    ```shell
    git add .
    git commit -m "add files"
    git push
    ```
7. Creamos una nueva pipeline en Jenkins con los siguientes datos y la ejecutamos, comprobando que todo funciona correctamente:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: https://github.com/L0kyLuke/lab_mod_4.git
   - Branch Specifier: */main
   - Script Path: Jenkinsfile
  
## 2. Modificar la pipeline para que utilice la imagen Docker de Gradle como build runner

1. Nos instalamos los plugins de `Docker` y `Docker Pipeline` desde `Dashboard > Manage Jenkins > Plugin Manager > Available plugins`

2. Para usar la imagen `gradle:6.6.1-jre14-openj9` de **Docker** como build runner. Modificamos el `Jenkinsfile` anterior

```diff
pipeline {
+   agent {
+     docker { image 'gradle:6.6.1-jre14-openj9' }
+}
-   agent any

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/L0kyLuke/lab_mod_4.git', branch: 'main'
            }
        }
        stage('Compile') {
            steps {
                sh './gradlew compileJava'
            }
        }
        stage('Unit Tests') {
            steps {
                sh './gradlew test'
            }
        }
    }
}
```
3. Subimos los cambios al repositorio
    ```shell
    git add .
    git commit -m "using docker runner"
    git push
    ```

4. Desde Jenkins volvemos a ejecutar la pipeline con `Build Now` y comprobamos que se ejecuta correctamente

# Ejercicios GitLab 

## 1. CI/CD de una aplicación spring

1. Creamos un nuevo proyecto en blanco en GitLab, lo llamamos `gitlab-springapp` y lo dejamos privado
   
2. Lo clonamos en local
    ```shell
    git clone http://gitlab.local:8888/bootcamp/gitlab-springapp.git
    ```
3. Copiamos los ficheros del proyecto springapp a /gitlab-springapp y subimos los cambios al repositorio
    ```shell
    git add .
    git commit -m "adding files springapp"
    git push
    ```
   
4. Creamos la rama `develop` y nos vamos a `CI/CD > Editor` para crear la siguiente pipeline:
    ```yaml
     # Declaramos las stages 
    stages:
      - maven:build
      - maven:test
      - docker:build
      - deploy

     # Hacemos la compilación de la app
    maven:build:
      image: maven:3.6.3-jdk-8
      stage: maven:build
      script: "mvn clean package"
      artifacts:
        paths:
          - target/*.jar

     # Realizamos el test
    maven:test: 
      image: maven:3.6.3-jdk-8
      stage: maven:test
      script: "mvn verify"
      artifacts:
        paths:
          - target/*.jar

     # Generamos la imagen de Docker a partir del Dockerfile
    docker:build: 
      stage: docker:build
      before_script:
        # Nos logueamos en el Container Registry
        - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY/$CI_PROJECT_PATH 
      script:
        # Hacemos un build usando la URL del Container Registry
        - docker build -t $CI_REGISTRY/$CI_PROJECT_PATH/gitlab-springapp:$CI_COMMIT_SHA .
        # Hacemos push a nuestro Container Registry
        - docker push $CI_REGISTRY/$CI_PROJECT_PATH/gitlab-springapp:$CI_COMMIT_SHA 
      
     # Utilizamos la imagen creada y la hacemos correr en local
    deploy:test:
      stage: deploy
      before_script:
        - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY/$CI_PROJECT_PATH # Nos logueamos en el Container Registry
        - if [[ $(docker ps --filter "name=springapptest" --format '{{.Names}}') == "springapptest" ]]; then  docker rm -f springapptest; else echo "No existe";  fi # Si el contenedor existe lo elimina
      script:
        - docker run --name springapptest -d -p 8081:8080 --rm $CI_REGISTRY/$CI_PROJECT_PATH/gitlab-springapp:$CI_COMMIT_SHA # Hacemos docker run de la imagen que hemos subido, desplegando una aplicación en local en el puerto 8081
      only:
        - develop
      environment: test

     # Hacemos el deploy en producción tras hacer una merge request y ejecutarlo en master lo cual nos desplegará la app en local en el puerto 8080
    deploy:prod:
      stage: deploy
      before_script:
        - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY/$CI_PROJECT_PATH
        - if [[ $(docker ps --filter "name=springapp$" --format '{{.Names}}') == "springapp" ]]; then  docker rm -f springapp; else echo "No existe";  fi
      script:
        - docker run --name springapp -d -p 8080:8080 --rm $CI_REGISTRY/$CI_PROJECT_PATH/gitlab-springapp:$CI_COMMIT_SHA 
      only:
        - master
      environment: prod
    ```
5. Hacemos commit de los cambios y vemos que la pipeline ha funcionado correctamente
   
6. Al estar en la rama *develop* el job ejecutado es el deploy test, por lo que nos conectamos a `localhost:8081`, viendo que la app funciona corréctamente
   
7. Hacemos el `merge request` para pasarlo a la rama *master* yendo a `Merge requests > Create merge request > Create merge request > Merge`
   
8. Tras la `merge request` y haberse ejecutado el job del deploy en producción, ejecutamos la app en `localhost:8080`

## 2. Crear un usuario nuevo y probar que no puede acceder al proyecto anteriormente creado

1. Nos logueamos como *Administrador* y vamos a `Admin > Users > New user` y lo llamamos `ejercicio`
   
2. Vamos al grupo *bootcamp*, a `Group information > Members > Invite members`. Seleccionamos `ejercicio` y le vamos dando los roles:
   
   - `Guest`:
     - **Permite:**
     - **No permite:** hacer commit, ejecutar pipeline manualmente, push and pull del repo, merge request, acceder a la administración del repo
  
   - `Reporter`:
     - **Permite:** pull
     - **No permite:** hacer commit, ejecutar pipeline manualmente, push, merge request, acceder a la administración del repo
  
   - `Developer`:
     - **Permite:** hacer commit desde otra rama que no sea master, ejecutar pipeline manualmente desde otra rama que no sea master, push desde otra rama que no sea master, crear la solicitud de merge request pero no ejecutarla
     - **No permite:** acceder a la administración del repo
  
   - `Maintainer`:
     - **Permite:** hacer commit, ejecutar pipeline manualmente, push and pull del repo, merge request, acceder a la administración del repo
     - **No permite:**

## 3. Crear un nuevo repositorio, que contenga una pipeline, que clone otro proyecto, springapp anteriormente creado

1. Nos logueamos con el usuario `developer1` y creamos un nuevo proyecto en blanco en GitLab, lo llamamos `cloner` y lo dejamos privado

2. Creamos la pipeline que instalará **Git** y clonará el proyecto `gitlab-springapp`. Posteriormente entrará en la carpeta y hará un `ls` para verificar que se ha clonado correctamente
```yml
stages:          
  - clone

build-job:       
  stage: clone
# Instalamos git
  before_script:
  - apk update && apk add git
  - git --version
# Clonamos el repositorio  
  script:
    - git clone http://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.local:8888/bootcamp/gitlab-springapp.git
    - cd gitlab-springapp
    - ls
```

### ¿Qué ocurre si el repo que estoy clonando no estoy cómo miembro?

1. Creamos un nuevo usuario llamado `prueba` que no forma parte del grupo `bootcamp` que es donde se encuentra el proyecto `gitlab-springapp`
   
2. Creamos la pipeline anterior para ver si nos deja clonar el proyecto `gitlab-springapp` con un usuario que no forme parte del grupo `bootcamp`. La pipeline falla, por lo que añadimos nuestro usuario al proyecto, primero con el rol de `Guest` y luego con el de reporter `Reporter`
   
Al ejecutar la pipeline con ambos roles se comprueba, que efectivamente como dice la documentación de **GitLab**, hay que formar parte del *grupo* o *proyecto* para poder clonar el repositorio, y mínimo tener rol de `Reporter`


# Ejercicios GitHub Actions

## 1. Crea un workflow CI para el proyecto de frontend

1. Copiamos *.start-code/hangman-front* al directorio raíz del proyecto
   
2. Creamos el fichero `YAML` que contendrá el workflow que realice la build y unity tests al hacer `pull request`
   
    ```yaml
    name: CI-front
    on:
      pull_request:
        branches: [ main ]

    jobs:
      build:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v3
          - uses: actions/setup-node@v3
            with:
              node-version: 16
              cache: 'npm'
              cache-dependency-path: hangman-front/package-lock.json
          - name: build
            working-directory: ./hangman-front
            run: |
              npm ci
              npm run build --if-present
      test:
        runs-on: ubuntu-latest
        needs: build
        steps:
          - uses: actions/checkout@v3
          - uses: actions/setup-node@v3
            with:
              node-version: 16
          - name: test
            working-directory: ./hangman-front
            run: |
              npm ci
              npm test
    ```

3. Creamos una nueva rama y subimos los cambios a GitHub
   ```sh
   git checkout -b added-workflow 
   git push -u origin added-workflow
   git add .
   git commit -m "added ci file"
   git push
   ```
4. Nos vamos a GitHub a la raíz al principal de nuestro repositorio y seleccionamos **Compare & pull request** y posteriormente **Create pull request**, esto ejecutará el workflow y podemos comprobar su estado desde la opción *Actions* del repositorio
   
5. Tras ejecutar el workflow comprobamos que el test ha dado error, por lo que observamos el log y vemos que en el código de la app hay que cambiar en *hangman-front/src/components/start-game.spec.tsx*
    ```diff
    -   expect(items).toHaveLength(1);
    +   expect(items).toHaveLength(2);
    ```
6. Volvemos a subir los cambios a GitHub y volverá a ejecutarse el workflow, pudiendo comprobar que se ejecuta tanto *build* como el *test* perfectamente

## 2. Crea un workflow CD para el proyecto de frontend

1. Creamos el `Dockerfile` en la raiz del proyecto
   ```dockerfile
    FROM node:lts-alpine as app

    WORKDIR /app

    COPY dist/ .

    COPY package.json .

    COPY package-lock.json .

    ENV NODE_ENV=production

    RUN npm install
   ```
   
2. Creamos el fichero `YAML` que contendrá el workflow que se dispare manualmente y cree la imagen de Docker y la publique en el Container Registry de GitHub
   
    ```yaml
    name: Docker-manual
    on:
      workflow_dispatch:

    jobs:
      build:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v3
          - uses: actions/setup-node@v3
            with:
              node-version: 16
              cache: 'npm'
              cache-dependency-path: hangman-front/package-lock.json
          - name: build
            working-directory: ./hangman-front
            run: |
              npm ci
              npm run build --if-present
      test:
        runs-on: ubuntu-latest
        needs: build
        steps:
          - uses: actions/checkout@v3
          - uses: actions/setup-node@v3
            with:
              node-version: 16
          - name: test
            working-directory: ./hangman-front
            run: |
              npm ci
              npm test

      login-build-push:
        runs-on: ubuntu-latest
        needs: test
        steps:
          -
            name: Login to GitHub Container Registry
            uses: docker/login-action@v2
            with:
              registry: ghcr.io
              username: ${{ github.repository_owner }}
              password: ${{ secrets.GITHUB_TOKEN }}   
          -
            name: Set up Docker Buildx
            uses: docker/setup-buildx-action@v2    
          -
            name: Build and push
            uses: docker/build-push-action@v4
            env:
              REPOSITORY: "gh-actions"
            with:
              context: "{{defaultContext}}:hangman-front"
              push: true
              tags: ghcr.io/l0kyluke/gh-actions:latest
    ```

3. Subimos los cambios
   ```sh
   git add .
   git commit -m "exercise 2"
   git push
   ```
4. Desde nuestro repositorio en **GitHub** ejecutamos la *GitHub Action* de forma manual

## 3. Crea un workflow que ejecute tests e2e

1. Creamos un nuevo repositorio en **GitHub** llamado *gh-e2e* y lo clonamos al local
    ```sh
    git clone https://github.com/L0kyLuke/gh-e2e.git
    ```
2. Copiamos el contenido de la carpeta *hangman-e2e/e2e/* al directorio raíz y comiteamos los cambios
    ```sh
    git add .
    git commit -m "adding files"
    git push
    ```
3. Creamos el `YAML` con el workflow que ejecute los tests usando `Cypress action`
    ```yml
    name: End-to-end tests
    on:
      push:
    jobs:
      build:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v3
          - uses: actions/setup-node@v3
            with:
              node-version: 16
              cache: 'npm'
              cache-dependency-path: ./package-lock.json
          - name: build
            working-directory: ./
            run: |
              npm ci
              npm run build --if-present
          - uses: actions/upload-artifact@v3
            with:
              name: build-code
              path: cypress/
      e2e-test:
        runs-on: ubuntu-latest
        needs: build
        steps: 
            - uses: actions/checkout@v3
            - uses: actions/download-artifact@v3
              with:
                name: build-code
                path: cypress/
            - name: Cypress run
              run: |
                docker run -d -p 3001:3000 jaimesalas/hangman-api
                docker run -d -p 8080:8080 -e API_URL=http://localhost:3001 jaimesalas/hangman-front
            - uses: cypress-io/github-action@v5
              with:
                project: .
                browser: chrome
    ```
4. Comiteamos los cambios y al hacer push se ejecutará el workflow, que al finalizar, en su sumario se puede observar el resultado del test
    ```sh
    git add .
    git commit -m "ej3"
    git push
    ```
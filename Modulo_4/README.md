# Ejercicios Jenkins
## Ejercicio 1

### Instalar Jenkins en local con dependencias necesarias
Para la ejecución en local construimos una imagen a partir del Dockerfile aportado y ejecutamos el contenedor de Jenkins
```shell
docker run -p 8080:8080 -p 50000:50000 --restart=on-failure jenkins:latest
```
Posteriormente lo cargamos desde localhost:8080 e instalamos los plugins recomendados

### 1. CI/CD de una Java + Gradle

1. Creamos el repositorio en GitHub para la app y lo clonamos
   
    ```
    git clone https://github.com/L0kyLuke/lab_mod_4.git
    ```

2. Posteriormente copiamos los ficheros en el repositorio local

3. Creamos el Jenkinsfile en el directorio raíz de la app
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
4. Le doy permisos de ejecución a `gradlew`
    ```shell
    chmod +x gradlew
    ```

5. Al usar WSL para evitar el error "/usr/bin/env: ‘bash\r’: No such file or directory" al ejecutar `gradlew` uso el comando `sed` sobre gradlew
    ```shell
    sed -i 's/\r$//' gradlew
    ```

6. Subimos los cambios al repositorio
    ```shell
    git add .
    git commit -m "add files"
    git push
    ```
7. Creamos una nueva pipeline en Jenkins con los siguientes datos y la ejecutamos:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: https://github.com/L0kyLuke/lab_mod_4.git
   - Branch Specifier: */main
   - Script Path: Jenkinsfile
  
### 2. Modificar la pipeline para que utilice la imagen Docker de Gradle como build runner

1. Instalamos los plugins `Docker` y `Docker Pipeline` en Jenkins
   
2. Modificamos la pipeline anterior
    ```groovy
        pipeline {
        agent {
            docker {
                image 'gradle:6.6.1-jre14-openj9'
                }
        }

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
    # CONSEGUIR INSTALAR DOCKER BIEN EN JENKINS YA QUE NO LO ENCUENTRA


# Ejercicios GitLab
## Ejercicio 1    

### 1. CI/CD de una aplicación spring

1. Creamos un nuevo proyecto en blanco en GitLab, lo llamamos `gitlab-springapp` y lo hacemos público
   
2. Lo clonamos en local
    ```shell
    git clone http://gitlab.local:8888/bootcamp/gitlab-springapp.git
    ```
3. Copiamos los ficheros del proyecto springapp a /gitlab-springapp y subimos los cambios al repositorio
   
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
5. Al comprobar en localhost:8081 que funciona corréctamente, hacemos el `merge request` para pasarlo a master yendo a `Merge requests > Create merge request > Merge`
   
6. Tras la `merge request` ejecutamos la app en localhost:8080

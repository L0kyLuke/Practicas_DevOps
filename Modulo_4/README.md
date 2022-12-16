# Ejercicio 1

## Instalar Jenkins en local con dependencias necesarias
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

2. Posteriormente copiamos los ficheros en el repositorio local

3. Creamos el Jenkinsfile en el directorio raíz de la app
    ```groovy
    pipeline {
        agent any

        stages {
            stage('Checkout') {
                steps {
                    git branch: 'main',
        url: 'https://github.com/L0kyLuke/lab_mod_4.git'
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
  
def call(String servicePath, String imageName, String imageTag) {
  dir(servicePath) {
    sh "docker build -t ${imageName}:${imageTag} ."
  }
}


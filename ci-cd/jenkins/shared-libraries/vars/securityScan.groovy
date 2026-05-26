def call(String target) {
  sh "trivy fs --severity HIGH,CRITICAL --ignore-unfixed ${target}"
}


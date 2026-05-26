def call(String releaseName, String chartPath, String valuesFile) {
  sh "helm upgrade --install ${releaseName} ${chartPath} -f ${valuesFile}"
}


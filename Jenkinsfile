pipeline {
    agent any
    environment {
      ORG               = 'garethjevans'
      APP_NAME          = 'golang-http2'
      GIT_PROVIDER      = 'github.com'
      CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
    }
    stages {
      stage('CI Build and push snapshot') {
        when {
          branch 'PR-*'
        }
        environment {
          PREVIEW_VERSION = "0.0.0-SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER"
          PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
          HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
        }
        steps {
          dir ('/home/jenkins/go/src/github.com/garethjevans/golang-http2') {
            checkout scm
            sh "make linux"
            sh 'export VERSION=$PREVIEW_VERSION && skaffold build -f skaffold.yaml'
            sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:$PREVIEW_VERSION"
          }
          dir ('/home/jenkins/go/src/github.com/garethjevans/golang-http2/charts/preview') {
            sh "make preview"
            sh "jx preview --app $APP_NAME --dir ../.."
          }
        }
      }
      stage('Build Release') {
        when {
          branch 'master'
        }
        steps {
          dir ('/home/jenkins/go/src/github.com/garethjevans/golang-http2') {
            checkout scm
          }
          dir ('/home/jenkins/go/src/github.com/garethjevans/golang-http2/charts/golang-http2') {
            git 'https://github.com/garethjevans/golang-http2.git'
            // until we switch to the new kubernetes / jenkins credential implementation use git credentials store
            sh "git config --global credential.helper store"

            sh "jx step git credentials"
          }
          dir ('/home/jenkins/go/src/github.com/garethjevans/golang-http2') {
            // so we can retrieve the version in later steps
            sh "echo \$(jx-release-version) > VERSION"
          }
          dir ('/home/jenkins/go/src/github.com/garethjevans/golang-http2/charts/golang-http2') {
            sh "make tag"
          }
          dir ('/home/jenkins/go/src/github.com/garethjevans/golang-http2') {
            sh "make build"
            sh 'export VERSION=`cat VERSION` && skaffold build -f skaffold.yaml'

            sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:\$(cat VERSION)"
          }
        }
      }
      stage('Promote to Environments') {
        when {
          branch 'master'
        }
        steps {
          dir ('/home/jenkins/go/src/github.com/garethjevans/golang-http2/charts/golang-http2') {
            sh 'jx step changelog --version v\$(cat ../../VERSION)'

            // release the helm chart
            sh 'jx step helm release'

            // promote through all 'Auto' promotion Environments
            sh 'jx promote -b --all-auto --timeout 1h --version \$(cat ../../VERSION)'
          }
        }
      }
    }
  }

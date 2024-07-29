def runShellCommand(script, int retries = 5) {
    for (int i = 0; i < retries; i++) {
        try {
            echo "Running shell command, attempt ${i + 1}..."
            int status = sh(
                    script: script,
                    returnStatus: true
            )
            if (status != 0) {
                throw new Exception("Command failed with status code: ${status}")
            }
            return // 成功时退出函数
        } catch (Exception e) {
            println("Command failed, attempt ${i + 1}, error: ${e}")
            if (i == retries - 1) {
                error("Max retries reached. Failing the build.")
            }
        }
    }
}

pipeline {
    agent {
        node {
            label 'linux-amd64-buildx'
        }
    }
    options {
        checkoutToSubdirectory('docker-web')
    }
    stages {
        stage('Preparation') {
            steps {
                script {
                    if (params.branch != null) {
                        env.BRANCH_NAME = params.branch
                    }
                    if (params.release_version != null) {
                        env.RELEASE_VERSION = params.release_version
                    } else {
                        env.RELEASE_VERSION = env.BRANCH_NAME
                    }

                    echo "RELEASE_VERSION=${RELEASE_VERSION}"
                    echo "BRANCH=${BRANCH_NAME}"
                }
            }
        }
        stage('Checkout') {
            steps {
                // Get some code from a GitHub repository
                dir('lina') {
                    git url: 'git@github.com:jumpserver/lina.git', branch: "dev"
                }
                dir('luna') {
                    git url: 'git@github.com:jumpserver/luna.git', branch: "dev"
                }
                sh """
                    git config --global user.email "fit2bot@jumpserver.org"
                    git config --global user.name "fit2bot"
                """
            }
        }
        stage('Build repos') {
            parallel {
                stage('lina') {
                    steps {
                        dir('lina') {
                            script {
                                echo "Start build lina"
                                runShellCommand("""
                                    docker buildx build \
                                    --platform linux/amd64,linux/arm64 \
                                    --build-arg VERSION=$RELEASE_VERSION \
                                    -t jumpserver/lina:${RELEASE_VERSION} .
                                """)
                            }
                        }
                    }
                }
                stage('luna') {
                    steps {
                        dir('luna') {
                            script {
                                echo "Start build luna"
                                runShellCommand("""
                                    docker buildx build \
                                    --platform linux/amd64,linux/arm64 \
                                    --build-arg VERSION=$RELEASE_VERSION \
                                    -t jumpserver/luna:${RELEASE_VERSION} .
                                """)
                            }
                        }
                    }
                }
            }
        }
        stage('Build docker web ce') {
            steps {
                script {
                    echo "Start build docker-web"
                    runShellCommand("""
                        docker buildx build \
                        --platform linux/amd64,linux/arm64 \
                        --build-arg VERSION=$RELEASE_VERSION \
                        -t jumpserver/web:${RELEASE_VERSION}-ce \
                        --push .
                    """)
                }
            }
        }
        stage('Build docker web ee') {
            steps {
                script {
                    echo "Start build docker-web"
                    runShellCommand("""
                        docker buildx build \
                        --platform linux/amd64,linux/arm64 \
                        --build-arg VERSION=$RELEASE_VERSION \
                        -f Dockerfile-ee \
                        -t jumpserver/web:${RELEASE_VERSION}-ee \
                        --push .
                    """)
                }
            }
        }
        stage('Done') {
            steps {
                echo "All done!"
            }
        }
    }
}

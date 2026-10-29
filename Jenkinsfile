// =============================================================================
// Enterprise Jenkins Declarative Pipeline for AWS Free-Tier Infrastructure
// Allows parameter-driven provisioning by simply specifying instance count.
// =============================================================================

pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select Terraform Action: plan (dry-run preview), apply (provision to AWS), or destroy (teardown)'
        )
        string(
            name: 'INSTANCE_COUNT',
            defaultValue: '1',
            description: 'Number of EC2 instances to provision (e.g. 1, 2, 3...)'
        )
        choice(
            name: 'INSTANCE_TYPE',
            choices: ['t3.micro', 't2.micro'],
            description: 'AWS Free-Tier eligible instance type (t3.micro is default for modern AWS accounts)'
        )
        choice(
            name: 'OS_TYPE',
            choices: ['ubuntu', 'amazon-linux'],
            description: 'Free-Tier Operating System (Ubuntu 22.04 LTS or Amazon Linux 2023)'
        )
        string(
            name: 'ROOT_VOLUME_GB',
            defaultValue: '10',
            description: 'Disk size in GB per instance (Keep total across all nodes <= 30 GB to stay 100% Free Tier!)'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Target deployment environment'
        )
        string(
            name: 'AWS_CREDENTIALS_ID',
            defaultValue: 'aws-credentials',
            description: 'Jenkins Credentials ID (Secret Text / AWS credentials) storing AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'Check to skip manual approval prompt before applying changes'
        )
    }

    environment {
        ENV_DIR = "environments/${params.ENVIRONMENT}"
        TF_IN_AUTOMATION = 'true'
    }

    stages {
        stage('Validate Free-Tier Budget') {
            steps {
                script {
                    def count = params.INSTANCE_COUNT.toInteger()
                    def volSize = params.ROOT_VOLUME_GB.toInteger()
                    def totalStorage = count * volSize

                    echo "================================================================="
                    echo "  AWS FREE-TIER COMPLIANCE CHECK"
                    echo "================================================================="
                    echo "Requested Instances: ${count} x ${params.INSTANCE_TYPE}"
                    echo "Requested Storage:   ${count} x ${volSize} GB = ${totalStorage} GB"
                    echo "Target Environment:  ${params.ENVIRONMENT}"
                    echo "NAT Gateway:         DISABLED (Saves \$32.85/month!)"
                    echo "S3 Gateway Endpoint: ENABLED (100% Free direct S3 routing)"

                    if (totalStorage > 30) {
                        echo "[WARNING] Total storage (${totalStorage} GB) exceeds AWS Free Tier limit of 30 GB/month!"
                        echo "          AWS will charge ~\$0.08 per GB-month for storage exceeding 30 GB."
                    } else {
                        echo "[PASS] Storage is within the 30 GB AWS Free Tier limit."
                    }
                    echo "================================================================="
                }
            }
        }

        stage('Generate Free-Tier Configuration') {
            steps {
                script {
                    echo "[Step 1/5] Dynamically generating Free-Tier terraform.tfvars..."
                    def pythonCmd = isUnix() ? "python3" : "python"
                    
                    // Run python helper to generate tfvars dynamically
                    sh "${pythonCmd} scripts/generate_free_tier_tfvars.py --count ${params.INSTANCE_COUNT} --instance-type ${params.INSTANCE_TYPE} --os ${params.OS_TYPE} --volume-gb ${params.ROOT_VOLUME_GB} --env ${params.ENVIRONMENT} --output ${env.ENV_DIR}/terraform.tfvars"
                }
            }
        }

        stage('Terraform Init & Validate') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: params.AWS_CREDENTIALS_ID,
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir(env.ENV_DIR) {
                        echo "[Step 2/5] Initializing Terraform..."
                        sh 'terraform init'

                        echo "[Step 3/5] Validating Terraform syntax..."
                        sh 'terraform validate'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.ACTION != 'destroy' }
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: params.AWS_CREDENTIALS_ID,
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir(env.ENV_DIR) {
                        echo "[Step 4/5] Generating execution plan..."
                        sh 'terraform plan -out=tfplan'
                    }
                }
            }
        }

        stage('Approval Gate') {
            when {
                allOf {
                    expression { params.ACTION == 'apply' }
                    expression { params.AUTO_APPROVE == false }
                }
            }
            steps {
                script {
                    echo "Execution plan generated above."
                    input message: "Review the plan above. Do you want to apply these ${params.INSTANCE_COUNT} free-tier instances to AWS?", ok: "Deploy to AWS"
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: params.AWS_CREDENTIALS_ID,
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir(env.ENV_DIR) {
                        echo "[Step 5/5] Applying approved infrastructure..."
                        sh 'terraform apply -input=false tfplan'
                        sh 'rm -f tfplan'

                        echo "================================================================="
                        echo "  PROVISIONED FREE-TIER INSTANCES SUMMARY"
                        echo "================================================================="
                        sh 'terraform output -json instance_summary'
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                script {
                    if (params.ENVIRONMENT == 'prod') {
                        input message: "DANGER: You are about to DESTROY the PRODUCTION environment! Confirm destruction?", ok: "Yes, destroy production"
                    }
                }
                withCredentials([usernamePassword(
                    credentialsId: params.AWS_CREDENTIALS_ID,
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir(env.ENV_DIR) {
                        echo "Decommissioning Free-Tier resources..."
                        sh 'terraform destroy -auto-approve'
                        echo "✔ Teardown completed."
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs(deleteDirs: true, notFailBuild: true, patterns: [[pattern: '**/tfplan', type: 'INCLUDE']])
        }
        success {
            echo "✔ Jenkins pipeline finished successfully!"
        }
        failure {
            echo "✖ Pipeline failed. Check console output above for error details."
        }
    }
}

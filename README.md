# Automated Web App Deployment with CI/CD, Docker, Kubernetes, and AWS

This project automates the deployment of a containerized web application using **Jenkins**, **Docker**, **Kubernetes**, **Terraform**, and **AWS**. It also includes monitoring with **Prometheus** and notifications via **Slack**.

## Architecture Overview

![Architecture Diagram](https://github.com/Nagham94/DEPI-FINAL-PROJECT/blob/main/depi-project-diagram.jpeg) <!-- Replace with the actual image path in your repo -->

### Components:
- **Jenkins**: Clones the GitHub repo, builds the Docker image, pushes it to Docker Hub, and triggers Terraform.
- **Terraform**: Provisions AWS infrastructure including EC2 instances, S3 bucket for state storage, and networking components.
- **Docker Hub**: Stores the Docker image built by Jenkins.
- **AWS EC2**:
  - **1 Master Node**: Runs the Kubernetes control plane.
  - **2 Worker Nodes**:
    - One runs the application pods.
    - One runs Prometheus to monitor all nodes.
- **Kubernetes**: Orchestrates containerized app deployment.
- **Slack**: Notified by Jenkins about build status, IPs, and app URL.

## Workflow

1. Jenkins clones the GitHub repo containing the app.
2. Jenkins builds the Docker image and pushes it to Docker Hub.
3. Jenkins triggers `terraform apply`.
4. Terraform:
   - Creates an S3 bucket for state management.
   - Provisions 3 EC2 instances (1 master, 2 workers).
5. Kubernetes cluster is initialized with the master node.
6. Worker nodes join the cluster.
7. App is deployed as pods on one of the worker nodes.
8. Prometheus is deployed on the other worker node to monitor all nodes.
9. Jenkins sends build and deployment updates to Slack (including IPs and app URL).

## Technologies Used

- Jenkins
- Docker
- Docker Hub
- GitHub
- Terraform
- AWS (EC2, S3)
- Kubernetes
- Prometheus
- Slack

## Repository Structure

```bash
/ (Root Directory)
│
├── app/                        # Application files and Dockerfile
│
├── deploy_all_files/           # Deployment kubernetes manifest files
│
├── modules/                    # Terraform modules
│   └── server_module/          # Server module
│
├── scripts/                    # Scripts for installing dependencies
│
├── .gitignore                  # Git ignore file
├── docker-compose.yml          # Docker Compose configuration file
├── jenkinsfile                 # Jenkins pipeline configuration
├── depi-project-diagram.jpeg   # Architecture of the project
├── main.tf                     # Main Terraform configuration
├── output.tf                   # Terraform output variables
├── README.md                   # Project README

```

## Prerequisites

- AWS CLI configured
- Docker & Docker Hub account
- Jenkins server (with required plugins)
- Terraform installed
- Slack Webhook URL for notifications

## Notes

- Replace placeholders (like DockerHub repo name, Slack Webhook) with your own values.
- Ensure ports are correctly opened on EC2 security groups.
- S3 bucket must be unique globally.

## Contact

For questions or feedback, feel free to reach out or open an issue.

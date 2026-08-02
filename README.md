LAB ARCHIECTURE


flowchart TD
    Git["GitLab repositories"] -->|Webhook or polling| JC["Jenkins controller pod"]
    JC -->|Kubernetes plugin| JA["Temporary Jenkins agent pod"]
    JA --> Build["Maven test and image build"]
    Build --> Registry["Local container registry"]
    JA --> Deploy["kubectl / Helm deployment"]
    Deploy --> Apps["Application pods in kind"]
    JA -->|Build complete| Delete["Agent pod deleted"]


install the Jenkins controller as a Kubernetes Deployment using the official Jenkins Helm chart.

The installation will contain:

Jenkins controller pod
Jenkins service
PersistentVolumeClaim for /var/jenkins_home
ServiceAccount and RBAC
Kubernetes plugin
Git, GitLab, Pipeline, Credentials and Configuration-as-Code plugins

The controller remains running, while build workloads execute on separate agent pods. This is also the installation method shown in the official Jenkins Kubernetes guide.

Important limitation: because kind is a local lab, deleting the entire cluster normally deletes Jenkins configuration and build history. We should therefore keep Jenkins configuration in Git using:

Helm values
Jenkins Configuration as Code
Job DSL or seed jobs
Jenkinsfiles
Shared Libraries

2. Can Jenkins agents run as pods?

Yes. The Jenkins Kubernetes plugin dynamically creates an agent pod for each build and deletes it afterward. That gives you exactly this lifecycle:

flowchart TD
    Git push
    ↓
    Jenkins pipeline triggered
    ↓
    Agent pod created
    ↓
    Repository cloned
    ↓
    Build → Test → Scan → Image build → Deploy
    ↓
    Agent pod deleted

The plugin officially supports creating an agent pod for a build and stopping it when the build finishes. Jenkins Kubernetes plugin documentation

**Recommended implementation order**
1. Verify Docker, kind, kubectl and Helm.---Done

2. Create a multi-node kind cluster.

    2.1. Create the cluster:
        Create kind/kind-config.yaml
        kind create cluster \
            --name jenkins-lab \
            --config kind/kind-config.yaml
    2.2. Validate the new cluster
            kubectl config current-context
            kubectl get nodes
            kubectl get pods -A
            kuebctl get storageclass
            kubectl get --raw='/readz?verbose'
        Output:
            kind-jenkins-lab
            jenkins-lab-control-plane
            jenkins-lab-worker
            jenkins-lab-worker2
        
4. Install Jenkins using Helm.
















5. Configure persistent storage and Jenkins Configuration as Code.
6. Configure Kubernetes dynamic agent pods.
7. Run a simple Groovy “Hello World” pipeline.
8. Run a Maven pipeline on an agent pod.
9. Add a local registry and image build.
10. Deploy the Java application into kind.
11. Integrate the GitLab repository.
12. Add Python, Node.js and legacy sample applications.
13. Build discovery and migration scripts.
14. Add multibranch pipelines and shared libraries.
15. Convert one Jenkinsfile into .gitlab-ci.yml.


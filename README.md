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
        
3. Install Jenkins using Helm.

    3.1. Add the official Jenins Helm repostory
    
        ``helm repo add jenkins https://charts.jenkins.io`
    3.2. Check the chart
         ``bash``
            helm repo update
    3.3. Crate the Jenkins namespace
        `` kubectl create namespae jenkins`

        NAME: jenkins
LAST DEPLOYED: Sun Aug  2 14:43:26 2026
NAMESPACE: jenkins
STATUS: deployed
REVISION: 1
NOTES:
1. Get your 'admin' user password by running:
  kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
2. Get the Jenkins URL to visit by running these commands in the same shell:
  echo http://127.0.0.1:8080
  kubectl --namespace jenkins port-forward svc/jenkins 8080:8080

3. Login with the password from step 1 and the username: admin
4. Configure security realm and authorization strategy
5. Use Jenkins Configuration as Code by specifying configScripts in your values.yaml file, see documentation: http://127.0.0.1:8080/configuration-as-code and examples: https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos

For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine

For more information about Jenkins Configuration as Code, visit:
https://jenkins.io/projects/jcasc/


NOTE: Consider using a custom image with pre-installed plugins

xjgXCxMuVMUvAsqJi1Eb4M


4. Port-forward

kubectl config current-context
if current-context isnot jenkins
kubectl get pods,svc,pvc -n jenkins ==> pvc should be bound
restart port-forarding
kubectl port-forward -n jenkins svc/jenkins 8080:8080
** IMP : Keep the terminal open**


5. Once logged in, our next step is to verify the Kubernetes plugin and run a basic Groovy pipeline on a temporary agent pod.
















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


=> k3d cluster delete argocd-cluster
    (it deletes the cluster if it already exists)

=> argocd app sync myapp
    (it syncs the application to deploy it on the cluster)
 
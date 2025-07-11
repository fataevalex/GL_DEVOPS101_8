#  SOPS-KMS-FLUX
### terraform bootstrap flux
1. Встановлюємо flux в kubernetges кластер зі схемою monorepo.
   Репозиторій flux тий самий що і для додатків
   Треба підготувати kubeconfig та 
```shell
  cd tfbootstrap/github
  terraform init
  terraform apply
  cd ../../
```

If you want to use an existing repository, the PAT’s user must have admin permissions.
https://fluxcd.io/flux/installation/bootstrap/github/#github-deploy-keys

2. Створення секрета для доступу до aws kms за допомогую IAM юзера
```shell
    export AWS_DEFAULT_REGION=
    export AWS_ACCESS_KEY_ID=
    eport AWS_SECRET_ACCESS_KEY=
    
    aws sts get-caller-identity
   
    bash iac/scripts/kube2iam-create-secret.sh
```
3. Налаштування разшифрування секретів, зашифрованих sops та aws kms
додаєм до clusters/archonmac/flux-system/kustomization.yaml
```text
 - ../../iac/environments/dev2
patchesStrategicMerge:
  - flux-system/patch-kustomization-decryption.yaml
  - flux-system/patch-kustomize-env.yaml
```
створюємо 2 нових файла в clusters/archonmac/flux-system
patch-kustomization-decryption.yaml
```text
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: flux-system
  namespace: flux-system
spec:
  decryption:
    provider: sops
    secretRef:
      name: kube2iam-aws-credentials

```
та
patch-kustomize-env.yaml
```text
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kustomize-controller
  namespace: flux-system
spec:
  template:
    spec:
      containers:
        - name: manager
          env:
            - name: AWS_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: kube2iam-aws-credentials
                  key: AWS_ACCESS_KEY_ID
            - name: AWS_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: kube2iam-aws-credentials
                  key: AWS_SECRET_ACCESS_KEY
            - name: AWS_REGION
              valueFrom:
                secretKeyRef:
                  name: kube2iam-aws-credentials
                  key: AWS_DEFAULT_REGION

```
та комітемо зміни у master
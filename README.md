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
    bash iac/scripts/kube2iam-create-secret.sh
```
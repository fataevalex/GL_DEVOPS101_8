#  SOPS-KMS-FLUX
### terraform bootstrap flux
1. Встановлюємо flux в kubernetges кластер зі схемою monorepo.
   Репозиторій flux тий самий що і для додатків
   Треба підготувати kubeconfig та 
```shell
  cd tfbootstrap/github
  terraform init
  terraform apply
```

If you want to use an existing repository, the PAT’s user must have admin permissions.
https://fluxcd.io/flux/installation/bootstrap/github/#github-deploy-keys
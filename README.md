#  SOPS-KMS-FLUX

### 1. Встановлюємо flux в kubernetges кластер за схемою monorepo.(вважаєм кластер вже готовий)
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

### 2. Створення секрета для доступу до aws kms за допомогую IAM юзера
```shell
    export AWS_DEFAULT_REGION=
    export AWS_ACCESS_KEY_ID=
    eport AWS_SECRET_ACCESS_KEY=
    
    aws sts get-caller-identity
   
    bash iac/scripts/kube2iam-create-secret.sh
```
### 3. Налаштування можливості разшифрування секретів в кластері, зашифрованих sops-ом та aws kms-ом
додаєм до clusters/archonmac/flux-system/kustomization.yaml
```text
- ../../../iac/environments/dev2
patchesStrategicMerge:
  - patch-kustomization-decryption.yaml
  - patch-kustomize-env.yaml
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
та комітемо зміни у master і запускаємо позачергову реконсиляцію
```shell
    flux reconcile kustomization flux-system --with-source 
```

### 4. Готуємо секрет для kbot
створемо конфігурацію для sops 
```text
cat <<EOF > .sops.yaml
creation_rules:
  - kms: "arn:aws:kms:eu-west-1:<AWS ACCOUNT ID>:key/<KMS_KEY_ID>"
    encrypted_regex: "^(data|stringData)$"
    path_regex: ".*secret.*\\.yaml$"
EOF
```
і сгенеруємо сам секрет
```shell
   export TELETOKEN=<значення токена для телеграм бота>
   kubectl create secret generic kbot --from-literal=token=${TELETOKEN} --dry-run=client -o yaml > iac/apps/kbot-otel/secret.sops.yaml
```
де XXX токен тееграм бота
далі шифруємо отриманий файл sops-ом (змінні середовища AWS_... для доступа KMS повинні бути встановлені)
```shell
    sops -e -i iac/apps/kbot-otel/secret.sops.yaml
```

### 5 Включаемо розгортання kbot в iac/environments/dev2/kustomization.yaml. Додаємо рядок
```text
  - ../../apps/kbot-otel
```
комітемо та пушаємо зроблені зміни
виконуємо path для додавання змінної METRICS_HOST. Без неї kbot-otel не працює
```shell
   kubectl apply -f iac/apps/kbot-otel/patch-env.yaml 
```
Дивимось логи бота
```shell
   kubectl logs -f  -l app.kubernetes.io/name=kbot -n kbot-otel-flux
```


# SOPS-KMS-FLUX: Налаштування та використання

Цей посібник охоплює налаштування **Flux CD** з підтримкою **AWS KMS** та **SOPS** для безпечного розгортання секретів у вашому **Kubernetes кластері**. Він призначений для використання у схемі **monorepo**, де репозиторій Flux є тим самим, що і для ваших додатків.
[Налаштування репозиторія для аналізу наявності конфіденційних даних в репозиторії](doc/gitleaks.md)
-----

### 1\. Встановлення Flux CD в Kubernetes кластері (схема monorepo)

**Примітка:** Ми припускаємо, що ваш Kubernetes кластер вже налаштований та готовий до використання.

Для встановлення Flux CD, виконайте наступні кроки:

1.  **Підготовка kubeconfig:** Переконайтеся, що ваш `kubeconfig` файл коректно налаштований для доступу до кластера.
2.  **Ініціалізація та застосування Terraform:**
    ```bash
    cd tfbootstrap/github
    terraform init
    terraform apply
    cd ../../
    ```

**Важливо:** Якщо ви використовуєте існуючий репозиторій, користувач, який згенерував **PAT (Personal Access Token)**, повинен мати **адмін-права** на цей репозиторій.
Додаткову інформацію можна знайти тут: [Flux CD Documentation: GitHub Deploy Keys](https://fluxcd.io/flux/installation/bootstrap/github/#github-deploy-keys).

-----

### 2\. Створення секрету для доступу до AWS KMS за допомогою IAM користувача

Перед створенням секрету переконайтеся, що у вас є необхідні облікові дані **AWS IAM** користувача.

1.  **Експорт змінних середовища AWS:**
    Замініть плейсхолдери `<ваш_регіон>`, `<ваш_ключ_доступу>` та `<ваш_секретний_ключ_доступу>` на ваші фактичні значення.

    ```bash
    export AWS_DEFAULT_REGION="<ваш_регіон>" # Наприклад, eu-west-1
    export AWS_ACCESS_KEY_ID="<ваш_ключ_доступу>"
    export AWS_SECRET_ACCESS_KEY="<ваш_секретний_ключ_доступу>"
    ```

2.  **Перевірка облікових даних AWS:**
    Ця команда підтвердить, що ваші облікові дані AWS налаштовані правильно.

    ```bash
    aws sts get-caller-identity
    ```

3.  **Створення Kubernetes секрету:**
    Цей скрипт створить Kubernetes секрет з вашими AWS обліковими даними, який буде використовуватися для доступу до KMS.

    ```bash
    bash iac/scripts/kube2iam-create-secret.sh
    ```

-----

### 3\. Налаштування розшифрування секретів у кластері за допомогою SOPS та AWS KMS

Щоб Flux CD міг розшифровувати секрети, зашифровані SOPS з використанням AWS KMS, необхідно внести зміни до конфігурації Flux CD.

1.  **Додавання патчів до `clusters/archonmac/flux-system/kustomization.yaml`:**
    Відкрийте файл `clusters/archonmac/flux-system/kustomization.yaml` та додайте наступні рядки:

    ```yaml
    - ../../../iac/environments/dev2 # Переконайтеся, що цей шлях коректний для вашого середовища
    patchesStrategicMerge:
      - patch-kustomization-decryption.yaml
      - patch-kustomize-env.yaml
    ```

2.  **Створення файлу `patch-kustomization-decryption.yaml`:**
    Створіть новий файл `patch-kustomization-decryption.yaml` у директорії `clusters/archonmac/flux-system` з наступним вмістом:

    ```yaml
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

    Цей патч налаштовує `Kustomization` Flux для використання **SOPS** як провайдера дешифрування.

3.  **Створення файлу `patch-kustomize-env.yaml`:**
    Створіть новий файл `patch-kustomize-env.yaml` у тій же директорії `clusters/archonmac/flux-system` з наступним вмістом:

    ```yaml
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

    Цей патч інжектує AWS облікові дані (доступ до KMS) у змінних середовища `kustomize-controller` контейнера, дозволяючи йому виконувати дешифрування.

4.  **Коміт змін та позачергова реконсиляція:**
    Закомітьте внесені зміни у вашій `master` (або основній) гілці та запустіть позачергову реконсиляцію Flux:

    ```bash
    flux reconcile kustomization flux-system --with-source
    ```

-----

### 4\. Підготовка секрету для Kbot

Для шифрування секретів Kbot за допомогою SOPS та AWS KMS виконайте наступні кроки:

1.  **Створення конфігурації SOPS (`.sops.yaml`):**
    Цей файл визначає правила шифрування для SOPS. Замініть `<AWS ACCOUNT ID>` та `<KMS_KEY_ID>` на ваші фактичні значення.

    ```bash
    cat <<EOF > .sops.yaml
    creation_rules:
      - kms: "arn:aws:kms:eu-west-1:<AWS ACCOUNT ID>:key/<KMS_KEY_ID>"
        encrypted_regex: "^(data|stringData)$"
        path_regex: ".*secret.*\\.yaml$"
    EOF
    ```

2.  **Генерація секрету для Kbot:**
    Замініть `<значення_токена_для_телеграм_бота>` на ваш фактичний токен.

    ```bash
    export TELETOKEN="<значення_токена_для_телеграм_бота>"
    kubectl create secret generic kbot --from-literal=token=${TELETOKEN} --dry-run=client -o yaml > iac/apps/kbot-otel/secret.sops.yaml
    ```

3.  **Шифрування файлу за допомогою SOPS:**
    Переконайтеся, що змінні середовища `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` та `AWS_DEFAULT_REGION` встановлені (як у кроці 2).

    ```bash
    sops -e -i iac/apps/kbot-otel/secret.sops.yaml
    ```

-----

### 5\. Включення розгортання Kbot та застосування патчу

1.  **Додавання Kbot до `iac/environments/dev2/kustomization.yaml`:**
    Відкрийте файл `iac/environments/dev2/kustomization.yaml` та додайте наступний рядок, щоб включити розгортання Kbot:

    ```yaml
    - ../../apps/kbot-otel
    ```

2.  **Коміт та пуш змін:**
    Закомітьте та відправте (пуш) зроблені зміни до вашого Git репозиторію.

3.  **Застосування патчу для змінної `METRICS_HOST`:**
    Kbot-otel потребує змінної середовища `METRICS_HOST` для коректної роботи. Застосуйте патч:

    ```bash
    kubectl apply -f iac/apps/kbot-otel/patch-env.yaml
    ```

4.  **Перегляд логів бота:**
    Щоб перевірити роботу Kbot, перегляньте його логи:

    ```bash
    kubectl logs -f -l app.kubernetes.io/name=kbot -n kbot-otel-flux
    ```

-----
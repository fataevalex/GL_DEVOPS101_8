# Перевірка секретів перед комітом за допомогою Gitleaks

Цей репозиторій містить `pre-commit` Git-хук, який автоматично виконує перевірку на наявність секретів у змінених файлах за допомогою [Gitleaks](https://github.com/gitleaks/gitleaks).

## Можливості

- Перевіряє `staged` файли на наявність секретів перед кожним комітом
- Блокує коміт, якщо виявлені потенційні секрети
- Якщо `gitleaks` не встановлено — виводить попередження, але **не блокує коміт**
- Генерує звіт у форматі SARIF для інтеграції з IDE (наприклад, VSCode)

### 1. Встановіть Gitleaks

**Для macOS (через Homebrew):**
```bash
brew install gitleaks
```
**Для Linux / кросплатформено**
```bash
curl -sSL https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_$(uname -s)_$(uname -m).tar.gz | tar -xz
sudo mv gitleaks /usr/local/bin
```

### 2. Активуйте хуки в цьому репозиторії
   Вкажіть Git використовувати директорію .githooks/ для хуків:
 ```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
```  
 Це потрібно виконати лише один раз після клонування.

### 3. (Опційно) Додайте звіти до .gitignore
   .gitleaks/


### Використання
додавайте та комітіть зміни:
```bash
git add .
git commit -m "додав нову функцію"
Якщо знайдено секрети — коміт буде заблокований.
Звіт буде збережений у .gitleaks/gitleaks-report.sarif.
```
### Підтримка IDE

#### VSCode
1. Встановіть розширення [SARIF Viewer](https://marketplace.visualstudio.com/items?itemName=MS-SarifVSCode.sarif-viewer) 
2. Відкрийте файл .gitleaks/gitleaks-report.sarif для перегляду

#### JetBrains IDE (IntelliJ, PyCharm тощо)
Поки що SARIF напряму не підтримується — можна переглядати вручну або 
конвертувати у Markdown.


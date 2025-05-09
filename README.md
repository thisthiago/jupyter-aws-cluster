# 🚀 Terraform AWS ECS - Jupyter Notebook

Este projeto provisiona uma infraestrutura completa na AWS utilizando **Terraform** para executar o **Jupyter Notebook** em um contêiner ECS com **Fargate**.

---
Claro! O **AWS Fargate** é um mecanismo de computação **serverless** para **containers**, que funciona com o **Amazon ECS** (Elastic Container Service) e o **Amazon EKS** (Elastic Kubernetes Service). Ele permite que você execute containers **sem precisar provisionar, configurar ou gerenciar servidores ou clusters**.

---

### 🔍 Como o Fargate funciona

1. **Você define apenas sua aplicação**:

   * Cria uma **task definition** (definição do container, imagem, CPU, memória, portas etc.).
   * Informa a **quantidade de recursos** (CPU e memória) por tarefa/container.
   * Especifica a **rede e permissões (IAM)**.

2. **Fargate cuida do resto**:

   * Ele **provisiona dinamicamente a infraestrutura necessária** para executar os containers.
   * Garante que cada tarefa tenha **isolamento de segurança e recursos dedicados**.
   * Escala automaticamente conforme você aumenta ou reduz o número de tarefas.

3. **Você paga apenas pelo que usa**:

   * O custo é baseado no **tempo de execução do container**, CPU e memória alocados.
   * Não há cobrança por instâncias EC2 — o provisionamento é feito "por container".

---

### ✅ Vantagens do Fargate

* **Zero gerenciamento de servidor**: você não precisa lidar com EC2, clusters, AMIs, atualizações, etc.
* **Escalabilidade automática**: adiciona ou remove containers conforme a demanda.
* **Segurança melhorada**: cada tarefa roda isoladamente, com sua própria ENI (Elastic Network Interface).
* **Custo eficiente para workloads intermitentes**: ideal para testes, notebooks, jobs e microserviços pequenos.

---

### 📌 Exemplo prático (no seu projeto)

No seu caso:

* O **Jupyter Notebook** roda como um container definido numa **task ECS**.
* O **Fargate** executa essa task, alocando exatamente `4096 vCPU` e `16 GB RAM`.
* A aplicação fica acessível via internet, com IP público em uma **sub-rede pública**.
* Nenhuma instância EC2 é gerenciada diretamente — Fargate faz tudo isso por trás dos panos.

---


## 📦 Funcionalidades

* Criação de VPC customizada com:

  * Sub-rede pública
  * Internet Gateway
  * Tabela de rotas
* Cluster ECS com Fargate
* Task Definition para Jupyter Notebook
* Serviço ECS com IP público
* Security Group com acesso na porta 8888
* Backend remoto no S3 para o estado do Terraform
* IAM Role com permissões para execução da task

## 🧱 Arquitetura

```text
[Usuário] --> [Security Group (porta 8888)] --> [ECS Fargate (Jupyter Notebook)]
                                 |
                        [Subnet Pública]
                                 |
                        [Internet Gateway]
                                 |
                             [VPC]
```

## ⚙️ Pré-requisitos

* [Terraform >= 1.0.0](https://www.terraform.io/downloads)
* [AWS CLI configurado](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
* Uma conta AWS com permissões suficientes
* Bucket S3 para armazenar o estado remoto (já criado: `tfstate-lab-02-infra-us-east-1`)

## 🚀 Como usar

1. **Clone o repositório:**

   ```bash
   git clone https://github.com/thisthiago/jupyter-aws-cluster.git
   cd jupyter-aws-cluster
   ```

2. **Inicialize o Terraform:**

   ```bash
   terraform init
   ```

3. **Visualize o plano de execução:**

   ```bash
   terraform plan
   ```

4. **Aplique a infraestrutura:**

   ```bash
   terraform apply
   ```

5. **Acesse o Jupyter:**

   * Obtenha o IP público da task ECS via Console AWS ou CLI.
   * Acesse `http://<IP>:8888` no navegador.

> ⚠️ A instância do Jupyter é pública e sem autenticação (sem token e senha). **Não use em ambientes de produção.**

## 🧹 Destruir a infraestrutura

```bash
terraform destroy
```

## 📁 Estrutura do Projeto

```
.
├── main.tf       # Arquivo principal com toda a infraestrutura
├── README.md     # Documentação do projeto
```

## 📝 Observações

* A imagem usada é `thisthiago/jupyter:latest`. Você pode substituí-la por outra conforme sua necessidade.
* Certifique-se de que sua conta AWS esteja na região `us-east-2`.

---

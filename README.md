# TaskManager BDMG

Projeto completo para a Prova Técnica de Desenvolvedor Delphi - BDMG.

## Estrutura do Projeto

```
TaskManagerBDMG/
├── Server/                          # Parte 1 - API REST (Horse)
│   ├── TaskManagerServer.dpr        # Programa principal do servidor
│   ├── sql/
│   │   └── 001_Schema.sql   # Script de criação do banco SQL Server
│   └── src/
│       ├── Attributes/              # Atributos RTTI customizados (ORM)
│       │   └── TaskManager.Attributes.pas
│       ├── Entities/                # Model (M do MVC)
│       │   ├── TaskManager.Entities.Base.pas   # Classe abstrata base
│       │   ├── TaskManager.Entities.User.pas   # Entidade Usuário
│       │   └── TaskManager.Entities.Task.pas   # Entidade Tarefa
│       ├── Repositories/           # Camada de acesso a dados
│       │   ├── TaskManager.Repositories.Interfaces.pas  # Interfaces genéricas
│       │   ├── TaskManager.Repositories.Memory.pas      # Mock (testes)
│       │   ├── TaskManager.Repositories.SQLServer.pas   # Produção
│       │   └── TaskManager.RTTI.Mapper.pas              # ORM via RTTI
│       ├── Services/               # Regras de negócio
│       │   ├── TaskManager.Services.Interfaces.pas
│       │   ├── TaskManager.Services.User.pas
│       │   └── TaskManager.Services.Task.pas
│       ├── Controllers/            # Controller (C do MVC)
│       │   ├── TaskManager.Controllers.User.pas
│       │   └── TaskManager.Controllers.Task.pas
│       ├── Middleware/
│       │   └── TaskManager.Middleware.Auth.pas  # Validação JWT
│       ├── Factories/
│       │   └── TaskManager.Factories.pas       # Abstract Factory
│       └── Utils/
│           ├── TaskManager.Utils.Hash.pas      # SHA-256 + Salt
│           └── TaskManager.Utils.JWT.pas       # Geração/Validação JWT
│
├── Client/                          # Parte 2 - Aplicação VCL
│   ├── TaskManagerClient.dpr        # Programa principal do cliente
│   └── src/
│       ├── Forms/                   # View (V do MVC)
│       │   ├── TaskManager.Client.Forms.Login.pas/.dfm
│       │   ├── TaskManager.Client.Forms.Register.pas/.dfm
│       │   └── TaskManager.Client.Forms.Main.pas/.dfm
│       └── Services/
│           └── TaskManager.Client.ApiService.pas  # HTTP Client
│
├── Tests/                           # Parte 3 - Testes Unitários (DUnitX)
│   ├── TaskManagerTests.dpr         # Runner dos testes
│   └── src/
│       ├── TaskManager.Tests.UserService.pas   # Testes de usuário
│       ├── TaskManager.Tests.TaskService.pas   # Testes de tarefa
│       └── TaskManager.Tests.RttiMapper.pas    # Testes de RTTI/ORM
```

## Arquitetura

### Padrão MVC

- **Model**: Entidades (`TBaseEntity`, `TUser`, `TTask`) com atributos RTTI
- **View**: Formulários VCL (`frmLogin`, `frmRegister`, `frmMain`)
- **Controller**: Controllers REST (`TUserController`, `TTaskController`)

### Princípios OOP Aplicados

| Princípio | Implementação |
|-----------|---------------|
| **Abstração** | Interfaces `IRepository<T>`, `IUserService`, `ITaskService`; classes abstratas |
| **Encapsulamento** | Campos `private` com `property` (getters/setters) em todas as entidades |
| **Herança** | `TBaseEntity` → `TUser`, `TTask` (campos comuns `Id`, `CreatedAt`) |
| **Polimorfismo** | `IUserRepository` implementada por `TMemoryUserRepository` e `TSQLServerUserRepository` |
| **RTTI** | `TRttiMapper` lê atributos `[TableName]`, `[Column]`, `[PrimaryKey]` para gerar SQL dinamicamente |

### Padrões de Projeto

- **Abstract Factory** (`TRepositoryFactory`): Cria repositórios Memory ou SQL Server
- **Factory Method** (`TServiceFactory`): Cria serviços injetando dependências
- **Repository Pattern**: Abstração do acesso a dados via interfaces genéricas
- **Middleware Pattern**: Autenticação JWT como middleware Horse

## Estrutura de Dados (SQL Server)

### Tabela Users

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| Id | INT IDENTITY | Chave primária, auto-incremento |
| Name | NVARCHAR(200) | Nome do usuário |
| Email | NVARCHAR(255) | E-mail (UNIQUE) |
| PasswordHash | NVARCHAR(500) | Hash SHA-256 da senha |
| Salt | NVARCHAR(100) | Salt aleatório para o hash |
| CreatedAt | DATETIME2 | Data de criação |

### Tabela Tasks

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| Id | INT IDENTITY | Chave primária, auto-incremento |
| UserId | INT FK | Referência ao usuário dono |
| Title | NVARCHAR(300) | Título da tarefa |
| Description | NVARCHAR(MAX) | Descrição (opcional) |
| Priority | INT | 1=Baixa, 2=Média, 3=Alta, 4=Crítica |
| Status | INT | 0=Pendente, 1=Em Andamento, 2=Concluída |
| CreatedAt | DATETIME2 | Data de criação |
| UpdatedAt | DATETIME2 | Última atualização |
| CompletedAt | DATETIME2 | Data de conclusão |

## Endpoints da API

### Públicos

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/api/users/register` | Cadastro de novo usuário |
| POST | `/api/users/login` | Autenticação (retorna JWT) |
| GET | `/api/health` | Health check |

### Protegidos (JWT no header `Authorization: Bearer <token>`)

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/tasks` | Listar tarefas do usuário |
| POST | `/api/tasks` | Criar nova tarefa |
| PUT | `/api/tasks/:id/status` | Atualizar status |
| DELETE | `/api/tasks/:id` | Remover tarefa |
| GET | `/api/tasks/stats` | Estatísticas (desafio SQL) |

### Desafio SQL - Estatísticas

O endpoint `/api/tasks/stats` executa as seguintes queries no SQL Server (escopo do usuário autenticado):

```sql
-- Total de tarefas
SELECT COUNT(*) AS Total FROM [Tasks] WHERE [UserId] = :UserId

-- Média de prioridade das tarefas pendentes
SELECT ISNULL(AVG(CAST([Priority] AS FLOAT)), 0) AS AvgPriority
FROM [Tasks] WHERE [UserId] = :UserId AND [Status] = 0

-- Tarefas concluídas nos últimos 7 dias
SELECT COUNT(*) AS Completed FROM [Tasks]
WHERE [UserId] = :UserId AND [Status] = 2
  AND [CompletedAt] >= DATEADD(DAY, -7, GETDATE())
```

## Como Executar

### Pré-requisitos

- Delphi 10.4+ (Alexandria ou superior)
- [Horse Framework](https://github.com/HashLoad/horse) (via Boss ou manualmente)
- [Horse-Jhonson](https://github.com/HashLoad/jhonson) (middleware JSON)
- SQL Server (opcional - roda em memória por padrão)

### Dependências (instalar via Boss)

```bash
boss install horse
boss install jhonson
```

### 1. Servidor

1. Abra `Server/TaskManagerServer.dpr` no Delphi
2. Compile e execute (F9)
3. O servidor inicia na porta 9000

> **Nota**: Por padrão, o servidor usa repositório em memória. Para usar SQL Server, altere `LUseDatabase := True` no programa principal e execute o script `sql/001_Schema.sql`.

### 2. Cliente VCL

1. Certifique-se de que o servidor está rodando
2. Abra `Client/TaskManagerClient.dpr` no Delphi
3. Compile e execute (F9)
4. Cadastre-se e faça login

### 3. Testes

1. Abra `Tests/TaskManagerTests.dpr` no Delphi
2. Compile e execute (F9)
3. Os testes rodam no console sem dependência de banco

## Cobertura de Testes

### TUserServiceTests (7 testes)
- ✅ Cadastro bem-sucedido
- ✅ E-mail duplicado → erro
- ✅ Login válido → retorna JWT
- ✅ Senha incorreta → erro
- ✅ E-mail inexistente → erro
- ✅ Nome vazio → erro
- ✅ Senha curta → erro

### TTaskServiceTests (13 testes)
- ✅ Criação de tarefa vinculada ao usuário
- ✅ Título vazio → erro
- ✅ Prioridade inválida → erro
- ✅ Listagem retorna apenas tarefas do usuário
- ✅ Listagem nunca retorna tarefas de outros
- ✅ Atualização de status próprio → sucesso
- ✅ Atualização de tarefa alheia → 403 Forbidden
- ✅ Conclusão define CompletedAt
- ✅ Remoção própria → sucesso
- ✅ Remoção de tarefa alheia → 403 Forbidden
- ✅ Remoção inexistente → 404 Not Found
- ✅ Estatísticas: total de tarefas
- ✅ Estatísticas: média de prioridade pendentes
- ✅ Estatísticas: concluídas últimos 7 dias

### TRttiMapperTests (12 testes)
- ✅ Leitura correta de [TableName] para TUser e TTask
- ✅ Leitura correta de [Column] (Email, UserId)
- ✅ Detecção de [PrimaryKey] e [AutoIncrement]
- ✅ INSERT exclui campos AutoIncrement
- ✅ INSERT contém colunas corretas
- ✅ UPDATE tem cláusula WHERE
- ✅ SELECT por Id correto
- ✅ SELECT All correto
- ✅ DELETE correto
- ✅ GetPropertyValue lê corretamente
- ✅ SetPropertyValue escreve corretamente

**Total: 32 testes cobrindo caminho feliz e caminho de erro.**

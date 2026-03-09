# TaskManager BDMG

Projeto completo para a Prova Técnica de Desenvolvedor Delphi — BDMG.

## Estrutura do Projeto

```
TaskManager/
├── Server/                              # Parte 1 — API REST (Horse)
│   ├── TaskManagerServer.dpr            # Programa principal do servidor
│   ├── server-config.json               # Configuração de banco, porta e JWT
│   ├── sql/
│   │   └── 001_Schema.sql              # Script de criação do banco SQL Server
│   └── src/
│       ├── Config/                      # Leitura de configurações externas
│       │   └── TaskManager.Config.Server.pas
│       ├── Attributes/                  # Atributos RTTI customizados (ORM)
│       │   └── TaskManager.Attributes.pas
│       ├── Entities/                    # Model (M do MVC)
│       │   ├── TaskManager.Entities.Base.pas    # Classe abstrata base
│       │   ├── TaskManager.Entities.User.pas    # Entidade Usuário
│       │   └── TaskManager.Entities.Task.pas    # Entidade Tarefa
│       ├── Repositories/               # Camada de acesso a dados
│       │   ├── TaskManager.Repositories.Interfaces.pas   # Interfaces genéricas
│       │   ├── TaskManager.Repositories.Memory.pas       # Mock (testes)
│       │   ├── TaskManager.Repositories.SQLServer.pas    # Produção
│       │   └── TaskManager.RTTI.Mapper.pas               # ORM via RTTI
│       ├── Services/                   # Regras de negócio
│       │   ├── TaskManager.Services.Interfaces.pas
│       │   ├── TaskManager.Services.User.pas
│       │   └── TaskManager.Services.Task.pas
│       ├── Controllers/                # Controller (C do MVC)
│       │   ├── TaskManager.Controllers.User.pas
│       │   └── TaskManager.Controllers.Task.pas
│       ├── Middleware/
│       │   └── TaskManager.Middleware.Auth.pas   # Validação JWT + TJWTAuthHelper
│       ├── Factories/
│       │   └── TaskManager.Factories.pas         # Abstract Factory
│       └── Utils/
│           ├── TaskManager.Utils.Hash.pas        # SHA-256 + Salt
│           └── TaskManager.Utils.JWT.pas         # Geração/Validação JWT (HS256)
│
├── Client/                              # Parte 2 — Aplicação VCL
│   ├── TaskManagerClient.dpr            # Programa principal do cliente
│   ├── client-config.json               # Configuração de host, porta e protocolo
│   └── src/
│       ├── Config/                      # Leitura de configurações externas
│       │   └── TaskManager.Client.Config.pas
│       ├── Forms/                       # View (V do MVC)
│       │   ├── TaskManager.Client.Forms.Login.pas/.dfm
│       │   ├── TaskManager.Client.Forms.Register.pas/.dfm
│       │   └── TaskManager.Client.Forms.Main.pas/.dfm
│       └── Services/
│           └── TaskManager.Client.ApiService.pas   # REST Client nativo
│
├── Tests/                               # Parte 3 — Testes Unitários (DUnitX)
│   ├── TaskManagerTests.dpr             # Runner dos testes
│   └── src/
│       ├── TaskManager.Tests.UserService.pas      # Testes de usuário (7)
│       ├── TaskManager.Tests.TaskService.pas      # Testes de tarefa (14)
│       └── TaskManager.Tests.RttiMapper.pas       # Testes de RTTI/ORM (14)
│
└── README.md
```

## Arquitetura

### Padrão MVC

- **Model**: Entidades (`TBaseEntity`, `TUser`, `TTask`) com atributos RTTI para mapeamento ORM
- **View**: Formulários VCL (`frmLogin`, `frmRegister`, `frmMain`) com botões customizados e hover effects
- **Controller**: Controllers REST (`TUserController`, `TTaskController`) que delegam para serviços

### Princípios OOP Aplicados

| Princípio | Implementação |
|-----------|---------------|
| **Abstração** | Interfaces `IRepository<T>`, `IUserService`, `ITaskService`; classes abstratas |
| **Encapsulamento** | Campos `private` (prefixo `F`) com `property` em todas as entidades |
| **Herança** | `TBaseEntity` → `TUser`, `TTask` (campos comuns `Id`, `CreatedAt`) |
| **Polimorfismo** | `IUserRepository` implementada por `TMemoryUserRepository` e `TSQLServerUserRepository` |
| **RTTI** | `TRttiMapper` lê atributos `[TableName]`, `[Column]`, `[PrimaryKey]` para gerar SQL dinamicamente |

### Padrões de Projeto

- **Abstract Factory** (`TRepositoryFactory`): Cria repositórios Memory ou SQL Server
- **Factory Method** (`TServiceFactory`): Cria serviços injetando dependências
- **Repository Pattern**: Abstração do acesso a dados via interfaces genéricas
- **Middleware Pattern**: Autenticação JWT como middleware Horse (`TAuthMiddleware`)

## Configuração via JSON

### Servidor (`server-config.json`)

O servidor carrega suas configurações de um arquivo JSON no mesmo diretório do executável. Se o arquivo não existir, valores padrão são utilizados.

```json
{
  "database": {
    "useDatabase": true,
    "driverID": "MSSQL",
    "server": "localhost",
    "database": "TaskManagerDB",
    "authentication": "windows",
    "username": "",
    "password": "",
    "encrypt": "no",
    "trustServerCertificate": "yes"
  },
  "server": {
    "port": 9000
  },
  "jwt": {
    "secretKey": "TaskManager_BDMG_SecretKey_2026!@#",
    "expirationHours": 24
  }
}
```

| Campo | Descrição |
|-------|-----------|
| `database.useDatabase` | `true` = SQL Server, `false` = repositório em memória |
| `database.authentication` | `"windows"` = credenciais do usuário logado no SO (OSAuthent), `"sqlserver"` = usuário e senha do JSON |
| `database.username` / `password` | Usados apenas quando `authentication = "sqlserver"` |
| `server.port` | Porta do servidor HTTP Horse |
| `jwt.secretKey` | Chave secreta para assinatura HMAC-SHA256 do JWT |
| `jwt.expirationHours` | Tempo de vida do token em horas |

### Cliente (`client-config.json`)

O cliente carrega host, porta e protocolo de um arquivo JSON. Se ausente, usa `http://localhost:9000`.

```json
{
  "server": {
    "host": "localhost",
    "port": 9000,
    "protocol": "http"
  }
}
```

A URL base é montada automaticamente como `protocol://host:port`.

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
| GET | `/api/tasks` | Listar tarefas do usuário autenticado |
| POST | `/api/tasks` | Criar nova tarefa |
| PUT | `/api/tasks/:id/status` | Atualizar status de uma tarefa |
| DELETE | `/api/tasks/:id` | Remover uma tarefa |
| GET | `/api/tasks/stats` | Estatísticas (desafio SQL) |

### Desafio SQL — Estatísticas

O endpoint `/api/tasks/stats` executa as seguintes queries no SQL Server, com escopo limitado ao usuário autenticado:

```sql
-- Total de tarefas do usuário
SELECT COUNT(*) AS Total
FROM [Tasks] WHERE [UserId] = :UserId

-- Média de prioridade das tarefas pendentes
SELECT ISNULL(AVG(CAST([Priority] AS FLOAT)), 0) AS AvgPriority
FROM [Tasks] WHERE [UserId] = :UserId AND [Status] = 0

-- Tarefas concluídas nos últimos 7 dias
SELECT COUNT(*) AS Completed
FROM [Tasks]
WHERE [UserId] = :UserId AND [Status] = 2
  AND [CompletedAt] >= DATEADD(DAY, -7, GETDATE())
```

## Como Executar

### Pré-requisitos

- Delphi 10.4+ (Alexandria ou superior)
- [Horse Framework](https://github.com/HashLoad/horse) (via Boss ou manualmente)
- [Horse-Jhonson](https://github.com/HashLoad/jhonson) (middleware JSON)
- SQL Server (opcional — roda em memória quando `useDatabase = false`)

### Dependências (instalar via Boss)

```bash
boss install horse
boss install jhonson
```

### 1. Servidor

1. Edite `Server/server-config.json` com as configurações do seu ambiente
2. Execute o script `Server/sql/001_Schema.sql` no SQL Server (se usando banco)
3. Abra `Server/TaskManagerServer.dpr` no Delphi
4. Compile e execute (F9)
5. O servidor inicia na porta configurada no JSON (padrão: 9000)

> Para rodar sem SQL Server, altere `"useDatabase": false` no JSON. O servidor usará repositório em memória.

### 2. Cliente VCL

1. Edite `Client/client-config.json` se o servidor não estiver em `localhost:9000`
2. Certifique-se de que o servidor está rodando
3. Abra `Client/TaskManagerClient.dpr` no Delphi
4. Compile e execute (F9)
5. Cadastre-se e faça login

### 3. Testes Unitários

1. Abra `Tests/TaskManagerTests.dpr` no Delphi
2. Compile e execute (F9)
3. Os testes rodam no console sem dependência de banco (usam repositório em memória)

## Cobertura de Testes

### TUserServiceTests — 7 testes

| # | Teste | Cenário |
|---|-------|---------|
| 1 | `Test_Register_Success` | Cadastro bem-sucedido gera Id, Hash e Salt |
| 2 | `Test_Login_Success_Returns_JWT` | Login válido retorna token JWT verificável |
| 3 | `Test_Register_DuplicateEmail_RaisesException` | E-mail duplicado → exceção |
| 4 | `Test_Login_WrongPassword_RaisesException` | Senha incorreta → exceção |
| 5 | `Test_Login_NonExistentEmail_RaisesException` | E-mail inexistente → exceção |
| 6 | `Test_Register_EmptyName_RaisesException` | Nome vazio → exceção |
| 7 | `Test_Register_ShortPassword_RaisesException` | Senha < 6 caracteres → exceção |

### TTaskServiceTests — 14 testes

| # | Teste | Cenário |
|---|-------|---------|
| 1 | `Test_CreateTask_Success` | Criação vinculada ao usuário autenticado |
| 2 | `Test_CreateTask_EmptyTitle_RaisesException` | Título vazio → exceção |
| 3 | `Test_CreateTask_InvalidPriority_RaisesException` | Prioridade fora de 1-4 → exceção |
| 4 | `Test_GetAllTasks_ReturnsOnlyUserTasks` | Listagem retorna apenas tarefas do próprio usuário |
| 5 | `Test_GetAllTasks_NeverReturnsOtherUserTasks` | Listagem nunca inclui tarefas de outros |
| 6 | `Test_UpdateStatus_OwnTask_Success` | Atualização de status da própria tarefa |
| 7 | `Test_UpdateStatus_OtherUserTask_Raises403` | Tarefa alheia → EForbiddenException (403) |
| 8 | `Test_UpdateStatus_Completed_SetsCompletedAt` | Conclusão preenche CompletedAt |
| 9 | `Test_DeleteTask_OwnTask_Success` | Remoção da própria tarefa |
| 10 | `Test_DeleteTask_OtherUserTask_Raises403` | Tarefa alheia → EForbiddenException (403) |
| 11 | `Test_DeleteTask_NonExistent_Raises404` | Tarefa inexistente → ENotFoundException (404) |
| 12 | `Test_Stats_TotalTaskCount` | Contagem total correta |
| 13 | `Test_Stats_AveragePendingPriority` | Média de prioridade apenas das pendentes |
| 14 | `Test_Stats_CompletedLast7Days` | Contagem de concluídas nos últimos 7 dias |

### TRttiMapperTests — 14 testes

| # | Teste | Cenário |
|---|-------|---------|
| 1 | `Test_GetTableName_User_ReturnsUsers` | Atributo `[TableName('Users')]` lido corretamente |
| 2 | `Test_GetTableName_Task_ReturnsTasks` | Atributo `[TableName('Tasks')]` lido corretamente |
| 3 | `Test_GetColumnMappings_User_ContainsEmail` | Coluna Email mapeada via `[Column]` |
| 4 | `Test_GetColumnMappings_Task_ContainsUserId` | Coluna UserId mapeada via `[Column]` |
| 5 | `Test_GetColumnMappings_User_IdIsPrimaryKey` | Atributo `[PrimaryKey]` detectado no Id |
| 6 | `Test_GetColumnMappings_User_IdIsAutoIncrement` | Atributo `[AutoIncrement]` detectado no Id |
| 7 | `Test_BuildInsertSQL_User_ExcludesId` | INSERT não contém campo AutoIncrement |
| 8 | `Test_BuildInsertSQL_User_ContainsColumns` | INSERT contém Name, Email, PasswordHash |
| 9 | `Test_BuildUpdateSQL_User_HasWhereClause` | UPDATE possui `WHERE [Id] = :Id` |
| 10 | `Test_BuildSelectByIdSQL_User_Correct` | SELECT * FROM [Users] WHERE [Id] = :Id |
| 11 | `Test_BuildSelectAllSQL_Task_Correct` | SELECT * FROM [Tasks] |
| 12 | `Test_BuildDeleteSQL_Task_Correct` | DELETE FROM [Tasks] WHERE [Id] = :Id |
| 13 | `Test_GetPropertyValue_ReadsCorrectly` | RTTI lê valor de propriedade corretamente |
| 14 | `Test_SetPropertyValue_WritesCorrectly` | RTTI escreve valor em propriedade corretamente |

### Resumo

| Fixture | Testes | Caminho Feliz | Caminho de Erro |
|---------|--------|---------------|-----------------|
| TUserServiceTests | 7 | 2 | 5 |
| TTaskServiceTests | 14 | 6 | 8 |
| TRttiMapperTests | 14 | 14 | 0 |
| **Total** | **35** | **22** | **13** |

Todos os 35 testes rodam sem dependência de banco de dados, utilizando `TMemoryUserRepository` e `TMemoryTaskRepository` como dublês de teste.

## Representação de execução do client VCL

### Login
<img width="475" height="474" alt="Screenshot 2026-03-09 081151" src="https://github.com/user-attachments/assets/186e4104-1860-4be6-809d-b21b56eb6afb" />

### Cadastro
<img width="472" height="584" alt="Screenshot 2026-03-09 081202" src="https://github.com/user-attachments/assets/bb03813f-27ea-4492-8175-21c6a0dcb319" />

### Gerenciamento de tarefas
<img width="990" height="445" alt="Screenshot 2026-03-09 081644" src="https://github.com/user-attachments/assets/4ab2d018-5497-4cd8-adae-cfa9db1e95a0" />

### Estatísticas
<img width="991" height="441" alt="Screenshot 2026-03-09 081653" src="https://github.com/user-attachments/assets/caa08165-2bc4-40d2-9c09-c8dfe057decd" />

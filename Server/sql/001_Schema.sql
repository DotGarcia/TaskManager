-- ============================================================================
-- TaskManager BDMG - Database Creation Script
-- SQL Server
-- ============================================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'TaskManagerDB')
BEGIN
    CREATE DATABASE TaskManagerDB;
END
GO

USE TaskManagerDB;
GO

-- ============================================================================
-- Tabela: Users
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[Users] (
        [Id]           INT            IDENTITY(1,1) NOT NULL,
        [Name]         NVARCHAR(200)  NOT NULL,
        [Email]        NVARCHAR(255)  NOT NULL,
        [PasswordHash] NVARCHAR(500)  NOT NULL,
        [Salt]         NVARCHAR(100)  NOT NULL,
        [CreatedAt]    DATETIME2      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_Users_Email] UNIQUE ([Email])
    );
END
GO

-- ============================================================================
-- Tabela: Tasks
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Tasks]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[Tasks] (
        [Id]          INT            IDENTITY(1,1) NOT NULL,
        [UserId]      INT            NOT NULL,
        [Title]       NVARCHAR(300)  NOT NULL,
        [Description] NVARCHAR(MAX)  NULL,
        [Priority]    INT            NOT NULL DEFAULT 1,  -- 1=Baixa, 2=Media, 3=Alta, 4=Critica
        [Status]      INT            NOT NULL DEFAULT 0,  -- 0=Pendente, 1=EmAndamento, 2=Concluida
        [CreatedAt]   DATETIME2      NOT NULL DEFAULT GETDATE(),
        [UpdatedAt]   DATETIME2      NULL,
        [CompletedAt] DATETIME2      NULL,
        CONSTRAINT [PK_Tasks] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Tasks_Users] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([Id])
    );
END
GO

-- Index para consultas por usuario
CREATE NONCLUSTERED INDEX [IX_Tasks_UserId] ON [dbo].[Tasks] ([UserId])
    INCLUDE ([Status], [Priority], [CompletedAt]);
GO

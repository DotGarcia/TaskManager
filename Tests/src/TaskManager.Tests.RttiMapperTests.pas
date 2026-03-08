unit TaskManager.Tests.RttiMapperTests;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Rtti,
  TaskManager.Entities,
  TaskManager.Attributes,
  TaskManager.RTTI.Mapper;

type
  /// <summary>
  /// Testes unitários para o mapeamento RTTI.
  /// Valida que os atributos customizados são lidos corretamente
  /// e que as queries SQL são geradas de forma correta.
  /// </summary>
  [TestFixture]
  TRttiMapperTests = class
  public
    [Setup]
    procedure Setup;

    // ===== Leitura de atributos =====

    [Test]
    [TestCase('TUser deve ter TableName = Users')]
    procedure Test_GetTableName_User;

    [Test]
    [TestCase('TTask deve ter TableName = Tasks')]
    procedure Test_GetTableName_Task;

    [Test]
    [TestCase('TUser deve ter colunas corretas')]
    procedure Test_GetColumns_User;

    [Test]
    [TestCase('TTask deve ter colunas corretas')]
    procedure Test_GetColumns_Task;

    [Test]
    [TestCase('PK de TUser deve ser Id')]
    procedure Test_GetPrimaryKey_User;

    [Test]
    [TestCase('PK de TTask deve ser Id')]
    procedure Test_GetPrimaryKey_Task;

    [Test]
    [TestCase('Coluna CreatedAt deve ser ReadOnly')]
    procedure Test_CreatedAt_IsReadOnly;

    [Test]
    [TestCase('Coluna Id deve ser AutoIncrement')]
    procedure Test_Id_IsAutoIncrement;

    // ===== Geração de SQL =====

    [Test]
    [TestCase('INSERT para TUser gerado corretamente')]
    procedure Test_GenerateInsertSQL_User;

    [Test]
    [TestCase('INSERT para TTask gerado corretamente')]
    procedure Test_GenerateInsertSQL_Task;

    [Test]
    [TestCase('INSERT não deve incluir campos AutoIncrement')]
    procedure Test_GenerateInsertSQL_ExcludesAutoIncrement;

    [Test]
    [TestCase('INSERT não deve incluir campos ReadOnly')]
    procedure Test_GenerateInsertSQL_ExcludesReadOnly;

    [Test]
    [TestCase('UPDATE para TUser gerado corretamente')]
    procedure Test_GenerateUpdateSQL_User;

    [Test]
    [TestCase('UPDATE deve conter WHERE com PK')]
    procedure Test_GenerateUpdateSQL_HasWhereClause;

    [Test]
    [TestCase('SELECT por Id gerado corretamente')]
    procedure Test_GenerateSelectByIdSQL_User;

    [Test]
    [TestCase('SELECT ALL gerado corretamente')]
    procedure Test_GenerateSelectAllSQL_Task;

    [Test]
    [TestCase('DELETE gerado corretamente')]
    procedure Test_GenerateDeleteSQL_Task;

    [Test]
    [TestCase('SELECT WHERE gerado corretamente')]
    procedure Test_GenerateSelectWhereSQL;

    // ===== GetPropertyValue / SetPropertyValue =====

    [Test]
    [TestCase('GetPropertyValue lê valor correto')]
    procedure Test_GetPropertyValue;

    [Test]
    [TestCase('SetPropertyValue define valor correto')]
    procedure Test_SetPropertyValue;
  end;

implementation

{ TRttiMapperTests }

procedure TRttiMapperTests.Setup;
begin
  // Nada a configurar — TRttiMapper usa class methods
end;

// ===== Leitura de atributos =====

procedure TRttiMapperTests.Test_GetTableName_User;
begin
  Assert.AreEqual('Users', TRttiMapper.GetTableName<TUser>);
end;

procedure TRttiMapperTests.Test_GetTableName_Task;
begin
  Assert.AreEqual('Tasks', TRttiMapper.GetTableName<TTask>);
end;

procedure TRttiMapperTests.Test_GetColumns_User;
var
  LColumns: TArray<TColumnMapping>;
  LFound: Boolean;
  LCol: TColumnMapping;
begin
  LColumns := TRttiMapper.GetColumns<TUser>;

  // Deve ter pelo menos Id, Name, Email, Password, Salt, CreatedAt
  Assert.IsTrue(Length(LColumns) >= 6,
    Format('TUser deve ter pelo menos 6 colunas mapeadas, encontrou %d', [Length(LColumns)]));

  // Verifica que coluna "Email" existe
  LFound := False;
  for LCol in LColumns do
  begin
    if LCol.ColumnName = 'Email' then
    begin
      LFound := True;
      Assert.AreEqual('Email', LCol.PropertyName);
      Break;
    end;
  end;
  Assert.IsTrue(LFound, 'Coluna Email deve estar mapeada');
end;

procedure TRttiMapperTests.Test_GetColumns_Task;
var
  LColumns: TArray<TColumnMapping>;
begin
  LColumns := TRttiMapper.GetColumns<TTask>;

  // TTask: Id, UserId, Title, Description, Priority, Status, DueDate, CompletedAt, CreatedAt
  Assert.IsTrue(Length(LColumns) >= 9,
    Format('TTask deve ter pelo menos 9 colunas, encontrou %d', [Length(LColumns)]));
end;

procedure TRttiMapperTests.Test_GetPrimaryKey_User;
var
  LPK: TColumnMapping;
begin
  LPK := TRttiMapper.GetPrimaryKeyColumn<TUser>;
  Assert.AreEqual('Id', LPK.ColumnName, 'PK de TUser deve ser coluna Id');
  Assert.IsTrue(LPK.IsPrimaryKey);
end;

procedure TRttiMapperTests.Test_GetPrimaryKey_Task;
var
  LPK: TColumnMapping;
begin
  LPK := TRttiMapper.GetPrimaryKeyColumn<TTask>;
  Assert.AreEqual('Id', LPK.ColumnName, 'PK de TTask deve ser coluna Id');
end;

procedure TRttiMapperTests.Test_CreatedAt_IsReadOnly;
var
  LColumns: TArray<TColumnMapping>;
  LCol: TColumnMapping;
  LFound: Boolean;
begin
  LColumns := TRttiMapper.GetColumns<TUser>;
  LFound := False;
  for LCol in LColumns do
  begin
    if LCol.ColumnName = 'CreatedAt' then
    begin
      LFound := True;
      Assert.IsTrue(LCol.IsReadOnly, 'CreatedAt deve ser ReadOnly');
      Break;
    end;
  end;
  Assert.IsTrue(LFound, 'Coluna CreatedAt deve existir');
end;

procedure TRttiMapperTests.Test_Id_IsAutoIncrement;
var
  LPK: TColumnMapping;
begin
  LPK := TRttiMapper.GetPrimaryKeyColumn<TUser>;
  Assert.IsTrue(LPK.IsAutoIncrement, 'Id deve ser AutoIncrement');
end;

// ===== Geração de SQL =====

procedure TRttiMapperTests.Test_GenerateInsertSQL_User;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.GenerateInsertSQL<TUser>;

  Assert.IsTrue(LSQL.StartsWith('INSERT INTO Users'),
    'SQL deve começar com INSERT INTO Users');
  Assert.IsTrue(LSQL.Contains('Name'), 'SQL deve conter coluna Name');
  Assert.IsTrue(LSQL.Contains('Email'), 'SQL deve conter coluna Email');
  Assert.IsTrue(LSQL.Contains('Password'), 'SQL deve conter coluna Password');
  Assert.IsTrue(LSQL.Contains(':Name'), 'SQL deve conter parâmetro :Name');
end;

procedure TRttiMapperTests.Test_GenerateInsertSQL_Task;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.GenerateInsertSQL<TTask>;

  Assert.IsTrue(LSQL.StartsWith('INSERT INTO Tasks'));
  Assert.IsTrue(LSQL.Contains('UserId'));
  Assert.IsTrue(LSQL.Contains('Title'));
  Assert.IsTrue(LSQL.Contains('Priority'));
end;

procedure TRttiMapperTests.Test_GenerateInsertSQL_ExcludesAutoIncrement;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.GenerateInsertSQL<TUser>;

  // A coluna Id (AutoIncrement) NÃO deve aparecer nos VALUES do INSERT
  // Verifica que não tem ":Id" na lista de parâmetros
  // (pode aparecer no texto como nome da tabela, mas não como parâmetro)
  Assert.IsFalse(LSQL.Contains(':Id'),
    'INSERT não deve conter parâmetro :Id (AutoIncrement)');
end;

procedure TRttiMapperTests.Test_GenerateInsertSQL_ExcludesReadOnly;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.GenerateInsertSQL<TUser>;

  Assert.IsFalse(LSQL.Contains(':CreatedAt'),
    'INSERT não deve conter parâmetro :CreatedAt (ReadOnly)');
end;

procedure TRttiMapperTests.Test_GenerateUpdateSQL_User;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.GenerateUpdateSQL<TUser>;

  Assert.IsTrue(LSQL.StartsWith('UPDATE Users SET'));
  Assert.IsTrue(LSQL.Contains('Name = :Name'));
  Assert.IsTrue(LSQL.Contains('Email = :Email'));
end;

procedure TRttiMapperTests.Test_GenerateUpdateSQL_HasWhereClause;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.GenerateUpdateSQL<TUser>;

  Assert.IsTrue(LSQL.Contains('WHERE Id = :Id'),
    'UPDATE deve ter cláusula WHERE com PK');
end;

procedure TRttiMapperTests.Test_GenerateSelectByIdSQL_User;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.GenerateSelectByIdSQL<TUser>;

  Assert.AreEqual('SELECT * FROM Users WHERE Id = :Id', LSQL);
end;

procedure TRttiMapperTests.Test_GenerateSelectAllSQL_Task;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.GenerateSelectAllSQL<TTask>;

  Assert.AreEqual('SELECT * FROM Tasks', LSQL);
end;

procedure TRttiMapperTests.Test_GenerateDeleteSQL_Task;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.GenerateDeleteSQL<TTask>;

  Assert.AreEqual('DELETE FROM Tasks WHERE Id = :Id', LSQL);
end;

procedure TRttiMapperTests.Test_GenerateSelectWhereSQL;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.GenerateSelectWhereSQL<TUser>('Email');

  Assert.AreEqual('SELECT * FROM Users WHERE Email = :Email', LSQL);
end;

// ===== GetPropertyValue / SetPropertyValue =====

procedure TRttiMapperTests.Test_GetPropertyValue;
var
  LUser: TUser;
  LValue: TValue;
begin
  LUser := TUser.Create;
  try
    LUser.Name := 'Teste RTTI';
    LValue := TRttiMapper.GetPropertyValue(LUser, 'Name');

    Assert.AreEqual('Teste RTTI', LValue.AsString);
  finally
    LUser.Free;
  end;
end;

procedure TRttiMapperTests.Test_SetPropertyValue;
var
  LUser: TUser;
begin
  LUser := TUser.Create;
  try
    TRttiMapper.SetPropertyValue(LUser, 'Email', TValue.From<string>('rtti@test.com'));

    Assert.AreEqual('rtti@test.com', LUser.Email);
  finally
    LUser.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TRttiMapperTests);

end.

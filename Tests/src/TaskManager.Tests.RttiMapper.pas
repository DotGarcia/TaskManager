unit TaskManager.Tests.RttiMapper;

interface

uses
  DUnitX.TestFramework, System.SysUtils,
  TaskManager.Attributes,
  TaskManager.Entities.Base,
  TaskManager.Entities.User,
  TaskManager.Entities.Task,
  TaskManager.RTTI.Mapper;

type
  /// <summary>
  /// Testes unitarios para TRttiMapper.
  /// Valida que os atributos RTTI sao lidos corretamente e que
  /// as queries SQL sao geradas de forma coerente.
  /// </summary>
  [TestFixture]
  TRttiMapperTests = class
  public
    [Setup]
    procedure Setup;

    // === TableName ===

    [Test]
    procedure Test_GetTableName_User_ReturnsUsers;

    [Test]
    procedure Test_GetTableName_Task_ReturnsTasks;

    // === Column Mappings ===

    [Test]
    procedure Test_GetColumnMappings_User_ContainsEmail;

    [Test]
    procedure Test_GetColumnMappings_Task_ContainsUserId;

    [Test]
    procedure Test_GetColumnMappings_User_IdIsPrimaryKey;

    [Test]
    procedure Test_GetColumnMappings_User_IdIsAutoIncrement;

    // === SQL Generation ===

    [Test]
    procedure Test_BuildInsertSQL_User_ExcludesId;

    [Test]
    procedure Test_BuildInsertSQL_User_ContainsColumns;

    [Test]
    procedure Test_BuildUpdateSQL_User_HasWhereClause;

    [Test]
    procedure Test_BuildSelectByIdSQL_User_Correct;

    [Test]
    procedure Test_BuildSelectAllSQL_Task_Correct;

    [Test]
    procedure Test_BuildDeleteSQL_Task_Correct;

    // === Property Value ===

    [Test]
    procedure Test_GetPropertyValue_ReadsCorrectly;

    [Test]
    procedure Test_SetPropertyValue_WritesCorrectly;
  end;

implementation

{ TRttiMapperTests }

procedure TRttiMapperTests.Setup;
begin
  // Nada especifico - TRttiMapper usa class methods
end;

// === TableName ===

procedure TRttiMapperTests.Test_GetTableName_User_ReturnsUsers;
begin
  Assert.AreEqual('Users', TRttiMapper.GetTableName(TUser));
end;

procedure TRttiMapperTests.Test_GetTableName_Task_ReturnsTasks;
begin
  Assert.AreEqual('Tasks', TRttiMapper.GetTableName(TTask));
end;

// === Column Mappings ===

procedure TRttiMapperTests.Test_GetColumnMappings_User_ContainsEmail;
var
  LMappings: TArray<TColumnMapping>;
  LMapping: TColumnMapping;
  LFound: Boolean;
begin
  LMappings := TRttiMapper.GetColumnMappings(TUser);
  LFound := False;
  for LMapping in LMappings do
  begin
    if LMapping.ColumnName = 'Email' then
    begin
      LFound := True;
      Break;
    end;
  end;
  Assert.IsTrue(LFound, 'Deve encontrar coluna Email nos mappings de TUser');
end;

procedure TRttiMapperTests.Test_GetColumnMappings_Task_ContainsUserId;
var
  LMappings: TArray<TColumnMapping>;
  LMapping: TColumnMapping;
  LFound: Boolean;
begin
  LMappings := TRttiMapper.GetColumnMappings(TTask);
  LFound := False;
  for LMapping in LMappings do
  begin
    if LMapping.ColumnName = 'UserId' then
    begin
      LFound := True;
      Break;
    end;
  end;
  Assert.IsTrue(LFound, 'Deve encontrar coluna UserId nos mappings de TTask');
end;

procedure TRttiMapperTests.Test_GetColumnMappings_User_IdIsPrimaryKey;
var
  LMappings: TArray<TColumnMapping>;
  LMapping: TColumnMapping;
begin
  LMappings := TRttiMapper.GetColumnMappings(TUser);
  for LMapping in LMappings do
  begin
    if LMapping.ColumnName = 'Id' then
    begin
      Assert.IsTrue(LMapping.IsPrimaryKey,
        'Coluna Id deve ser marcada como PrimaryKey');
      Exit;
    end;
  end;
  Assert.Fail('Coluna Id nao encontrada nos mappings');
end;

procedure TRttiMapperTests.Test_GetColumnMappings_User_IdIsAutoIncrement;
var
  LMappings: TArray<TColumnMapping>;
  LMapping: TColumnMapping;
begin
  LMappings := TRttiMapper.GetColumnMappings(TUser);
  for LMapping in LMappings do
  begin
    if LMapping.ColumnName = 'Id' then
    begin
      Assert.IsTrue(LMapping.IsAutoIncrement,
        'Coluna Id deve ser marcada como AutoIncrement');
      Exit;
    end;
  end;
  Assert.Fail('Coluna Id nao encontrada nos mappings');
end;

// === SQL Generation ===

procedure TRttiMapperTests.Test_BuildInsertSQL_User_ExcludesId;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.BuildInsertSQL(TUser);
  // Id e AutoIncrement, nao deve aparecer nos VALUES
  Assert.IsFalse(LSQL.Contains(':Id'),
    'INSERT nao deve conter :Id (campo AutoIncrement)');
end;

procedure TRttiMapperTests.Test_BuildInsertSQL_User_ContainsColumns;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.BuildInsertSQL(TUser);
  Assert.IsTrue(LSQL.Contains('[Name]'), 'INSERT deve conter coluna Name');
  Assert.IsTrue(LSQL.Contains('[Email]'), 'INSERT deve conter coluna Email');
  Assert.IsTrue(LSQL.Contains('[PasswordHash]'), 'INSERT deve conter coluna PasswordHash');
  Assert.IsTrue(LSQL.Contains(':Name'), 'INSERT deve conter parametro :Name');
end;

procedure TRttiMapperTests.Test_BuildUpdateSQL_User_HasWhereClause;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.BuildUpdateSQL(TUser);
  Assert.IsTrue(LSQL.Contains('WHERE [Id] = :Id'),
    'UPDATE deve ter clausula WHERE com Id');
  Assert.IsTrue(LSQL.Contains('SET'), 'UPDATE deve conter SET');
end;

procedure TRttiMapperTests.Test_BuildSelectByIdSQL_User_Correct;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.BuildSelectByIdSQL(TUser);
  Assert.IsTrue(LSQL.Contains('SELECT * FROM [Users]'),
    'SELECT deve referenciar tabela Users');
  Assert.IsTrue(LSQL.Contains('WHERE [Id] = :Id'),
    'SELECT deve filtrar por Id');
end;

procedure TRttiMapperTests.Test_BuildSelectAllSQL_Task_Correct;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.BuildSelectAllSQL(TTask);
  Assert.AreEqual('SELECT * FROM [Tasks]', LSQL);
end;

procedure TRttiMapperTests.Test_BuildDeleteSQL_Task_Correct;
var
  LSQL: string;
begin
  LSQL := TRttiMapper.BuildDeleteSQL(TTask);
  Assert.IsTrue(LSQL.Contains('DELETE FROM [Tasks]'),
    'DELETE deve referenciar tabela Tasks');
  Assert.IsTrue(LSQL.Contains('WHERE [Id] = :Id'),
    'DELETE deve filtrar por Id');
end;

// === Property Value ===

procedure TRttiMapperTests.Test_GetPropertyValue_ReadsCorrectly;
var
  LUser: TUser;
  LValue: string;
begin
  LUser := TUser.Create;
  try
    LUser.Email := 'test@example.com';
    LValue := TRttiMapper.GetPropertyValue(LUser, 'Email').AsString;
    Assert.AreEqual('test@example.com', LValue);
  finally
    LUser.Free;
  end;
end;

procedure TRttiMapperTests.Test_SetPropertyValue_WritesCorrectly;
var
  LUser: TUser;
begin
  LUser := TUser.Create;
  try
    TRttiMapper.SetPropertyValue(LUser, 'Name', 'Garcia');
    Assert.AreEqual('Garcia', LUser.Name);
  finally
    LUser.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TRttiMapperTests);

end.

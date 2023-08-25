# Start-AzSqlInstanceDatabaseLogReplay `
#     -ResourceGroupName "Pacha" `
#     -InstanceName "pachami" `
#     -Name "PachadataFormation" `
# 	-Collation "SQL_Latin1_General_CP1_CI_AS" `
#     -StorageContainerUri "https://pachasql.blob.core.windows.net/backups" `
#     -StorageContainerIdentity SharedAccessSignature `
# 	-StorageContainerSasToken "si=backups&spr=https&sv=2022-11-02&sr=c&sig=PiooKNXJ6fW6RH8C7vHhGFGzr2jyaSclh50zCE6zImY%3D" `
# 	-AutoCompleteRestore `
#     -LastBackupName "PachaDataFormation_LOG_20230818_150734.trn"

Start-AzSqlInstanceDatabaseLogReplay `
    -ResourceGroupName "Pacha" `
    -InstanceName "pachami" `
    -Name "PachadataFormation" `
	-Collation "SQL_Latin1_General_CP1_CI_AS" `
    -StorageContainerUri "https://pachasql.blob.core.windows.net/backups/PachaDataFormation" `
    -StorageContainerIdentity ManagedIdentity `
	-AutoCompleteRestore `
    -LastBackupName "PachaDataFormation_LOG_20230818_154111.trn"

    
@isTest
private class BulkManageDataControllerTest {
    @isTest
    private static void processRecordsInsert() {
        Account acc1 = new Account(Name = 'testName',Description = 'testDescription');
        Account acc2 = new Account(Description = 'testDescription'); 
        List<Account> accs = new List<Account>{acc1,acc2};
        test.startTest();
        BulkManageDataController.CSVToSObjectWrapper result = BulkManageDataController.processRecords(accs,'Insert',new List<String>{'Name','Description'});
        test.stopTest();
        assert.areEqual(result.successes.size(),1,'The acc1 insert should work');
        assert.areEqual(result.failures.size(),1,'The acc2 insert should fail');
    }

    @isTest
    private static void processRecordsUpdate() {
        Account acc1 = new Account(Name = 'testName',Description = 'testDescription');
        insert acc1;
        acc1.Description = 'testUpdated';
        test.startTest();
        BulkManageDataController.CSVToSObjectWrapper result = BulkManageDataController.processRecords(new List<Account>{acc1},'Update',new List<String>{'Name','Description'});
        test.stopTest();
        assert.areEqual(result.successes.size(),1,'The acc1 update should work');
        assert.areEqual(result.failures.isEmpty(),true,'Any error was expected');

        assert.areEqual(((Account)result.records[0]).Description,'testUpdated','The acc1 was not updated as expected');

    }
}
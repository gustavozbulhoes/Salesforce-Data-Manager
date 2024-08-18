@isTest
private class BulkManageDataControllerTest {
    @TestSetup
    static void setupData(){
        Manage_Data_Group__c accessGroup = new  Manage_Data_Group__c(name = 'test');
        insert accessGroup;
        Manage_Data_Object__c manageOpp = new Manage_Data_Object__c(Allowed_Operations__c = 'Insert;Update', Name = 'Opportunity', Manage_Data_Group__c = accessGroup.Id);
        Manage_Data_Object__c manageAcc = new Manage_Data_Object__c(Allowed_Operations__c = 'Insert;Update', Name = 'Account', Manage_Data_Group__c = accessGroup.Id);
        List<Manage_Data_Object__c> manageDataObjects = new List<Manage_Data_Object__c>{manageOpp,manageAcc};
        insert manageDataObjects;
        Manage_Data_Users__c userPerm = new Manage_Data_Users__c(Group__c = accessGroup.Id, User__c = UserInfo.getUserId());
        insert userPerm;
    }

    @isTest
    private static void getAllowedObjectsAndOperations(){
        List<BulkManageDataController.AllowedObjectAndOperation> allowedObjectAndOperationResult;
        test.startTest();
        allowedObjectAndOperationResult = BulkManageDataController.getAllowedObjectsAndOperations(UserInfo.getUserId());
        test.stopTest();
        assert.areEqual(false, allowedObjectAndOperationResult.isEmpty(), 'allowedObjectAndOperationResult should be not empty due records in setup');
        Map<String,Set<String>> getOperationsFromObject = new Map<String,Set<String>>();
        for(BulkManageDataController.AllowedObjectAndOperation allowed:allowedObjectAndOperationResult){
            if(getOperationsFromObject.containsKey(allowed.objectName)){
                getOperationsFromObject.get(allowed.objectName).addAll(allowed.operations);
            } else {
                getOperationsFromObject.put(allowed.objectName,allowed.operations);
            }
        }
        Set<String> allowedObjects = getOperationsFromObject.keySet();
        assert.areEqual(true, allowedObjects.contains('Account'), 'Account object was expected due setup data');
        assert.areEqual(true, allowedObjects.contains('Opportunity'), 'Opportunity object was expected due setup data');
        Set<String> accountAllowedOperations = getOperationsFromObject.get('Account');
        Set<String> opportunityAllowedOperations = getOperationsFromObject.get('Account');
        assert.areEqual(true, accountAllowedOperations.contains('Insert'), 'Account Insert was expected');
        assert.areEqual(true, accountAllowedOperations.contains('Update'), 'Account Update was expected');
        assert.areEqual(true, opportunityAllowedOperations.contains('Insert'), 'Opportunity Insert was expected');
        assert.areEqual(true, opportunityAllowedOperations.contains('Update'), 'Opportunity Update was expected');
    }

    @isTest
    private static void getFieldInfo(){
        List<BulkManageDataAction.FieldInfo> fieldsInfo = BulkManageDataAction.getFieldInfo('Account');
        Map<String,String> getLabelAndTypeFromName = new Map<String,String>();
        for(BulkManageDataAction.FieldInfo fieldInfo:fieldsInfo){
            getLabelAndTypeFromName.put(fieldInfo.fieldName,fieldInfo.fieldLabel + ' - ' + fieldInfo.fieldType);
        }
        assert.areEqual('Account Name - STRING',getLabelAndTypeFromName.get('Name'),'Label - Type of the standard Account.Name field was expected');
    }

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
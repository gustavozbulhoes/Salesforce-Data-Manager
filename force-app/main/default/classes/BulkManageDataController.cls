public with sharing class BulkManageDataController {
    @AuraEnabled
    public static CSVToSObjectWrapper processRecords(List<SObject> objects, String operationType, List<String> fields) {
        CSVToSObjectWrapper result = new CSVToSObjectWrapper();
        Database.SaveResult[] srList;
        result.successes = new List<Id>();
        result.failures = new List<String>();
        
        if (operationType == 'Insert') {
            srList = Database.insert(objects, false);
        } else if (operationType == 'Update') {
            srList = Database.update(objects, false);
        }

        for (Integer i = 0; i < srList.size(); i++) {
            if (srList[i].isSuccess()) {
                result.successes.add(srList[i].getId());
            } else {
                result.failures.add(srList[i].getErrors()[0].getMessage());
            }
        }

        result.records = objects;
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<AllowedObjectAndOperation> getAllowedObjectsAndOperations(Id userId){
        system.debug('userId --> ' + userId);
        Map<String,Set<String>> getOperationsFromObjectName = BulkManageDataAction.getAllowedObjectsAndOperationsMap(userId);
        List<AllowedObjectAndOperation> result = new List<AllowedObjectAndOperation>();
        for(String objectName:getOperationsFromObjectName.keySet()){
            AllowedObjectAndOperation allowedObjectOperation = new AllowedObjectAndOperation();
            allowedObjectOperation.objectName = objectName;
            allowedObjectOperation.operations = getOperationsFromObjectName.get(objectName);
            result.add(allowedObjectOperation);
        }
        system.debug('result --> ' + result);
        return result;
    }

    public class CSVToSObjectWrapper {
        @AuraEnabled
        public List<SObject> records { get; set; }

        @AuraEnabled
        public List<Id> successes { get; set; }

        @AuraEnabled
        public List<String> failures { get; set; }
    }

    public class AllowedObjectAndOperation {
        public String objectName { get; set; }
        public Set<String> operations { get; set; }
    }
}
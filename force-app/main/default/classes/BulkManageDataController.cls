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

        if (!fields.contains('Id')) {
            fields.add('Id');
        }

        result.records = objects;
        result.fields = fields;

        return result;
    }

    public class CSVToSObjectWrapper {
        @AuraEnabled
        public List<SObject> records { get; set; }

        @AuraEnabled
        public List<String> fields { get; set; }

        @AuraEnabled
        public List<Id> successes { get; set; }

        @AuraEnabled
        public List<String> failures { get; set; }
    }
}
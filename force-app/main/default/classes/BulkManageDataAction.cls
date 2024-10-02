public without sharing class BulkManageDataAction {
    
    public class FieldInfo {
        public String fieldName { get; set; }
        public String fieldLabel { get; set; }
        public String fieldType { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<FieldInfo> getFieldInfo(String objectName) {
        List<FieldInfo> fieldInfoList = new List<FieldInfo>();
        
        // Describe the object
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
        if (sObjectType == null) {
            throw new IllegalArgumentException('Object not found: ' + objectName);
        }
        Schema.DescribeSObjectResult describeSObjectResult = sObjectType.getDescribe();
        
        // Get the list of fields for the object
        Map<String, Schema.SObjectField> fieldsMap = describeSObjectResult.fields.getMap();
        
        for (Schema.SObjectField field : fieldsMap.values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            
            FieldInfo info = new FieldInfo();
            info.fieldName = fieldDescribe.getName();
            info.fieldLabel = fieldDescribe.getLabel();
            info.fieldType = fieldDescribe.getType().name();
            
            fieldInfoList.add(info);
        }
        
        return fieldInfoList;
    }

    public static Map<String,Set<String>> getAllowedObjectsAndOperationsMap(Id userId){
        //Check if the user has the permission
        Map<String,Set<String>> getOperationsFromObjectName = new Map<String,Set<String>>();
        List<Manage_Data_Users__c> manageDataUsers = [SELECT Id,Group__c FROM Manage_Data_Users__c WHERE User__c =: userId];
        if(manageDataUsers.isEmpty()){
            return getOperationsFromObjectName;
        }
        Set<Id> groupsIds = new Set<Id>();
        for(Manage_Data_Users__c manageDataUser:manageDataUsers){
            groupsIds.add(manageDataUser.Group__c);
        }
        if(groupsIds.isEmpty()){
            return getOperationsFromObjectName;
        }

        //Create a map considering that a user can be related to multiple groups
        List<Manage_Data_Object__c> allowedObjectsAndOperations = [SELECT Id,Name,Allowed_Operations__c FROM Manage_Data_Object__c WHERE Manage_Data_Group__c IN:groupsIds];
        for(Manage_Data_Object__c manageDataObject:allowedObjectsAndOperations){
            if(getOperationsFromObjectName.containsKey(manageDataObject.Name)){
                for(String allowedOperation:manageDataObject.Allowed_Operations__c.split(';')){
                    getOperationsFromObjectName.get(manageDataObject.Name).add(allowedOperation);
                }
            } else {
                Set<String> allowedOperationsSet = new Set<String>();
                allowedOperationsSet.addAll(manageDataObject.Allowed_Operations__c.split(';'));
                getOperationsFromObjectName.put(manageDataObject.Name,allowedOperationsSet);
            }
        }
        return getOperationsFromObjectName;
    }
    
}
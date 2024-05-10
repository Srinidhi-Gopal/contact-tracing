public with sharing class CTLocationTriggerHandler {
    public static void beforeInsertHandler(List<Location__c> newLocations){
        for(Location__c loc: newLocations){
            loc.Status__c = 'Green';
        }
    }
    public static void beforeUpdateHandler(List<Location__c> newRecords, Map<Id, Location__c> oldRecordMap){
        for(Location__c loc: newRecords){
            if(loc.Status__c != oldRecordMap.get(loc.Id).Status__c){
                loc.Status_Update_Date__c = Date.today();
            }
        }
    }
    public static void afterUpdateHandler(List<Location__c> newRecords, Map<Id, Location__c> oldRecordMap){
        Set<Id> locationIds = new Set<Id>();
        for(Location__c loc: newRecords){
            if(loc.Status__c == 'Red' && oldRecordMap.get(loc.Id).Status__c != 'Red'){
                locationIds.add(loc.Id);
            }
        }
        Set<Id> visitors = CTLocationController.getVisitors(locationIds);
        List<Person__c> personsToUpdate = new List<Person__c>();
        if(visitors != null && visitors.size() > 0)
        {
            for(Id v: visitors){
                personsToUpdate.add(new Person__c(Id=v, Health_Status__c='Yellow'));
            }
            update personsToUpdate;
        }
    }

}

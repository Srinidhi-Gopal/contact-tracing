public with sharing class CTPersonTriggerHandler {
    public static void beforeInsertHandler(List<Person__c> newPersons){
        for (Person__c per: newPersons){
            per.Health_Status__c = 'Green';
            per.Token__c = CTPersonController.getToken(per.Mobile__c);
        }
    }
    public static void beforeUpdateHandler(List<Person__c> newRecords, Map<Id, Person__c> oldRecordMap){
        for(Person__c per: newRecords){
            if(per.Health_Status__c != oldRecordMap.get(per.Id).Health_Status__c){
                per.Status_Update_Date__c = Date.today();
            }
        }
    }
    public static void afterUpdateHandler(List<Person__c> newRecords, Map<Id, Person__c> oldRecordMap){
        Set<Id> statusChange = new Set<Id>();
        Set<Id> redStatus = new Set<Id>();
        for(Person__c per: newRecords){
            if(per.Health_Status__c != oldRecordMap.get(per.Id).Health_Status__c){
                statusChange.add(per.Id);
            }
            if(per.Health_Status__c == 'Red' && oldRecordMap.get(per.Id).Health_Status__c != 'Red'){
                redStatus.add(per.Id);
            }
        }

        Set<Id> alreadyProcessed = new Set<Id>();
        alreadyProcessed.addAll(redStatus);

        Set<Id> orangeStatus = new Set<Id>();
        orangeStatus.addAll(CTPersonController.getCohibitant(redStatus, alreadyProcessed));
        Set<Id> primaryContacts = CTPersonController.getPrimaryContacts(redStatus, alreadyProcessed);
        orangeStatus.addAll(primaryContacts);

        Set<Id> yellowStatus = new Set<Id>();
        yellowStatus.addAll(CTPersonController.getNeighbours(redStatus, alreadyProcessed));
        yellowStatus.addAll(CTPersonController.getSecondaryContacts(primaryContacts, alreadyProcessed));

        List<Person__c> personsToUpdate = new List<Person__c>();
        for(Id pid: orangeStatus){
            personsToUpdate.add(new Person__c(id=pid, Health_Status__c='Orange'));
        }
        for(Id pid: yellowStatus){
            personsToUpdate.add(new Person__c(id=pid, Health_Status__c='Yellow'));
        }

        if(personsToUpdate.size() > 0){
            update personsToUpdate;
        }

        List<Location_Tracing__c> locationTraces = CTLocationTracingController.getLocationsByPersonIds(statusChange);
        if(locationTraces != null && locationTraces.size() > 0){
            Set<Id> locationIds = new Set<Id>();
            for(Location_Tracing__c lt: locationTraces){
                locationIds.add(lt.Location__c);
            }
            CTLocationController.updateRedScore(locationIds);
        }
    }
}

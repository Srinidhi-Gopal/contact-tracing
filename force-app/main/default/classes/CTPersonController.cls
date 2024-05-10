/**
 * @Description: People  Class Controller for the Contract Tracing Application
 * @Author: Srinidhi Gopal
 * @Last Modified On: 5May2024
 * @Last Modified By: Srinidhi Gopal
 * @Modification Logs
 * Ver  Date        Author              Modification
 * 1.0  5May2024    Srinidhi Gopal      Added getToken method
 * 1.1  5May2024    Srinidhi Gopal      Added getRecentHealthChanges, searchPeople, getPersonById methods
 */
public with sharing class CTPersonController {
    
    /**
     * Get a Token from Person Mobile Phone Number
     * @return String
     */
    public static String getToken(String mobilePhone){
        Blob targetBlob = Blob.valueOf(mobilePhone);
        Blob hash = Crypto.generateDigest('MD5', targetBlob);
        
        //Return the String value of the Blob
        return EncodingUtil.base64Encode(hash);
    }

    /**
     * Get latest 100 person records with changes
     * @return List<Person__c>
     */
    public static List<Person__c> getRecentHealthChanges(){
        return [
            SELECT Id,
                   Health_Status__c,
                   Mobile__c,
                   Name,
                   Status_Update_Date__c,
                   Token__c
              FROM Person__c
          ORDER BY Status_Update_Date__c DESC NULLS LAST
             LIMIT 100
        ];
    }

    /**
     * Search a Person by Name, Mobile and Token
     * @return List<Person__c>
     */
    public static List<Person__c> searchPeople(String searchTerm){
        searchTerm += '%';
        return [
            SELECT Id,
                   Health_Status__c,
                   Mobile__c,
                   Name,
                   Status_Update_Date__c,
                   Token__c
              FROM Person__c
             WHERE Name LIKE :searchTerm
                OR Mobile__c LIKE :searchTerm
                OR Token__c LIKE :searchTerm
          ORDER BY Status_Update_Date__c DESC NULLS LAST
        ];
    }

    /**
     * Get a Person record by its Id
     * @return Person__c
     */
    public static Person__c getPersonById(String personId){
        List<Person__c> personList = [
            SELECT Id,
                   Health_Status__c,
                   Mobile__c,
                   Name,
                   Status_Update_Date__c,
                   Token__c
              FROM Person__c
             WHERE Id = :personId 
        ];
        if (personList != null && personList.size() > 0) {
            return personList[0];
        }
        return null;
    }

    /**
     * Get a Person count for each Status
     * @return Map<String, Integer>
     */
    public static Map<String, Integer> getHealthStatusCount(){
        Map<String, Integer> healthStatusMap = new Map<String, Integer>();
        for(AggregateResult ar: [
            SELECT Health_Status__c, 
                   COUNT(id) statusCount
              FROM Person__c 
          GROUP BY Health_Status__c
        ]){
            healthStatusMap.put(String.valueOf(ar.get('Health_Status__c')), Integer.valueOf(ar.get('statusCount')));
        }
        return healthStatusMap;
    }

    /**
     * Get set of cohabitants of the set of persons passed in parameter
     * @return Set<Id>
     */
    public static Set<Id> getCohibitant(Set<Id> personIds, Set<Id> alreadyProcessed){
        List<String> healthStatuses = new List<String>{'Green', 'Yellow'};
        List<People_Tracing__c> peopleTraces = [
            SELECT Id, 
                   Contact_Date__c, 
                   Contact_Type__c, 
                   Person_1__c, 
                   Person_2__c
              FROM People_Tracing__c
             WHERE (Person_1__c IN :personIds OR Person_2__c IN :personIds)
               AND Contact_Type__c = 'Cohabitant'
               AND (Person_1__r.Health_Status__c IN :healthStatuses OR Person_2__r.Health_Status__c IN :healthStatuses)
        ];
        Set<Id> cohabitants = new Set<Id>();
        for(People_Tracing__c pt: peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                cohabitants.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!alreadyProcessed.contains(pt.Person_2__c)){
                cohabitants.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return cohabitants;
    }

    /**
     * Get set of neighbours of the set of persons passed in parameter
     * @return Set<Id>
     */
    public static Set<Id> getNeighbours(Set<Id> personIds, Set<Id> alreadyProcessed){
        List<People_Tracing__c> peopleTraces = [
            SELECT Id, 
                   Contact_Date__c, 
                   Contact_Type__c, 
                   Person_1__c, 
                   Person_2__c
              FROM People_Tracing__c
             WHERE (Person_1__c IN :personIds OR Person_2__c IN :personIds)
               AND Contact_Type__c = 'Neighbour'
               AND (Person_1__r.Health_Status__c = 'Green' OR Person_2__r.Health_Status__c = 'Green')
        ];
        Set<Id> neighbours = new Set<Id>();
        for(People_Tracing__c pt: peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                neighbours.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!alreadyProcessed.contains(pt.Person_2__c)){
                neighbours.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return neighbours;
    }

    /**
     * Get set of primary contacts of the set of persons passed in parameter
     * @return Set<Id>
     */
    public static Set<Id> getPrimaryContacts(Set<Id> personIds, Set<Id> alreadyProcessed){
        List<String> healthStatuses = new List<String>{'Green', 'Yellow'};
        List<People_Tracing__c> peopleTraces = [
            SELECT Id, 
                   Contact_Date__c, 
                   Contact_Type__c, 
                   Person_1__c, 
                   Person_2__c
              FROM People_Tracing__c
             WHERE (Person_1__c IN :personIds OR Person_2__c IN :personIds)
               AND Contact_Type__c = 'Other'
               AND (Person_1__r.Health_Status__c IN :healthStatuses OR Person_2__r.Health_Status__c IN :healthStatuses)
               AND Contact_Date__c = LAST_N_DAYS:10
        ];
        Set<Id> primaryContacts = new Set<Id>();
        for(People_Tracing__c pt: peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                primaryContacts.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!alreadyProcessed.contains(pt.Person_2__c)){
                primaryContacts.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return primaryContacts;
    }

    /**
     * Get set of secondary contacts of the set of persons passed in parameter
     * @return Set<Id>
     */
    public static Set<Id> getSecondaryContacts(Set<Id> primaryContactIds, Set<Id> alreadyProcessed){
        List<People_Tracing__c> peopleTraces = [
            SELECT Id, 
                   Contact_Date__c, 
                   Contact_Type__c, 
                   Person_1__c, 
                   Person_2__c
              FROM People_Tracing__c
             WHERE (Person_1__c IN :primaryContactIds OR Person_2__c IN :primaryContactIds)
               AND Contact_Type__c = 'Other'
               AND Contact_Date__c = LAST_N_DAYS:10
               AND (Person_1__r.Health_Status__c = 'Green' OR Person_2__r.Health_Status__c = 'Green')
        ];
        Set<Id> secondaryContacts = new Set<Id>();
        for(People_Tracing__c pt: peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                secondaryContacts.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!alreadyProcessed.contains(pt.Person_2__c)){
                secondaryContacts.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return secondaryContacts;
    }

}

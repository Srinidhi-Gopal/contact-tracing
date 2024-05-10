/**
 * @Description: People Tracing Class Controller for the Contract Tracing Application
 * @Author: Srinidhi Gopal
 * @Last Modified On: 5May2024
 * @Last Modified By: Srinidhi Gopal
 * @Modification Logs
 * Ver  Date        Author              Modification
 * 1.0  5May2024    Srinidhi Gopal      Added getTraces, checkDuplicates Methods
 * 1.1  
 */

public with sharing class CTPeopleTracingController {
    
    /**
     * Get all traces for a give Person Id
     * @return List<People_Tracing__c> 
     */
    public static List<People_Tracing__c> getTraces(String recordId){
        return [
            SELECT Id,
                   Contact_Date__c,
                   Person_1__c,
                   Person_1__r.Health_Status__c,
                   Person_1__r.Token__c,
                   Person_2__c,
                   Person_2__r.Health_Status__c,
                   Person_2__r.Token__c
              FROM People_Tracing__c
             WHERE Person_1__c = :recordId
                OR Person_2__c = :recordId
          ORDER BY Contact_Date__c DESC
        ];
    }

    /**
     * Get all deuplicate records in People_Tracing__c
     * @return List<People_Tracing__c> 
     */
    public static List<People_Tracing__c> checkDuplicates(List<People_Tracing__c> newPeopleTraces){
        //Create a common person Id List for person 1 and 2
        Set<Id> personIds = new Set<Id>();
        for (People_Tracing__c pt: newPeopleTraces) {
            personIds.add(pt.Person_1__c);
            personIds.add(pt.Person_2__c);
        }

        //Query exisitng records in People_Tracing__c comparing above list with Person_1__c and Person_2__c fields
        List<People_Tracing__c> exisitingPt = [
            SELECT ID,
                   Person_1__c,
                   Person_2__c
              FROM People_Tracing__c
             WHERE Person_1__c IN :personIds
                OR Person_2__c IN :personIds
        ];

        //Create a map, which tells every person(value in the set) a person(key in the set) has meet
        Map<Id, Set<Id>> existingMap = new Map<Id, Set<Id>>();
        if(exisitingPt != null && exisitingPt.size() > 0){
            for(People_Tracing__c pt: exisitingPt){
                if(! existingMap.containsKey(pt.Person_1__c)){
                    existingMap.put(pt.Person_1__c, new Set<Id>());
                }
                existingMap.get(pt.Person_1__c).add(pt.Person_2__c);

                if(! existingMap.containsKey(pt.Person_2__c)){
                    existingMap.put(pt.Person_2__c, new Set<Id>());
                }
                existingMap.get(pt.Person_2__c).add(pt.Person_1__c);
            }
        }

        //Loop over the parameter, check if either Person 1 has met Person 2 or if Person 2 has met Person 1. if so, its a duplicate
        List<People_Tracing__c> duplicates = new List<People_Tracing__c>();
        for(People_Tracing__c pt: newPeopleTraces){
            if(
                (existingMap.containsKey(pt.Person_1__c) && existingMap.get(pt.Person_1__c).contains(pt.Person_2__c))
                ||
                (existingMap.containsKey(pt.Person_2__c) && existingMap.get(pt.Person_2__c).contains(pt.Person_1__c))
            ){
                duplicates.add(pt);
            }
        }

        return duplicates;
    }

}

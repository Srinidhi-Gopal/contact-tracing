/**
 * @Description: Location Tracing Class Controller for the Contract Tracing Application
 * @Author: Srinidhi Gopal
 * @Last Modified On: 5May2024
 * @Last Modified By: Srinidhi Gopal
 * @Modification Logs
 * Ver  Date        Author              Modification
 * 1.0  5May2024    Srinidhi Gopal      Added getVisitors, getLocationsByPersonIds, getLocationsByLocationIds Methods
 * 1.1  5May2024    Srinidhi Gopal      Added checkDuplicates Method
 */
public with sharing class CTLocationTracingController {

    /**
     * Get Latest visitors for a location
     * @return List<Location_Tracing__c> 
     */
    public static List<Location_Tracing__c> getVisitors(String locationId){
        return [
            SELECT Id,
                   Name,
                   Person__c, 
                   Location__c,
                   Visit_Date__c,
                   Person__r.Token__c,
                   Person__r.Health_Status__c
              FROM Location_Tracing__c
             WHERE Location__c = :locationId
          ORDER BY Visit_Date__c DESC NULLS LAST
        ];
    }

    /**
     * Get all visitors by person Ids
     * @return List<Location_Tracing__c> 
     */
    public static List<Location_Tracing__c> getLocationsByPersonIds(Set<Id> personIds){
        return [
            SELECT Id,
                   Name,
                   Person__c, 
                   Location__c,
                   Visit_Date__c,
                   Person__r.Token__c,
                   Person__r.Health_Status__c
              FROM Location_Tracing__c
             WHERE Person__c IN :personIds
               AND Visit_Date__c = LAST_N_DAYS:10
          ORDER BY Visit_Date__c DESC NULLS LAST
        ];
    }

    /**
     * Get all visitors by locationIds
     * @return List<Location_Tracing__c> 
     */
    public static List<Location_Tracing__c> getLocationsByLocationIds(Set<Id> locationIds){
        return [
            SELECT Id,
                   Name,
                   Person__c, 
                   Location__c,
                   Visit_Date__c,
                   Person__r.Token__c,
                   Person__r.Health_Status__c
              FROM Location_Tracing__c
             WHERE Location__c IN :locationIds
               AND Person__r.Health_Status__c = 'Green'
               AND Visit_Date__c = LAST_N_DAYS:10
          ORDER BY Visit_Date__c DESC NULLS LAST
        ];
    }

    /**
     * Get Duplicat Location Tracing records
     * @return List<Location_Tracing__c> 
     */
    public static List<Location_Tracing__c> checkDuplicates(List<Location_Tracing__c> newLocationTraces){
        
        //Create 2 sets to store person ids and locations ids from the parameter
        Set<Id> personIds = new Set<Id>();
        Set<Id> locationIds = new Set<Id>();
        for (Location_Tracing__c lt: newLocationTraces){
            personIds.add(lt.Person__c);
            locationIds.add(lt.Location__c);
        }

        //query existing records from the Location_Tracing__c object
        List<Location_Tracing__c> existingLt = [
            SELECT Id,
                   Person__c, 
                   Location__c
              FROM Location_Tracing__c
             WHERE Location__c IN :locationIds
               AND Person__c IN :personIds
        ];

        //Create Map of Location Id => Set (Person Ids). Easier to find duplicates. eliminating nested for loops
        Map<Id, Set<Id>> existingMap = new Map<Id, Set<Id>>();
        if (existingLt != null && existingLt.size() > 0){
            for (Location_Tracing__c elt: existingLt){
                if(! existingMap.containsKey(elt.Location__c)){
                    existingMap.put(elt.Location__c, new Set<Id>());
                }
                existingMap.get(elt.Location__c).add(elt.Person__c);
            }
        }

        //Loop over parameter. If location id and person id found in above map, its a Duplicate
        List<Location_Tracing__c> duplicates = new List<Location_Tracing__c>();
        for(Location_Tracing__c lt: newLocationTraces){
            if(existingMap.containsKey(lt.Location__c) && existingMap.get(lt.Location__c).contains(lt.Person__c)){
                duplicates.add(lt);
            }
        }

        return duplicates;
    }

}

/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 03/08/2020
 */

@IsTest
private class LeadAssignmentTest {
    static Group hotQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Hot_Queue'];

    @IsTest
    static void flowSetsOwner() {
        Lead testLead = new Lead(Company = 'ACME Flow', Rating = 'Hot', LastName = 'Duck');

        Test.startTest();
        insert testLead;
        Test.stopTest();

        testLead = [SELECT OwnerId FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals(hotQueue.Id, testLead.OwnerId);
    }

    @IsTest
    static void flowSetsOwnerOnUpdate() {
        Lead testLead = new Lead(Company = 'ACME Flow', LastName = 'Duck');
        insert testLead;
        testLead = [SELECT OwnerId FROM Lead WHERE Id = :testLead.Id];

        System.assertNotEquals(hotQueue.Id, testLead.OwnerId);

        Test.startTest();
        testLead.Rating = 'Hot';
        update testLead;
        Test.stopTest();

        testLead = [SELECT OwnerId FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals(hotQueue.Id, testLead.OwnerId);
    }

    @IsTest
    static void pbSetsHot() {
        Lead testLead = new Lead(Company = 'ACME Unicorns PB', LastName = 'Duck');

        Test.startTest();
        insert testLead;
        Test.stopTest();

        testLead = [SELECT Rating FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals('Hot', testLead.Rating);
    }

    @IsTest
    static void pbAndFlowSetsHot() {
        Lead testLead = new Lead(Company = 'ACME Flow Unicorns PB', LastName = 'Duck');

        Test.startTest();
        insert testLead;
        Test.stopTest();

        testLead = [SELECT Rating, OwnerId FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals('Hot', testLead.Rating);
        System.assertEquals(hotQueue.Id, testLead.OwnerId);
    }

    @IsTest
    static void apexSetsOwner() {
        Lead testLead = new Lead(Company = 'ACME Apex', Rating = 'Hot', LastName = 'Duck');

        Test.startTest();
        insert testLead;
        Test.stopTest();

        testLead = [SELECT OwnerId FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals(hotQueue.Id, testLead.OwnerId);
    }

    @IsTest
    static void pbAndApexSetsHot() {
        Lead testLead = new Lead(Company = 'ACME Apex Unicorns PB', LastName = 'Duck');

        Test.startTest();
        insert testLead;
        Test.stopTest();

        testLead = [SELECT Rating, OwnerId FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals('Hot', testLead.Rating);
        System.assertEquals(hotQueue.Id, testLead.OwnerId);
    }
}
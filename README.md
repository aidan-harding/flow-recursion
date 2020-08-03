# The Dangers of Recursion with Before-Flows

Before Flows are neat - they allow efficient updates on the same object, without having to do an extra commit to the 
database. However, a note from the [Architect's Guide](https://quip.com/VJfCAFhEBO0W) says that they will never support
recursive execution.

On one hand, who cares about recursion? It hurts your head, right?

On the other hand, this introduces a sharp-edged restriction into your system that you really need to be aware 
of. If your system causes some accidental recursion (even if it's only once), your Flow won't do what you expect. Or, at
least, that was my concern. So, here's a project I built to test the theory.

You can download this and try it for yourself! Especially if it turns out that I've done something dumb, but I think 
it's right.

## The Flow

I built a Before Flow on Lead which put Leads with a Rating of "Hot" onto a Queue called "Hot Queue". More precisely,
if the Company contains "Flow" and Rating is "Hot", then query for a Queue called "Hot_Queue", and assign the owner over
to that Queue. Here are the Apex tests for it:

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
These tests pass

## The Process Builder

I built a Process Builder to do a same-object update on Lead the old way. If the Company contains both "Unicorn" and "PB",
then set the Rating to "Hot". Here's the Apex test for it:

    @IsTest
    static void pbSetsHot() {
        Lead testLead = new Lead(Company = 'ACME Unicorns PB', LastName = 'Duck');

        Test.startTest();
        insert testLead;
        Test.stopTest();

        testLead = [SELECT Rating FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals('Hot', testLead.Rating);
    }
    
This test passes

## The Apex

Finally, I built an Apex trigger to do a before insert/update assignment. If the Company contains 
"Apex" and Rating is "Hot", then query for a Queue called "Hot_Queue", and assign the owner over
to that Queue. Here's the Apex test for it:

    @IsTest
    static void apexSetsOwner() {
        Lead testLead = new Lead(Company = 'ACME Apex', Rating = 'Hot', LastName = 'Duck');

        Test.startTest();
        insert testLead;
        Test.stopTest();

        testLead = [SELECT OwnerId FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals(hotQueue.Id, testLead.OwnerId);
    }
This test passes

## What about the Flow Unicorn PB?

What happens if we combine PB updating the Rating to "Hot", and then Flow to assigning it to the Queue?

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

This test fails.

The execution order is: 

1. Lead insert begins
1. Flow runs, no need to reassign Owner as Rating is not Hot
1. PB runs and updates Rating to Hot
1. Flow doesn't run again because that would be recursion

## Won't someone think of the Apex Unicorns?!

What about if we try the same recursion, but with Apex Unicorns instead of Flow:

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

This passes. In Apex, recursion control is up to the developer. 

## Conclusions

This doesn't mean that Flow is bad, but there is certainly one scenario where you will have to be very careful: migrating
an org with a bunch of same-object PBs over to Flow. If you're half-migrated, then the PBs can interact with the Flows 
in the way above and give you results that weren't what you were expecting.   

I think of before triggers in Apex as being for enforcing database invariants. I know that if I've wired Hot Leads to be 
assigned to the Hot Queue with a before trigger, I can just forget about it. There will be no Hot Lead that isn't on 
the right queue. With Before Flows, this abstraction becomes [leaky](https://www.joelonsoftware.com/2002/11/11/the-law-of-leaky-abstractions/).

In the presence of a complicated system where automation can bounce from one object to another, recursive loops that 
stop Flow may be very hard to spot. And sometimes recursion isn't your choice - it may be thrust upon you be packages 
or by legacy code. So, you may very well be scratching your head about this one in the future.    
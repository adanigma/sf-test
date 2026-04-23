@IsTest
private class WelcomeEmailServiceTest {

    @IsTest
    static void testEmailSentOnContactInsert() {
        Test.startTest();
        insert new Contact(FirstName = 'Jane', LastName = 'Doe', Email = 'jane.doe@example.com');
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(1, invocations, 'Expected one email send call');
    }

    @IsTest
    static void testNoEmailWhenMissingAddress() {
        Test.startTest();
        insert new Contact(FirstName = 'John', LastName = 'Smith');
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(0, invocations, 'No email should be sent without an email address');
    }

    @IsTest
    static void testBulkEmailSend() {
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Alice', LastName = 'A', Email = 'alice@example.com'),
            new Contact(FirstName = 'Bob',   LastName = 'B', Email = 'bob@example.com'),
            new Contact(FirstName = 'No',    LastName = 'Email')
        };

        Test.startTest();
        WelcomeEmailService.sendWelcomeEmails(contacts);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(1, invocations, 'Expected one batched send call for multiple contacts');
    }
}

@IsTest
private class WelcomeEmailServiceTest {

    @IsTest
    static void testEmailSentOnContactInsert() {
        Test.startTest();
        insert new Contact(FirstName = 'Jane', LastName = 'Doe', Email = 'jane.doe@example.com');
        Test.stopTest();

        System.assertEquals(1, Limits.getEmailInvocations(), 'Expected one email send call');
    }

    @IsTest
    static void testNoEmailWhenMissingAddress() {
        Test.startTest();
        insert new Contact(FirstName = 'John', LastName = 'Smith');
        Test.stopTest();

        System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent without an email address');
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
        Test.stopTest();

        System.assertEquals(1, Limits.getEmailInvocations(), 'Expected one batched send call for multiple contacts');
    }
}

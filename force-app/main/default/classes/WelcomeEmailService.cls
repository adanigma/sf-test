public with sharing class WelcomeEmailService {

    public static void sendWelcomeEmails(List<Contact> newContacts) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Contact c : newContacts) {
            if (String.isBlank(c.Email)) continue;

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ c.Email });
            email.setSubject('Welcome to ' + UserInfo.getOrganizationName() + '!');
            email.setHtmlBody(buildEmailBody(c));
            email.setSaveAsActivity(false);
            emails.add(email);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }

    private static String buildEmailBody(Contact c) {
        String firstName = String.isBlank(c.FirstName) ? 'there' : c.FirstName;
        return '<html><body>'
            + '<h2>Welcome, ' + firstName + '!</h2>'
            + '<p>Thank you for signing up. We\'re thrilled to have you on board.</p>'
            + '<p>If you have any questions, feel free to reach out to us at any time.</p>'
            + '<p>Best regards,<br/>' + UserInfo.getOrganizationName() + ' Team</p>'
            + '</body></html>';
    }
}

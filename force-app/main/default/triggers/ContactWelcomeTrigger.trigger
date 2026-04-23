trigger ContactWelcomeTrigger on Contact (after insert) {
    WelcomeEmailService.sendWelcomeEmails(Trigger.new);
}

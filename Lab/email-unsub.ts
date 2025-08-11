/**
 * Unsubscribes from emails by searching for threads containing the word "unsubscribe",
 * extracting unsubscribe links from the email bodies, and sending requests to those links.
 * (Created to eliminate spam on my personal email account - Gillen)
 *
 * The function performs the following steps:
 * 1. Searches for Gmail threads containing the word "unsubscribe".
 * 2. Extracts unsubscribe links from the email bodies using a regular expression.
 * 3. Logs the number of found unsubscribe links.
 * 4. Sends HTTP requests to each unsubscribe link and logs the result.
 *
 * @returns {void}
 */
function unsubscribeEmails() {
  const threads = GmailApp.search('unsubscribe');
  const unsubscribeLinks = [];
  
  threads.forEach(thread => {
    const messages = thread.getMessages();
    messages.forEach(message => {
      const body = message.getBody();
      const regex = /https?:\/\/[^\s"']*unsubscribe[^\s"']*/gi;
      const links = body.match(regex);
      if (links) {
        unsubscribeLinks.push(...links);
      }
    });
  });

  Logger.log(`Found ${unsubscribeLinks.length} unsubscribe links.`);
  
  unsubscribeLinks.forEach(link => {
    try {
      const response = UrlFetchApp.fetch(link);
      if (response.getResponseCode() === 200) {
        Logger.log(`Successfully unsubscribed from: ${link}`);
      } else {
        Logger.log(`Failed to unsubscribe from: ${link}`);
      }
    } catch (error) {
      Logger.log(`Error unsubscribing from: ${link}`);
    }
  });
}

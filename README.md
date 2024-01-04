This is a NodeJS server that listens to web hooks from the PayCom HRIS, and interacts with FreshService and PayCom APIs. It maintains a small local database of jobs its completed, so that when the server starts up it can try to catch up on missed jobs.

It's triggered by new hire and termination events in PayCom. In the event of a new hire, it attempts to create an Active Directory account and an onboarding ticket in the FreshService help desk.
In the event of a termination, it creates a termination ticket in the help desk.

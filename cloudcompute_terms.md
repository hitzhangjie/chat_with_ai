Q:

> what's the differences btw IaaS, PaaS and SaaS?

A:

> - **Infrastructure as a Service **(IaaS) is when a provider spins up computers for you on demand with certain predefined virtual hardware configurations. It is mainly targeted at system administrators and DevOps staff who used to **rack and stack **hardware. Prob‐ ably the most famous of these services is Amazon EC2, but there is also Rackspace, Microsoft Azure, and Google Compute Engine, among others. The idea is that you specify the amount of RAM, CPU, and disk space you want in your “machine” and the provider spins it up for you in a matter of minutes.  This service is great since you no longer have to go through a long procurement process or fixed investment to obtain machines for your work. The drawback to this solution is that you are still responsible for installing and maintaining the operating system and server packages, configuring the network, and doing all the basic system administration. If you are reading this book, then system administration is probably not your area of expertise and you would likely rather spend your time writing code.
> - **Software as a Service **(SaaS) requires the least amount of maintenance and administra‐ tion on your part. With SaaS you just sign up for the service and start using it. You may be able to make some customizations, but you’re limited to what the service provider allows you to do. Common examples of SaaS are Gmail, Salesforce, and QuickBooks Online. While these services are useful because you can start working right away with little to configure or deploy, they are of limited use to programmers. They offer the least amount of customization of the three cloud services mentioned here. As Steve’s kids’ physical education teacher says: “You get what you get and you don’t get upset.
> - **Platform as a Service (PaaS)** is the middle ground between IaaS and SaaS. It is primarily targeted at application developers and programmers. With PaaS, you issue a few commands (which could be in a web console) and the platform spins up the development environment along with all the “server” pieces you need to run your application. For example, in this book we are going to make a Python web application with a PostgreSQL database. To get all this spun up, you issue one command and OpenShift does all the networking and server installs, and creates a Git repository for you. The OpenShift administrators will keep the operating system up-to-date, manage the network, and do all the sys admin work—leaving the developer to focus on writing code.
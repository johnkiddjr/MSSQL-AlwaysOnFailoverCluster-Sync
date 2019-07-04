# MSSQL-AlwaysOnFailoverCluster-Sync
Syncs users and SQL Agent jobs from Primary to all other servers in an Always-On Failover Cluster

# How to Use
1. Edit the Powershell script to include the name of your Availability Group Listener and a User-Created database to use for testing writeability
2. Run the SQL file on all your servers so the test sql function is in the master database
3. Schedule the PS1 script you edited to run on a regular basis on all servers as admin, using Task Scheduler or your choice of method

# How it Works
- The script will ask the availability group listener who the primary server is and check if it's the server running the script.
- If it is, it will then check all the jobs to ensure the first step of any job is to check if the server is the primary before executing
- If this step is missing, it adds the step to each job as the first step
- Once done, it syncs the jobs and users to all servers in the availability group

# Credits
I used 2 Powershell modules installed from the PSGallery.
- dbatools by the dbatools team : https://www.powershellgallery.com/packages/dbatools
- SqlServer by Microsoft : https://www.powershellgallery.com/packages/SqlServer

This was based on an article by IT Pro Today : https://www.itprotoday.com/windows-server/how-use-conditional-sql-agent-job-flows-alwayson-availability-groups

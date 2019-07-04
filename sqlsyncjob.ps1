#REQUIRED CONFIG
$sqlaglName = ""
$sqltestdbName = ""

#check if the modules we need are imported
if((Get-Module -ListAvailable -Name dbatools).Name -eq "dbatools" -and (Get-Module -ListAvailable -Name SqlServer).Name -eq "SqlServer")
{
    Echo "No Installs Required"
}
else
{
    Echo "Installing Modules dbatools and SqlServer..."

    #trust the PSGallery Repo
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    #install the modules, clobber to allow it to install newest version
    Install-Module -Name dbatools -SkipPublisherCheck -Confirm:$false -AllowClobber
    Install-Module -Name SqlServer -SkipPublisherCheck -Confirm:$false -AllowClobber
}

#get the availability group so we can check if this script is running on the primary
$availgp = Get-DbaAvailabilityGroup -SqlInstance $sqlaglName

#make sure this only runs on the primary server
if($availgp.PrimaryReplica -eq $env:COMPUTERNAME)
{
    #get details of each job on the primary server, and make sure the check for primary is on them...
    $jobs = Get-SqlAgentJob -ServerInstance $availgp.PrimaryReplica

    foreach($job in $jobs)
    {
        foreach($step in $job.JobSteps)
        {
            if($step.ID -eq 1) #this check is in case the first step isn't the first in the array of job steps... 
            {
                if($step.Name -eq "DO_NOT_REMOVE_CheckServerPrimary")
                {
                    Echo "Jobstep already exists for job: $job.Name"
                    continue
                }
                else
                {
                    Echo "Creating new jobstep for job: $job.Name"

                    #create the jobstep to check if running server is primary
                    $newstep = New-Object Microsoft.SqlServer.Management.Smo.Agent.JobStep
                    $newstep.Name = 'DO_NOT_REMOVE_CheckServerPrimary'
                    $newstep.Parent = $job
                    $newstep.DatabaseName = 'dex_racklabels'
                    $newstep.Command = "DECLARE @is_write BIT; SELECT @is_write = dbo.fn_is_writeable_replica('$sqltestdbName'); IF @is_write = 0 BEGIN PRINT 'EXITING GRACEFULLY'; THROW 51000, 'This is not a writeable replica', 1; END"
                    $newstep.SubSystem = 'TransactSql'
                    $newstep.OnFailAction = 'QuitWithSuccess'
                    $newstep.OnSuccessAction = 'GoToNextStep'
                    $newstep.ID = 1

                    $newstep.create()
                    $job.Alter()
                    break
                }
            }
        }
    }

    #if this is the primary, all the changes are happening here...
    foreach($replica in $availgp.AvailabilityReplicas)
    {
        if($replica.Name -eq $availgp.PrimaryReplica)
        {
            continue
        }
        else
        {
            Echo "Syncing Logins..."
            Copy-DbaLogin -Source $availgp.PrimaryReplica -Destination $replica.Name
            Echo "Syncing Agent Jobs..."
            Copy-DbaAgentJob -Source $availgp.PrimaryReplica -Destination $replica.Name
        }
    }
}
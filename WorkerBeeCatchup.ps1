Import-Module PSSQLite #-Verbose

$db = "C:\Projects\NodeHookServer\jobs.db"

$conn = New-SQLiteConnection -DataSource $db


#$check_query = "SELECT * FROM new_hires" #WHERE ID='"+$new_hire_id+"'"
#$results = Invoke-SqliteQuery -Query $check_query -SQLiteConnection $conn
#Write-Output $results


function Get-BasicAuthCreds {
    param([string]$Username,[string]$Password)
    $AuthString = "{0}:{1}" -f $Username,$Password
    $AuthBytes  = [System.Text.Encoding]::Ascii.GetBytes($AuthString)
    return [Convert]::ToBase64String($AuthBytes)
}
<#
function SQLinsert {
    param([int]$new_emp_id)
    $date = Get-Date -Format "ddd MMM dd yyyy HH:mm:ss"
    $date = $date + " "+[TimeZoneInfo]::Local.DisplayName

    $query = "INSERT INTO new_employees (
                          ID,
                          status,
                          ticket_id,
                          entry_creation_date
                      )
                      VALUES (
                          '"+$new_emp_id+"',
                          '',
                          '',
                          '"+$date+"'
                      )"
    
    Invoke-SqliteQuery -Query $query -SQLiteConnection $conn

}
#>
function SQLinsert {
    param([int]$new_hire_id)
    $date = Get-Date -Format "ddd MMM dd yyyy HH:mm:ss"
    $date = $date + " "+[TimeZoneInfo]::Local.DisplayName

    $query = "INSERT INTO new_hires (
                          ID,
                          status,
                          ticket_id,
                          entry_creation_date
                      )
                      VALUES (
                          '"+$new_hire_id+"',
                          '',
                          '',
                          '"+$date+"'
                      )"
    
    Invoke-SqliteQuery -Query $query -SQLiteConnection $conn

}

$PayComCreds = Get-BasicAuthCreds -Username "YOUR_USERNAME" -Password "YOUR_PASSWORD"
$FreshCreds = Get-BasicAuthCreds -Username "YOUR_USERNAME" -Password "YOUR_PASSWORD"


#$URL = 'https://api.paycomonline.net/v4/rest/index.php/api/v1/newhire/'+$new_hire_id
$URL = 'https://api.paycomonline.net/v4/rest/index.php/api/v1/newhireids'
#$URL = 'https://api.paycomonline.net/v4/rest/index.php/api/v1/employeenewhire'
$APIresponse = Invoke-RestMethod -Uri $URL -Headers @{"Authorization"="Basic $PayComCreds"} -Method Get -ContentType 'application/json'
Write-Output $APIresponse



if ($APIresponse.data -eq '')
{
    Write-Output "no new employees"
}
else
{
 
    #loop through results here
    for($i = 0; $i -lt $APIresponse.records;$i++)
    {
        $newempEntry = $APIresponse.data[$i]
        #Write-Output $newhireEntry
        #try to insert into database, call WorkerBee with the ID if it worked
        #$new_emp_id = $newempEntry.eecode
        #Write-Output $new_emp_id

        #query the database for new hires, since the error checking never works on this sqlite plugin
        #$check_query = "SELECT * FROM new_employees"
        #$results = Invoke-SqliteQuery -Query $check_query -SQLiteConnection $conn
        #Write-Output $results


        $new_hire_id = $newempEntry.new_hire_id
        Write-Output $new_hire_id

        #query the database for new hires, since the error checking never works on this sqlite plugin
        #$check_query = "SELECT * FROM new_employees"
        #$results = Invoke-SqliteQuery -Query $check_query -SQLiteConnection $conn
        $check_query = "SELECT * FROM new_hires"
        $results = Invoke-SqliteQuery -Query $check_query -SQLiteConnection $conn
        #Write-Output $results

        if($results.ID -contains $new_hire_id) #$new_emp_id
        {
            Write-Output "already exists in db"
        }
        else
        {
            #SQLinsert -new_emp_id $new_emp_id
            SQLinsert -new_hire_id $new_hire_id

            Write-Output "execute other script"
            #Start-Job { C:/Projects/NodeHookServer/WorkerBee.ps1 $new_hire_id }
            #CAUSED ISSUES NOT WAITING FOR THESE THREADS TO COMPLETE
            #$job = Start-Job -filepath "C:/Projects/NodeHookServer/WorkerBee.ps1" -ArgumentList $new_emp_id
            $job = Start-Job -filepath "C:/Projects/NodeHookServer/WorkerBee.ps1" -ArgumentList $new_hire_id
            Wait-Job $job
            Receive-Job $job
        }
    }
 
}




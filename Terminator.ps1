Import-Module PSSQLite -Verbose

$staff_id=$args[0]

$db = "C:\Projects\NodeHookServer\jobs.db"

$conn = New-SQLiteConnection -DataSource $db

function Get-BasicAuthCreds {
    param([string]$Username,[string]$Password)
    $AuthString = "{0}:{1}" -f $Username,$Password
    $AuthBytes  = [System.Text.Encoding]::Ascii.GetBytes($AuthString)
    return [Convert]::ToBase64String($AuthBytes)
}

function SQLupdate {
    param([int]$staff_id,[string]$field,[string]$value)

    $query = "UPDATE terminations SET " + $field +" = " + $value + "WHERE ID = "+$staff_id
    $results = Invoke-SqliteQuery -Query $query -SQLiteConnection $conn

    return $results
}

function SQLinsert {
    param([int]$staff_id)
    $date = Get-Date -Format "ddd MMM dd yyyy HH:mm:ss"
    $date = $date + " "+[TimeZoneInfo]::Local.DisplayName

    $query = "INSERT INTO terminations (
                          ID,
                          status,
                          ticket_id,
                          entry_creation_date,
                          termed_date
                      )
                      VALUES (
                          '"+$new_emp_id+"',
                          '',
                          '',
                          '"+$date+"',
                          ''
                      )"
    
    Invoke-SqliteQuery -Query $query -SQLiteConnection $conn

}


$PayComCreds = Get-BasicAuthCreds -Username "YOUR_USERNAME" -Password "YOUR_PASSWORD"
$FreshCreds = Get-BasicAuthCreds -Username "YOUR_USERNAME" -Password "YOUR_PASSWORD"


#short circuit the script if there's no data to work on
try {
    #get the new hire info
    $URL = 'https://api.paycomonline.net/v4/rest/index.php/api/v1/employee/'+$staff_id
    $APIresponse = Invoke-RestMethod -Uri $URL -Headers @{"Authorization"="Basic $PayComCreds"} -Method Get -ContentType 'application/json' -ErrorAction Stop
    Write-Output $APIresponse
}
catch
{
    Write-Output "empty data"
    #$attempt2 = SQLupdate -new_hire_id $new_emp_id -field "status" -value "'No such NewHire data'"
    Exit

}



$firstName = $APIresponse.data.firstname
$middleName = $APIresponse.data.middlename
$lastName = $APIresponse.data.lastname
$workEmail = $APIresponse.data.work_email
$campus = $APIresponse.data.location
$manager = $APIresponse.data.labor_allocation_details
$position = $APIresponse.data.position_title
$dept = $APIresponse.data.department_description
$supervisors = $APIresponse.data.supervisor_primary +", "+$APIresponse.data.supervisor_secondary+", "+$APIresponse.data.supervisor_tertiary+", "+$APIresponse.data.supervisor_quaternary
#Quamika confirmated that hireDate is the first paid on-site day for the staff member
$termDate = $APIresponse.data.termination_date



$attempt1 = SQLupdate -staff_id $staff_id -field "termed_date" -value "'$termDate'"


#check if ticket already in database and can be found in FreshService
$check_query = "SELECT * FROM terminations WHERE ID='"+$staff_id+"'"
$results = Invoke-SqliteQuery -Query $check_query -SQLiteConnection $conn


$ticketID = $results.ticket_id

$ticket_exists = $true

if($ticketID -eq '' -or $ticketID -eq $null)
{
    $ticket_exists = $false
}

$URL2 = 'https://YOUR_DOMAIN.freshservice.com/api/v2/tickets/'+$ticket_id

#check if FreshService still has a ticket
if($ticket_exists -eq $true)
{
    try{
        $APIresponse2 = Invoke-RestMethod -Uri $URL2 -Headers @{"Authorization"="Basic $FreshCreds"} -Method Get -ContentType 'application/json'
    }
    catch
    {
        $ticket_exists = $false
    }
}


$ticketPayload = @"
{ "description": "Term Date: $termDate<br>First Name: $firstName<br>Middle Name: $middleName<br>Last Name: $lastName<br>E-Mail: $workEmail<br>Campus: $campus<br>Title: $position<br>Department: $dept<br>Reports To: $manager<br>Supervisors: $supervisors",
"subject": "[Automated Termination] $firstName $lastName, Departing $termDate",
"email": "YOUR_HR_EMAIL",
"priority": 1,
"status": 2}
"@


#Create helpdesk ticket if one didn't exist
if($ticket_exists -eq $false)
{

    $URL3 = 'https://YOUR_DOMAIN.freshservice.com/api/v2/tickets/'
    $APIresponse3 = Invoke-RestMethod -Uri $URL3 -Headers @{"Authorization"="Basic $FreshCreds"} -Method Post -Body $ticketPayload -ContentType 'application/json'
    #Write-Output $APIresponse2

    $ticketID = $APIresponse3.ticket.id

    $attempt2 = SQLupdate -staff_id $staff_id -field "ticket_id" -value "'$ticketID'"

}


#add a note if the ticket already existed
if($ticket_exists -eq $true)
{

    $response1 = @{
        body="<b>Automated Response</b><br>New Termination Date: "+$termDate
    }
    $json1 = $response1 | ConvertTo-Json
    $URL4 = 'https://YOUR_DOMAIN.freshservice.com/api/v2/tickets/'+$ticketID+'/notes'
    $APIresponse4 = Invoke-RestMethod -Uri $URL4 -Headers @{"Authorization"="Basic $FreshCreds"} -Method Post -Body $json1 -ContentType 'application/json'
    Write-Output $APIresponse4

}




$ticketPayload2 = @"
{ "due_by": "$termtDate"}
"@

#adding the due by date later, just in case, since back dated due by dates aren't allowed by the API
try{
    $APIresponse5 = Invoke-RestMethod -Uri 'https://YOUR_DOMAIN.freshservice.com/api/v2/tickets/'+$ticketID -Headers @{"Authorization"="Basic $FreshCreds"} -Method Put -Body $ticketPayload2 -ContentType 'application/json' -ErrorAction Stop
    Write-Output $APIresponse5
}
catch
{
    Write-Output "Failed to set ticket due date"
    $error_logs = "Failed to set ticket due date."
    $response2 = @{
        body="<b>Automated Response</b><br>Failed to set Due Date: "+$termDate
    }
    $json2 = $response2 | ConvertTo-Json
    $URL6 = 'https://YOUR_DOMAIN.freshservice.com/api/v2/tickets/'+$ticketID+'/notes'
    $APIresponse6 = Invoke-RestMethod -Uri $URL6 -Headers @{"Authorization"="Basic $FreshCreds"} -Method Post -Body $json2 -ContentType 'application/json'
    Write-Output $APIresponse6
}
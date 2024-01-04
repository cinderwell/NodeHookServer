Import-Module PSSQLite -Verbose

#$new_emp_id=$args[0]
$new_hire_id=$args[0]

$db = "C:\Projects\NodeHookServer\jobs.db"

$conn = New-SQLiteConnection -DataSource $db

$error_logs = ""
$error.Clear()
$debug_mode = $false
$debug_path = "C:\Projects\NodeHookServer\debug\"

function Get-BasicAuthCreds {
    param([string]$Username,[string]$Password)
    $AuthString = "{0}:{1}" -f $Username,$Password
    $AuthBytes  = [System.Text.Encoding]::Ascii.GetBytes($AuthString)
    return [Convert]::ToBase64String($AuthBytes)
}
<#
function SQLupdate {
    param([int]$new_emp_id,[string]$field,[string]$value)

    $query = "UPDATE new_employees SET " + $field +" = " + $value + "WHERE ID = "+$new_emp_id
    $results = Invoke-SqliteQuery -Query $query -SQLiteConnection $conn #"C:\Projects\NodeHookServer\jobs.db"

    return $results
}
#>
function SQLupdate {
    param([int]$new_hire_id,[string]$field,[string]$value)

    $query = "UPDATE new_hires SET " + $field +" = " + $value + "WHERE ID = "+$new_hire_id
    $results = Invoke-SqliteQuery -Query $query -SQLiteConnection $conn #"C:\Projects\NodeHookServer\jobs.db"

    return $results
}

function Remove-AccentMarks
{
    PARAM ([string]$String)
    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))
}

$PayComCreds = Get-BasicAuthCreds -Username "YOUR_USERNAME" -Password "YOUR_PASSWORD"
$FreshCreds = Get-BasicAuthCreds -Username "YOUR_USERNAME" -Password "YOUR_PASSWORD"


#short circuit the script if there's no data to work on
try {
    #get the new hire info
    #$URL = 'https://api.paycomonline.net/v4/rest/index.php/api/v1/employee/'+$new_emp_id
    $URL = 'https://api.paycomonline.net/v4/rest/index.php/api/v1/newhire/'+$new_hire_id
    $APIresponse = Invoke-RestMethod -Uri $URL -Headers @{"Authorization"="Basic $PayComCreds"} -Method Get -ContentType 'application/json' -ErrorAction Stop
    Write-Output $APIresponse

    if($debug_mode -eq $true)
    {
        Write-Output "Attempting debug"
        $temp_date = Get-Date -Format "MM-dd-yyyy_HH-mm"
        $file_name = $debug_path+$new_hire_id+"_"+$temp_date+".txt"
        Write-Output $file_name
        New-Item $file_name
        Set-Content $file_name $APIresponse.data
    }

}
catch
{
    Write-Output "empty data"
    Write-Output $error
    #$attempt2 = SQLupdate -new_hire_id $new_emp_id -field "status" -value "'No such NewHire data'"
    Exit

}





#Write-Output $APIresponse.data.firstName
<#
$firstName = $APIresponse.data.firstname
$middleName = $APIresponse.data.middlename
$lastName = $APIresponse.data.lastname
$city = $APIresponse.data.city
$state = $APIresponse.data.state
$zip = $APIresponse.data.zipcode
$primaryPhone = $APIresponse.data.primary_phone
$personalEmail = $APIresponse.data.personal_email
$workEmail = $APIresponse.data.work_email
$campus = $APIresponse.data.location
$manager = $APIresponse.data.labor_allocation_details
$position = $APIresponse.data.position_title
$dept = $APIresponse.data.department_description
$supervisors = $APIresponse.data.supervisor_primary +", "+$APIresponse.data.supervisor_secondary+", "+$APIresponse.data.supervisor_tertiary+", "+$APIresponse.data.supervisor_quaternary
#Quamika confirmated that hireDate is the first paid on-site day for the staff member
$startDate = $APIresponse.data.hire_date
#Write-Output $startDate
#$startDate2 = $startDate+"T08:00:00Z"
#$startDate2 = "2024-03-16T01:00:00Z"
#Write-Output $startDate2
$startDate3 = $startDate.Substring(5,2)+"-"+$startDate.Substring(8,2)+"-"+$startDate.Substring(0,4)

#working around a fun problem where data.address gives us the object's memory address or something
#$json1 = $APIresponse.data | ConvertTo-Json
#$json2 = $json1  | ConvertFrom-Json
#$homeAddress = $json2.address
$homeAddress = $APIresponse.data.street
#>

$firstName = $APIresponse.data.firstName
$middleName = $APIresponse.data.middleName
$lastName = $APIresponse.data.lastName
$city = $APIresponse.data.city
$state = $APIresponse.data.state
$zip = $APIresponse.data.zipcode
$primaryPhone = $APIresponse.data.primaryPhone
$personalEmail = $APIresponse.data.personalEmail
$workEmail = $APIresponse.data.workEmail
$campus = $APIresponse.data.location
$manager = $APIresponse.data.primarySupervisor
$position = $APIresponse.data.positionTitle
$dept = $APIresponse.data.laborAllocation
$supervisors = $APIresponse.data.primarySupervisor +", "+$APIresponse.data.secondarySupervisor+", "+$APIresponse.data.tertiarySupervisor+", "+$APIresponse.data.quarternarySupervisor
#Quamika confirmated that hireDate is the first paid on-site day for the staff member
$startDate = $APIresponse.data.hireDate
#Write-Output $startDate
#$startDate2 = $startDate+"T08:00:00Z"
#$startDate2 = "2024-03-16T01:00:00Z"
#Write-Output $startDate2
$startDate3 = $startDate.Substring(5,2)+"-"+$startDate.Substring(8,2)+"-"+$startDate.Substring(0,4)

#working around a fun problem where data.address gives us the object's memory address or something
$json1 = $APIresponse.data | ConvertTo-Json
$json2 = $json1  | ConvertFrom-Json
$homeAddress = $json2.address
$homeAddress = $homeAddress+" "+$APIresponse.data.apt_suite_other


#make the first name not ALL CAPS
if($firstName -cmatch "^[A-Z]*$")
{
    Write-Output "first name not all caps"
    $firstName = $firstName.ToLower()
    $firstName = (Get-Culture).TextInfo.ToTitleCase($firstName)
}
#make the last name not ALL CAPS
if($lastName -cmatch "^[A-Z]*$")
{
    Write-Output "last name not all caps"
    $lastName = $lastName.ToLower()
    $lastName = (Get-Culture).TextInfo.ToTitleCase($lastName)
}
#make the middle name not ALL CAPS
if($middleName -cmatch "^[A-Z]*$")
{
    Write-Output "middle name not all caps"
    $middleName = $middleName.ToLower()
    $middleName = (Get-Culture).TextInfo.ToTitleCase($middleName)
}


$displayName = $firstName+' '+$lastName
$userName = Remove-AccentMarks($lastname+$firstName.Substring(0,1))
$userName = $userName.ToLower()
$userName = $userName.Replace(' ','')
$email = $userName+'@YOUR_EMAIL_DOMAIN'




$subject_line = "[Automated New Hire] $firstName $lastName, Starting: $startDate3"


$ticketPayload = @"
{ "description": "Start Date: $startDate3<br>First Name: $firstName<br>Middle Name: $middleName<br>Last Name: $lastName<br>Address: $homeAddress, $city, $state, $zip<br>Personal E-Mail: $personalEmail<br>Phone Number: $primaryPhone<br>Campus: $campus<br>Title: $position<br>Department: $dept<br>Reports To: $manager<br>Supervisors: $supervisors",
"subject": "$subject_line",
"email": "YOUR_HR_EMAIL",
"priority": 1,
"status": 2}
"@

Write-Output $ticketPayload

$URL2 = 'https://YOUR_DOMAIN.freshservice.com/api/v2/tickets/'
$APIresponse2 = Invoke-RestMethod -Uri $URL2 -Headers @{"Authorization"="Basic $FreshCreds"} -Method Post -Body $ticketPayload -ContentType 'application/json'
#Write-Output $APIresponse2

$ticketID = $APIresponse2.ticket.id

#$attempt1 = SQLupdate -new_emp_id $new_emp_id -field "ticket_id" -value "'$ticketID'"
$attempt1 = SQLupdate -new_hire_id $new_hire_id -field "ticket_id" -value "'$ticketID'"

$ticketPayload2 = @"
{ "due_by": "$startDate"}
"@

#adding the due by date later, just in case, since back dated due by dates aren't allowed by the API
try{
    $APIresponse3 = Invoke-RestMethod -Uri $URL2+$ticketID -Headers @{"Authorization"="Basic $FreshCreds"} -Method Put -Body $ticketPayload2 -ContentType 'application/json' -ErrorAction Stop
    Write-Output $APIresponse3
}
catch
{
    Write-Output "Failed to set ticket due date"
    $error_logs = "Failed to set ticket due date."
    $response2 = @{
        body="<b>Automated Response</b><br>Failed to set Due Date: "+$startDate2
    }
    $json2 = $response2 | ConvertTo-Json
    $URL3 = 'https://YOUR_DOMAIN.freshservice.com/api/v2/tickets/'+$ticketID+'/notes'
    $APIresponse4 = Invoke-RestMethod -Uri $URL3 -Headers @{"Authorization"="Basic $FreshCreds"} -Method Post -Body $json2 -ContentType 'application/json'
    Write-Output $APIresponse3
}



#ATTEMPT TO CREATE AD ACCOUNT
$error.Clear()
try
{
    $password = "YOUR_TEMP_PASSWORD"
    $User = New-ADUser -Name $displayName -SamAccountName $userName -DisplayName $displayName -Surname $lastName -Title $position -GivenName $firstName -EmailAddress $email -UserPrincipalName $email -Enabled $True -ChangePasswordAtLogon $True -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -Path "OU=YOUR_OU,OU=YOUR_OU,DC=YOUR_DC,DC=local" -erroraction Stop #-OtherAttributes @{'title'=""} -erroraction Stop
    Add-ADGroupMember -Identity "YOUR_AD_GROUP" -Members $userName -ErrorAction SilentlyContinue


    #$ticket_id = $Result.tickets[$i].id
    #Write-Output $ticket_id
    $response3 = @{
        body="<b>Automated Response</b><br>Account created: "+$email+"<br>Temp Password: "+$password+"<br>Continue account prep and onboarding.";
    }
    $json3 = $response3 | ConvertTo-Json
    #Write-Output $json
    $URL3 = 'https://YOUR_DOMAIN.freshservice.com/api/v2/tickets/'+$ticketID+'/notes'
    $APIresponse4 = Invoke-RestMethod -Uri $URL3 -Headers @{"Authorization"="Basic $FreshCreds"} -Method Post -Body $json3 -ContentType 'application/json'
    Write-Output $APIresponse4
}
catch
{
    $body = ""
    foreach($msg in $error)
    {
        $body = $body+"<br>"+$msg
    }
    #$error_logs = $error_logs + $body

    $response3 = @{
        body="<b>Automated Response</b><br>Failed to create user: "+$email+$body;
    }
    $json3 = $response3 | ConvertTo-Json
    #Write-Output $json
    $URL3 = 'https://YOUR_DOMAIN.freshservice.com/api/v2/tickets/'+$ticketID+'/notes'
    $APIresponse4 = Invoke-RestMethod -Uri $URL3 -Headers @{"Authorization"="Basic $FreshCreds"} -Method Post -Body $json3 -ContentType 'application/json'
    Write-Output $APIresponse4
}


#attempt mailbox creation here
Start-Job { C:/Projects/NodeHookServer/AutoMailbox.ps1 $userName $email }

#LOG RESULTS
<#
if($error_logs -eq "")
{
    $attempt2 = SQLupdate -new_emp_id $new_emp_id -field "status" -value "'Complete'"
}
else
{
    $attempt2 = SQLupdate -new_emp_id $new_emp_id -field "status" -value "'Finished With Errors, see ticket.'"
}
#>
if($error_logs -eq "")
{
    $attempt2 = SQLupdate -new_hire_id $new_hire_id -field "status" -value "'Complete'"
}
else
{
    $attempt2 = SQLupdate -new_hire_id $new_hire_id -field "status" -value "'Finished With Errors, see ticket.'"
}
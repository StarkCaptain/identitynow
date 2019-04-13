<#
  .SYNOPSIS
  Gets Sources from IdentityNow using an oauth bearer token

  .DESCRIPTION
  Gets Sources from IdentityNow using an oauth bearer token. By default all sources will be returned. You can specifiy a single source to return
  You can export source data to .json files

  .PARAMATER orgName
  Specify the organization name (org.identitynow.com, omit identitynow.com)

  .PARAMATER accessToken
  Specify the oauth Bearer token

  .PARAMATER sourceID
  sourceId is not required and be specified to retrieve a single source

  .PARAMATER export
  Specify the export switch to export results to a json file

  .PARAMATER exportPath
  exportPath is an optional parameter and defaults to 'C:\SourceBackups'. This is the path where the export json files will be created

  .EXAMPLE
  Define your access token using a variable for ease of use
  $accessToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJY2YTUNPo9n5kqaA....'
  
  .EXAMPLE
  Get All Sources
  get-idnsource -orgName 'myorg' -accessToken $accessToken
  
  .EXAMPLE
  Get a single source
  get-idnsource -orgName 'myorg' -accessToken $accessToken -sourceID 16503
  
  .EXAMPLE
  Export All Sources
  get-idnsource -orgName 'myorg' -accessToken $accessToken -export -exportPath 'C:\Users\Myuser\Desktop'
  
  .EXAMPLE
  Export a single Source
  get-idnsource -orgName 'myorg' -accessToken $accessToken -sourceID 16503 -export
#>
Function get-idnsource{
    [CmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low',DefaultParametersetName='ParamDefault')]
        param(
            [Parameter(Mandatory=$true,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True)]
                [ValidateNotNull()]
                [string]$orgName,

             [Parameter(Mandatory=$true,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True)]
                [ValidateNotNull()]
                [string]$accessToken,

             [Parameter(Mandatory=$false,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True)]
                [ValidateNotNull()]
                [string]$endpointUri = '/api/source/',

             [Parameter(Mandatory=$false,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True)]
                [ValidateNotNull()]
                [string]$sourceID,

             [Parameter(Mandatory=$false,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                ParameterSetName="export")]
                [ValidateNotNull()]
                [switch]$export,

             [Parameter(Mandatory=$false,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                ParameterSetName="export")]
                [ValidateNotNull()]
                [string]$exportPath = 'C:\SourceBackups'
        )

    #Required Variables
    $tenantUri = 'https://{0}.identitynow.com' -f $orgName 
    $Headers = @{Authorization = "Bearer $accessToken"}
    $Results = @()
    function get-idnsinglesource{
        param(
             [Parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
                [ValidateNotNull()]
                [string]$sourceID,
             [Parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
                [ValidateNotNull()]
                [string]$uri
        )
        
        Write-Verbose ('Querying {0} api endpoint' -f $uri) -Verbose
        try{
            $Response = Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers
            Write-Verbose ('Found Source {0} with a total of {1} accounts'-f $Response.name, $Response.accountsCount) -Verbose
        }catch{
            Write-Error "Issues Connecting to $uri"
            throw
        }

        $Response
    }
    

    If (!($sourceID)){

        $Sources = Invoke-RestMethod -Uri $('{0}{1}list' -f $tenantUri, $endpointUri) -Method Get -Headers $Headers

        ForEach ($Source in $Sources){
            $Results += get-idnsinglesource -sourceID $Source.id -uri $('{0}{1}get/{2}' -f $tenantUri, $endpointUri, $Source.id)
        }

    }else{

        $Results = get-idnsinglesource -sourceID $sourceID -uri $('{0}{1}get/{2}' -f $tenantUri, $endpointUri, $sourceID)

    }

    If ($export){
        $exportPath = $exportPath.Trim('\')
        Write-Verbose ('Exporting Results to {0} ' -f $exportPath) -Verbose

        #Create the Export Folder if it does not exist
        try{
            If(!(Test-Path $exportPath)){New-Item -Path $exportPath}
        }catch{
            Write-Error "Issues Creating Export Folder: $exportPath"
            throw
        }
    
        #Export the Results to JSON file
        If ($Results){

            ForEach ($Result in $Results){
                $Result | ConvertTo-Json | Out-File -FilePath $('{0}\source_{1}_{2}.json' -f $exportPath, $Result.Name, $Result.id) -Force -Confirm:$False
            }
        }else{
            Write-Verbose ('Response from source id: {0} was empty ' -f $sourceID) -Verbose
        }
    }else {
        $Results
    }
}
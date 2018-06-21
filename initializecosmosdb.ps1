param(
    [string] $tenantId = "$1",
    [string] $clientId = "$2",
    [string] $clientSecret = "$3",
    [string] $datapacketUri = "$4",
    [string] $deviceManagementUri = "$5"
    )
    Login-AzureRmAccount 
    Select-AzureRmSubscription -SubscriptionName "Sysgain-Backup" -TenantID $tenantId
    function Get-AccessTokenAPI{
        Write-Host "`nRequesting access token.." -ForegroundColor Green
    
        $tokenParams = @{
          client_id=$clientId;
            client_secret=$clientSecret;
          resource=$clientId;
          grant_type='client_credentials';
          scope='openid'
        }
    
        $baseUri="https://login.microsoftonline.com/"+$tenantId+"/oauth2/token"
        $response=Invoke-RestMethod -Uri $baseUri -Method POST -Body $tokenParams
     
        return $response.access_token
    }
    function CosmosDbInit{
    param([string]$apiBaseURL,[string]$accessToken)
    
        Write-Host "`nInitializing Cosmos DB..." -ForegroundColor Green
        $APIURL=[string]::Format("{0}/api/templates/generate",$apiBaseURL)
        $result=Invoke-RestMethod -Uri $APIURL -Method Post -ContentType "application/json" -Headers @{ "Authorization" = "Bearer $accessToken" }
        if($result -eq "true")
        {
            Write-Host "`nCosmos DB initialized successfully..!" -ForegroundColor Green    
            return $true;
        }
        else
        {
            Write-Host "`nError !! Cosmos DB not initialized!" -ForegroundColor Red  
            return $false;  
        }
    }
            $datapacketUriOIDC=$datapacketUri+"/signin-oidc"      
            $deviceManagementUriOIDC=$deviceManagementUri+"/signin-oidc"   
            $replyURLList = @($datapacketUriOIDC,$deviceManagementUriOIDC);  
            Write-Host '', 'Configuring and setting the Azure AD reply URLs' -ForegroundColor Green
            #####################################################################
            # Get Access token for calling API
            #####################################################################
            $accessToken=Get-AccessTokenAPI $tenantId $clientId $clientSecret
            Write-Host "Access token is " $accessToken -ForegroundColor Magenta
            #add sleep inorder to have API startup successfully
            Start-Sleep -s 10
            #####################################################################
            # Call API to initialize cosmos DB with default starter IoT templates
            # This templates will be loaded in the data packet designer
            #####################################################################
            $cosmosDBInitResult=CosmosDbInit $datapacketUri $accessToken  
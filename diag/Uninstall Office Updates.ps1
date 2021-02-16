# Uninstall unnecessary Office 2010-2016 updates
# http://www.bifido.net/tweaks-and-scripts/7-script-of-additional-cleanup-of-windows-updates.html

function Get-SupersededState ([string]$Patch)
{
	# �஢�ઠ ���ﭨ� ����������
	$IsSuperseded = $false
	$Uninstallable = Get-ItemPropertyValue -LiteralPath "Registry::$Patch" -Name Uninstallable

	# ���������� ���� 㤠�塞�
	if ($Uninstallable -eq "1")
	{
		$State = Get-ItemPropertyValue -LiteralPath "Registry::$Patch" -Name State
		# ���������� ���� ���ॢ訬
		if ($State -eq "2")
		{
			$IsSuperseded = $true
		}
	}

	return $IsSuperseded
}

function Get-Guid ([string]$Token)
{
	# �८�ࠧ������ ���� ॥��� ᮮ⢥�����饣� ���������� � ᯥ樠�쭮� ���祭�� ����室���� ��� ��� 㤠�����
	$guid = $Token[7] + $Token[6] + $Token[5] + $Token[4] + $Token[3] + $Token[2] + $Token[1] + $Token[0] + "-"
	$guid += $Token[11] + $Token[10] + $Token[9] + $Token[8] + "-"
	$guid += $Token[15] + $Token[14] + $Token[13] + $Token[12] + "-"
	$guid += $Token[17] + $Token[16] + $Token[19] + $Token[18] + "-"
	$guid += $Token[21] + $Token[20] + $Token[23] + $Token[22] + $Token[25] + $Token[24] + $Token[27] + $Token[26] + $Token[29] + $Token[28] + $Token[31] + $Token[30]

	return $guid
}

function Get-OfficeUpdates
{
	# ���� ���ॢ�� ���������� ��� ���
	[System.Collections.Hashtable]$ProductsNames = @{}
	[System.Collections.Hashtable]$ProductsUpdates = @{}
	[System.Collections.Hashtable]$ProductsPatches = @{}

	# ���᮪ ���������� 
	[string[]]$Updates = $null
	[string[]]$Patches = $null

	# ���� �� ���� �த�⠬
	foreach ($Product in (Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products"))
	{
		# ���祭�� ����稢��騥�� 000000F01FEC
		if ($Product.PSChildName -match "000000F01FEC")
		{
			$Updates = $null
			$Patches = $null
			$KeyPatches = "$Product\Patches"

			# ���� �� ���������� ��� ��࠭���� �த��
			foreach ($Item in Get-ChildItem -Path "Registry::$KeyPatches")
			{
				# �஢�ઠ ���ﭨ� ����������
				$IsSuperseded = Get-SupersededState -Patch $Item

				# ���������� ���� ���ॢ訬
				if ($IsSuperseded)
				{
					# ����祭�� ����� ����������
					$Update = Get-ItemPropertyValue -LiteralPath "Registry::$Item" -Name DisplayName
					# ����祭�� ᯨ᪠ �������� ����������
					$Updates += , "$Update"
					# ����祭�� ᯨ᪠ ���祩
					$Patches += , $Item.PSChildName
				}
			}

			if ($Patches)
			{
				# ����祭�� ����� �த��
				$KeyProduct = "$Product\InstallProperties"
				$ProductName = Get-ItemProperty -LiteralPath "Registry::$KeyProduct" -Name DisplayName
				$ProductsNames[$Product.PSChildName] = $ProductName
				$ProductsPatches[$Product.PSChildName] = $Patches
				$ProductsUpdates[$Product.PSChildName] = $Updates
			}
		}
	}

	# �뢮� १���⮢
	if ($ProductsNames.Count -gt 0)
	{
		foreach ($Key in $ProductsNames.Keys)
		{
			# �������� �த��
			$Title = $ProductsNames["$Key"]
			# ����������
			$Updates = $ProductsUpdates["$Key"]
		}

		Clear-Host

		# �������� ����������
		foreach ($Key in $ProductsNames.Keys)
		{
			# �������� �த��
			$Title = $ProductsNames["$Key"]
			# ����������
			$Updates = $ProductsUpdates["$Key"]
			# ����
			$Patches = $ProductsPatches["$Key"]
			# �८�ࠧ������ ���� � ᯥ樠�쭮� ���祭��
			$ProductGuid = Get-Guid -Token "$Key"

			# ���� �� 㤠�塞� ����������
			for
			(
				$n = 0
				$n -lt $Patches.Count
				$n++
			)
			{
				# �८�ࠧ������ ���� � ᯥ樠�쭮� ���祭��
				$Patch = $Patches[$n]
				$PatchGuid = Get-Guid -Token $Patch

				# �뢮� ����� 㤠�塞��� ����������
				Write-Host "Removing: " -NoNewline
				Write-Host $Updates[$n]

				# �������� ���������� � ������� ᯥ樠���� ���祭�� ��� �த�� � ����������
				if ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Patches\$Patch") -and (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\$Key\Patches\$Patch"))
				{
					# �஢�ઠ ����⢮����� 䠩�� ���⠫���� ��� ����������
					if ($PathPatch = (Get-ItemPropertyValue -LiteralPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Patches\$Patch" -Name LocalPackage))
					{
						if (Test-Path -Path "$PathPatch")
						{
							& "msiexec.exe" /package "{$ProductGuid}" /uninstall "{$PatchGuid}" /qn /norestart | Out-Null

							if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\$Key\Patches\$Patch")
							{
								Write-Warning -Message "Error occurred"
							}
						}
						else
						{
							Write-Warning -Message "Installer not exist"
						}
					}
					else
					{
						Write-Warning -Message "Path not exist"
					}
				}
				else
				{
					Write-Warning -Message "Already removed"
				}
			}
		}
	}
	else
	{
		Write-Warning -Message "There are no updates to remove"
	}

	pause
}

Get-OfficeUpdates
pause
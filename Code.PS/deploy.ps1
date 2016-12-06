#
# deploy.ps1
# 主要目的是比较新旧发布包，打出增量更新包
#

# 文件的MD5较验码
# 参数1：文件的路径
Function Md5File{

	if($args.Count -lt 1){
		return;
	}

	$file = $args[0];
	
	# ps5以下适用
	#$md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
	#$hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($file)))
	#return $hash;

	# ps5 适用
	return (Get-FileHash $file -Algorithm MD5).Hash;
}

# 比较两个文件
# 先比较文件体积，体积一样时比较MD5
Function CompareFile{

	if($args.Count -lt 2){
		return $false;
	}

	$newfile = $args[0];
	$oldfile = $args[1];
	if($newfile.Length -ne $oldfile.Length){
		return $false;
	}else{
		return ((Md5File $newfile.FullName) -eq (Md5File $oldfile.FullName));	
	}
}


# 比较两个文件夹，必须两个参数，输出更新文件列表
# 参数1：新的文件目录，输出的更新列表以此目录为基准
# 参数2：老的文件目录
Function CompareFolder{
	
	$updatelist=@();
	$baklist=@();

	if($args.Count -lt 2){
		return $baklist,$updatelist;
	}


	$newfolder = $args[0];
	$oldfolder = $args[1]; 

	$list1 = Dir $newfolder | sort name
	$list2 = Dir $oldfolder | sort name

	if(!$list1){
		return $baklist,$updatelist;
	}
	elseif(!$list2){
		return $baklist,$list1;
	}
	elseif(!($list2 -is [array])){
		$list2=,$list2
	}

	$i = 0;

	$list1 | ForEach-Object{

		$isMatch = $false;

		for($j=$i;$j -lt $list2.Count;$j++){

			if($_.Name -eq $list2[$j].Name){
				
                if($_ -is [IO.DirectoryInfo]){
                
                    $resultlist = (CompareFolder $_.FullName $list2[$j].FullName);
					$baklist += $resultlist[0];
					$updatelist += $resultlist[1];
                
                }elseif(!(CompareFile $_ $list2[$j])){
                    
					#  记录
					$updatelist+=$_;
					$baklist+=$list2[$j];

                }


				$isMatch = $true;
                $i=$j+1;
				break;
				
			}
		}

		# 在$list2中没找到也记录
		if(!$isMatch)
		{
			$updatelist+=$_;
		}

	}
	
	return $baklist,$updatelist;

}

# 进行复制
# 参数1：被更新过的文件的列表
# 参数2：新的文件目录，复制来源目录
# 参数3：复制目的目录
Function CreateDeploy{

	if($args.Count -lt 3){
		return;
	}

	$updatelist = $args[0];
	$newFolder = $args[1];
	$deployFolder = $args[2];

	if($updatelist.Count -le 0){
		return;
	}

	if(Test-Path $deployFolder){
		get-childitem $deployFolder -Recurse | Remove-Item
	}else{
		New-Item $deployFolder -itemtype directory
	}

	$updatelist | ForEach-Object{

		$desFolder = $deployFolder;

		$ownerFolder = $_.Parent.FullName;
		if($_ -isnot [IO.DirectoryInfo]){
			$ownerFolder = $_.DirectoryName;
		}

		if($ownerFolder -ne $newFolder){
			$desFolder = $ownerFolder.replace($newFolder,$deployFolder);

			if(!(Test-Path $desFolder)){
				New-Item $desFolder -itemtype directory
			}
		}

		Copy-Item $_.FullName -Destination $desFolder -Recurse
	}

}

# 进行备份
# 参数1：会被覆盖的文件列表
# 参数2：老的文件目录，复制会被覆盖的文件来源目录
# 参数3：备份的目录，(程序会自动在该目录下按日期建立子目录)
Function CreateBak{
	if($args.Count -lt 3){
		return;
	}

	$baklist = $args[0];
	$oldFolder = $args[1];
	$bakFolder = $args[2];

	if($baklist.Count -le 0){
		return;
	}

	$bakFolder += "\" + (Get-Date -DisplayHint DateTime -Format yyyyMMddHHmmss);

	New-Item $bakFolder -itemtype directory

	CreateDeploy $baklist $oldFolder $bakFolder
}

# 产生增量包之后的处理，把老文件夹加上时间重命名做为备份，把新文件更改为老文件夹名，以便于下次发布之后直接比较出增量包
# 参数1：新文件夹
# 参数2：老文件夹
Function RenameFolder{
    
    if($args.Count -lt 2){
		return;
	}

	$newFolder = $args[0];
	$oldFolder = $args[1];
    
    $objOldFolder = Get-Item -Path $oldFolder

    Rename-Item -NewName ($objOldFolder.Name + "_" + (Get-Date -DisplayHint DateTime -Format yyyyMMddHHmmss)) -Path $oldFolder

    Copy-Item -Path $newFolder -Destination $oldFolder -Recurse

}

Function Execute{
    
    # 配置参数1：新的目录文件，更新包的文件复制来源
    $newfolder = "$PSScriptRoot\Release";
    # 配置参数2：老的目录文件，新与旧比较，取出有变化的文件列表
    $oldfolder = "$PSScriptRoot\Release1";
    # 配置参数3：更新的文件复制目的地
    $deployfolder = "$PSScriptRoot\deploy";
    # 配置参数4：备份会被覆盖的文件
    $bakfolder = "$PSScriptRoot\bak";

    # 执行
    $result = CompareFolder $newfolder $oldfolder
    if($result[0].Count -gt 0){
        CreateBak $result[0] $oldfolder $bakfolder
    }
    if($result[1].Count -gt 0){
        CreateDeploy $result[1] $newfolder $deployfolder
        RenameFolder $newfolder $oldfolder
    }
}

Execute

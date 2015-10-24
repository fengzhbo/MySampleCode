#
# deploy.ps1
# 主要目的是比较新旧发布包，打出增量更新包
#

# 文件的MD5较验码
# 参数1：文件的路径
Function Md5File{

	if($args.Length -lt 1){
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

	if($args.Length -lt 2){
		return;
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

	if($args.Length -lt 2){
		return;
	}

	$updatelist=@();

	$newfolder = $args[0];
	$oldfolder = $args[1]; 

	$list1 = Dir $newfolder | sort name
	$list2 = Dir $oldfolder | sort name

	if(!$list1){
		return;
	}
	elseif(!$list2){
		return $list1;
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
                
                    $updatelist += (CompareFolder $_.FullName $list2[$j].FullName);
                
                }elseif(!(CompareFile $_ $list2[$j])){
                    
					#  记录
					$updatelist+=$_;

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

	return $updatelist;

}

# 进行复制
# 参数1：被更新过的文件的列表
# 参数2：新的文件目录，复制来源目录
# 参数3：复制目的目录
Function CreateDeploy{

	if($args.Length -lt 3){
		return;
	}

	$updatelist = $args[0];
	$newFolder = $args[1];
	$deployFolder = $args[2];

	if($updatelist.length -le 0){
		return;
	}

	if(Test-Path $deployFolder){
		get-childitem $deployFolder -Recurse | Remove-Item
	}else{
		New-Item $deployFolder -itemtype directory
	}

	$updatelist | ForEach-Object{

		$desFolder = $deployFolder;

		if($_.DirectoryName -ne $newFolder){
			$desFolder = $_.DirectoryName.replace($newFolder,$deployFolder);

			if(!(Test-Path $desFolder)){
				New-Item $desFolder -itemtype directory
			}
		}

		Copy-Item $_.FullName -Destination $desFolder -Recurse
	}

}

# 配置参数1：新的目录文件，更新包的文件复制来头
$newfolder = "C:\Users\fengzhbo\Desktop\test1";
# 配置参数2：老的目录文件，新与旧比较，取出有变化的文件列表
$oldfolder = "C:\Users\fengzhbo\Desktop\test2";
# 配置参数3：更新的文件复制目的地
$deployfolder = "C:\Users\fengzhbo\Desktop\deploy";

# 执行
$result = CompareFolder $newfolder $oldfolder
CreateDeploy $result $newfolder $deployfolder
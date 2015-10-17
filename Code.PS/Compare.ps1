#
# Compare.ps1
#

# 比较两个文件，必须两个参数
Function CompareFile{
	$newfile = $args[0];
	$oldfile = $args[1];
	if($newfile.Length -ne $oldfile.Lenght){
		return false;
	}
    return true;	
}


# 比较两个文件夹，必须两个参数
Function CompareFolder{

	$newfolder = $args[0];
	$oldfolder = $args[1]; 

	$list1 = Dir $newfolder | sort name
	$list2 = Dir $oldfolder | sort name

	$i = 0;

	$list1 | ForEach-Object{

		for(;$i -le $list2.length;$i++){
			if($_.Name -eq $list2[$i].Name){
				
                if($_ -is [IO.DirectoryInfo]){
                
                    CompareFolder($_.FullName,,$list2[$i].FullName);
                
                }elseif(!CompareFile($_.FullName,$list2[$i].FullName)){
                    
                }
				
                $i++;
				break;
				
			}
		}
		
	}

	
	

}

echo 1
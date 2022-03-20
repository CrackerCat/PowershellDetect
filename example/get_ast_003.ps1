function Convert-CodeToAst
{
  param
  (
    [Parameter(Mandatory)]   # 强制参数
    [System.String]$str      # 执行ps文件名称
  )

  # 构建hashtable
  $hierarchy = @{}
  $result = [System.Collections.ArrayList]@()

  # 提取ps文件中的内容 
  Write-Output ("file name: {0}" -f ($str))
  $content = Get-content $str
  Write-Output $content

  # 创建Scipt代码块
  $code = [ScriptBlock]::Create($content)

  # 提取AST
  $code.Ast.FindAll( { $true }, $true) |
  ForEach-Object {
    # take unique object hash as key
    $id = 0;
    if($_.Parent) {
      $id = $_.Parent.GetHashCode()
    }
    Write-Debug('{0}:{1}' -f $_.GetType().Name,$id)

    if ($hierarchy.ContainsKey($id) -eq $false) {
      $hierarchy[$id] = [System.Collections.ArrayList]@()
    }
    $null = $hierarchy[$id].Add($_)
    # add ast object to parent
  }
  
  # 递归可视化树
  function Visualize-Tree($Id)
  {
    # 每级缩进
    $hierarchy[$id] | ForEach-Object {
      # 获取当前AST对象的id
      $newid = $_.GetHashCode()

      # 递归其子节点（if any)
      if ($hierarchy.ContainsKey($newid))
      {
        Visualize-Tree -id $newid
      }
      $null = $result.Add($_.GetType().Name)
    }
  }

  # 使用AST根对象开始可视化
  Visualize-Tree -id $code.Ast.GetHashCode()
  return $result
}

Convert-CodeToAst -str .\data\sneal_62c28
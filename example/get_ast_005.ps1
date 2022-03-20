# 函数：批量读取文件
function Read_csv_powershell {
  param (
    [parameter(Mandatory=$true)]
    [System.String]$inputfile,
    [System.String]$outputfile
  )

  # 读取CSV文件
  $content = Import-CSV $inputfile
  $list = [System.Collections.ArrayList]@()
  foreach($line in $content) {
    $no = $line.("no")
    $code = $line.("decoded code")
    $name = $line.("family name")
    # Write-Output($no, $code, $name)

    # 转换抽象语法树AST
    try {
      $str = Convert-CodeToAst -str $code
      Write-Output($str)
    } catch [System.Exception] {
      'exception info:{0}' -f $_.Eception.Message
      continue
    }
    $list.add([PSCustomObject]@{
      no = $no
      code = $code
      name = $name
      ast = $str
    })
  }
  $list | ConvertTo-Csv -NoTypeInformation | out-file $outputfile -Encoding ascii -Force
  Write-Output($list)
}

# 函数：拼接AST节点内容
function add_blanks {
    param (
      [parameter(Mandatory=$true)]
      [System.Array]$arr
    )
    $strNode = ''
    foreach($elem in $arr) {
        if($strNode.Length -ne 0) { #不等于
            $elem = " " + $elem
        }
        $strNode = $strNode + $elem
    }
    return $strNode
}

# 函数：提取Powershell代码的抽象语法树(AST)
function Convert-CodeToAst
{
  param
  (
    [Parameter(Mandatory)]   # 强制参数
    [System.String]$str      # 执行ps代码
  )

  # 构建hashtable
  $hierarchy = @{}
  $result = [System.Collections.ArrayList]@()

  # 创建Scipt代码块
  $code = [ScriptBlock]::Create($str)

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
  # Write-Output ($result,"`n")

  # result存储根节点内容
  $strNode = add_blanks -arr $result
  return $strNode
}

# 读取单独PS文件
# Convert-CodeToAst -str .\data\example-002.ps1

# 注意input是系统自带变量
$inputCSV = '.\data\data.csv'
$outputCSV = '.\data\data_AST.csv'
Read_csv_powershell -inputfile $inputCSV -outputfile $outputCSV

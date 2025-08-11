try {
    cls

    $csv = "C:\Users\GillenReid\Downloads\MDM-Document-Summary.csv"

    if ($reader -ne $null) {
        $reader.Close()
        $reader.Dispose()
    }

    "zn ""RWWXCH"""
    "DO $SYSTEM.SQL.Shell()"
    "SET DIALECT=Sybase"

    $reader = New-Object System.IO.StreamReader($csv)
    if ($reader -ne $null) {
        while (!$reader.EndOfStream) {
            $linecount++
            $line = $reader.ReadLine()
            $input = $line.Split(",")
            if ($input[0] -eq "Y") {

                $CareSetting = $input[5]
                $DateAdded = "GETDATE()"
                $DocumentCode = $input[2]
                $DocumentGroup = $input[6]
                $DocumentName = $input[3]
                $DocumentRuleSet = $input[8]
                $DocumentSNOMEDCTCode = $input[10]
                $DocumentType = $input[7]
                
                if ($input[13] -eq "Y") {$Email = "1"}
                else  {$Email = "0"}

                if ($input[11] -eq "Y") {$Fraxinus = "1"}
                else  {$Fraxinus = "0"}

                if ($input[9] -eq "Y") {$GP = "1"}
                else  {$GP = "0"}

                $Letter = 0 #Don't know where this comes from


                if ($DocumentSNOMEDCTCode -eq "") {$Share2Care = "0"}
                else  {$Share2Care = "1"}


                $SourceApplication = $input[1].ToUpper()


                "Check"
                $sql = "SELECT * FROM RWWXCH_Document_Table_Local.DocumentConfiguration "
                $sql = $sql + "where DocumentName =  '$DocumentName'"
                $sql

                ""
                "Insert"
                $sql = "INSERT INTO RWWXCH_Document_Table_Local.DocumentConfiguration "
                $sql = $sql + "(CareSetting, DateAdded, DocumentCode, DocumentGroup, DocumentName, DocumentRuleSet, DocumentSNOMEDCTCode, DocumentType, Email, Fraxinus, GP, Letter, Share2Care, SourceApplication)"
                $sql = $sql + " VALUES "
                $sql = $sql + "('$CareSetting', $DateAdded, '$DocumentCode', '$DocumentGroup', '$DocumentName', '$DocumentRuleSet', '$DocumentSNOMEDCTCode', '$DocumentType', $Email, $Fraxinus, $GP, $Letter, $Share2Care, '$SourceApplication')"
                $sql
                ""
            }
        }
    }
  

} Catch {
    "Error at line $linecount"
    $_
} Finally {
    if ($reader -ne $null) {
        $reader.Close()
        $reader.Dispose()
    }

}
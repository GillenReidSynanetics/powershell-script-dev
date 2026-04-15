@{

# Script module or binary module file associated with this manifest.
ModuleToProcess = 'ConvertFrom-WordToPDF.psm1'

# Version number of this module.
ModuleVersion = '2.0.1'

# ID used to uniquely identify this module
GUID = 'a699dea5-2c73-4616-a270-1f7abb777e71'

# Author of this module
Author = 'Andrew Thompson (andrew@synanetics.com)'

# Company or vendor of this module
CompanyName = 'Synanetics Ltd'

# Copyright statement for this module
Copyright = 'Copyright (c) 2024 by Synanetics Ltd, licensed under Apache 2.0 License.'

# Description of the functionality provided by this module
Description = 'This function converts Word document to PDF'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Functions to export from this module
FunctionsToExport = @( 
    'ConvertFrom-WordToPDF'
)

# # Cmdlets to export from this module
# CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = @(
    'SourceFile',
    'DestinationFolder'
)
}
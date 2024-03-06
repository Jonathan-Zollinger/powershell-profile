# original author -> https://allthesystems.com/2020/10/read-text-from-a-pdf-with-powershell/
function Convert-PDFtoText {
  #requires -runasadministrator
	param(
		[Parameter(Mandatory=$true)][string]$file
	)	
	Add-Type -Path "$($PowerShellHome)/src/itextsharp.dll"
	$pdf = New-Object iTextSharp.text.pdf.pdfreader -ArgumentList $file
	for ($page = 1; $page -le $pdf.NumberOfPages; $page++){
		$text=[iTextSharp.text.pdf.parser.PdfTextExtractor]::GetTextFromPage($pdf,$page)
		Write-Output $text
	}	
	$pdf.Close()
}
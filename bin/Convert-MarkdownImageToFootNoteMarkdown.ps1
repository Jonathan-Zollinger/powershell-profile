#!/usr/bin/env pwsh

function Convert-MarkdownImageToFootNoteMarkdown {
    <#
    .SYNOPSIS
    Facilitates converting a standard markdown image (with alt link) to markdown-with-footnote styled markdown

    .PARAMETER MarkdownText
    Markdown formatted image link with a link to follow other than the image.

    .PARAMETER ToClipboard
    Put this output to the clipboard as well.

    .EXAMPLE
    # converting Sonarcloud's generated build badge
    $> Convert-MarkdownImageToFootNoteMarkdown "[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=Graqr_Threshr&metric=vulnerabilities)](https://sonarcloud.io/summary/new_code?id=Graqr_Threshr)"
    [Vulnerabilities][Vulnerabilities link]
    [Vulnerabilities]:(https://sonarcloud.io/api/project_badges/measure?project=Graqr_Threshr&metric=vulnerabilities)
    [Vulnerabilities link]:(https://sonarcloud.io/summary/new_code?id=Graqr_Threshr)
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ -match '^\[!\[.+]\(.+\)\]\(.+\)'})]
        [String]
        $MarkdownText,
        [Parameter(Mandatory = $false)]
        [switch]
        $ToClipboard
    )
    $title = ($MarkdownText | Select-String -Pattern '\[[^!)]+\]').Matches.Value
    $title = $title.Substring(1, ($title.Length-2))
    $links = ($MarkdownText | Select-String -AllMatches '\([^)]+\)').Matches

    $return = @"
    [![$title]][$($title) link]
    [$($title)]:$($links.Get(0).Value.Substring(1, ($links.Get(0).Length - 2)))
    [$($title) link]:$($links.Get(1).Value.Substring(1, ($links.Get(1).Length - 2)))
"@
    if ($ToClipboard.IsPresent) {
        $return | Set-Clipboard
    }
    $return
}
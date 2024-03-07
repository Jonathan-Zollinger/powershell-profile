#!/usr/bin/env pwsh

function Convert-MarkdownImageToFootNoteMarkdown {
    <#
    .SYNOPSIS
    Facilitates converting a standard markdown image (with alt link) to markdown-with-footnote styled markdown

    .PARAMETER MarkdownText
    Markdown formatted image link with a link to follow other than the image.

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
        $MarkdownText
    )
    $title = ($MarkdownText | Select-String -Pattern '\[[^!)]+\]').Matches.Value
    $title = $title.Substring(1, ($title.Length-2))
    $links = ($MarkdownText | Select-String -AllMatches '\([^)]+\)').Matches
    "[$title][$($title) link]"
    "[$($title)]:$($links.Get(0))"
    "[$($title) link]:$($links.Get(1))"
}
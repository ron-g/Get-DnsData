<#
.SYNOPSIS
"Get-DnsData" queries the listed DNS Server's specified zones for the specified record types, and optionally matches on the HostName property.

.DESCRIPTION
"Get-DnsData" queries the listed DNS Server's specified zones for the specified record types, and optionally matches on the HostName property.

.PARAMETER DnsServer

The DNS server to be queried.

.PARAMETER DnsZones

One or more Zones managed by the DNS server queried.

.PARAMETER NameLike

Regex filter to match a record. Default is ".+", any.

.PARAMETER RecordTypes

One or more record types to query. Default is 'A' records.

.NOTES

Version:        1.0
Author:         ron-g
Creation Date:  2019-06-20 22:00
Purpose/Change: To query my company's DNS server for records.

.INPUTS

DnsServer
DnsZones
NameLike
RecordTypes

.OUTPUTS

Microsoft.Management.Infrastructure.CimInstance#root/Microsoft/Windows/DNS/DnsServerResourceRecord

.EXAMPLE

Get-DnsData.ps1 -DnsZones ad.example.com, example.com -DnsServer dc1 -RecordTypes 'A', 'CNAME', 'MX' -NameLike 'y'

HostName                  RecordType Type       Timestamp            TimeToLive      RecordData
--------                  ---------- ----       ---------            ----------      ----------
....y...                  A          1          0                    01:00:00        10.10.40.23
....y...-..               A          1          6/14/2019 00:00:00   00:20:00        10.10.40.34
......y..                 A          1          0                    01:00:00        10.10.40.20
.....y-.                  A          1          6/20/2019 17:00:00   00:20:00        10.10.100.48
..Y..-...                 A          1          6/21/2019 00:00:00   00:20:00        10.10.100.46
...
..y.......                A          1          0                    01:00:00        10.10.90.86
.......y.                 A          1          0                    01:00:00        192.168.8.60
Y....-...                 A          1          6/18/2019 12:00:00   00:20:00        10.10.100.106
...........y              CNAME      5          0                    01:00:00        mailrelay.example.io.
........y...              CNAME      5          0                    00:01:00        ........y-...ad.example.com.

Query "dc1" for DNS zones "ad.example.com" and "example.com" for record types "A", "CNAME", and "MX" where the HostName property contains a 'y'.

#>

[CmdletBinding()]
param (
	[Parameter(Mandatory=$True)]
	[string]$DnsServer,

	[Parameter(Mandatory=$True)]
	[string[]]$DnsZones,

	[Parameter(Mandatory=$False)]
	[string]$NameLike='.*',

	[Parameter(Mandatory=$False)]
	[string[]]$RecordTypes="A"	
)

$DnsData = ''

$DnsData = `
    foreach ($zone in $DnsZones) {
        foreach ($rtype in $RecordTypes) {
            Get-DnsServerResourceRecord `
                -ComputerName $DnsServer `
                -ZoneName     $zone `
                -RRType       $rtype
            }
        }

$DnsData | `
    Where-Object { $_.HostName -match "$NameLike" } | `
        Select-Object `
            -Property `
                HostName, `
                @{Name='Zone'; exp={(([string]$_.DistinguishedName).Split(',')[1]).Split('=')[1]}}, `
                @{Name='RD' ; exp={$_.RecordData.IPv4Address.IPAddressToString}}, `
                RecordType, `
                Type, `
                Timestamp, `
                TimeToLive | `
            Sort-Object -Property RecordType, HostName, Zone | `
                Format-Table
